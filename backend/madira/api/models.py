from django.db import models, transaction, IntegrityError
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.core.validators import MinValueValidator
from django.core.exceptions import ValidationError
from django.utils import timezone
from django.utils.text import slugify
from django.db.models import Sum, F, Q, Max
from decimal import Decimal
import datetime
import re
import secrets

def create_meaningful_slug(text, max_len=3):
    """Extract meaningful abbreviation from text"""
    if not text:
        return "UNK"
    text = str(text).upper().strip()
    text = re.sub(r'[^A-Z0-9\s]', '', text)
    words = text.split()
    if len(words) > 1:
        result = ''.join(w[0] for w in words if w)[:max_len]
        return result if result else text[:max_len]
    return text[:max_len] if text else "UNK"

# ═══════════════════════════════════════════════════════════════════════════════
#                                USER MANAGEMENT
# ═══════════════════════════════════════════════════════════════════════════════

class UserManager(BaseUserManager):
    def create_user(self, username, password=None, **extra_fields):
        if not username:
            raise ValueError('Users must have a username')
        
        user = self.model(username=username, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user
    
    def create_superuser(self, username, password=None, **extra_fields):
        extra_fields.setdefault('role', 'admin')
        extra_fields.setdefault('is_staff', True)
        extra_fields.setdefault('is_superuser', True)
        return self.create_user(username, password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    """
    User model with roles: Admin, Responsible, Simple User
    Relations: INPUT (créateur), OUTPUT (créateur), STOCK_MOVEMENT (créateur)
    """
    
    class Role(models.TextChoices):
        ADMIN = 'admin', 'Admin'
        RESPONSIBLE = 'responsible', 'Responsible'
        SIMPLE_USER = 'simple_user', 'Simple User'
    
    username = models.CharField(max_length=50, unique=True, db_index=True)
    full_name = models.CharField(max_length=100, blank=True)
    role = models.CharField(
        max_length=20,
        choices=Role.choices,
        default=Role.SIMPLE_USER
    )
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    
    objects = UserManager()
    
    USERNAME_FIELD = 'username'
    REQUIRED_FIELDS = []
    
    class Meta:
        db_table = 'users'
        ordering = ['-created_at']
    
    def __str__(self):
        return f"{self.username} ({self.get_role_display()})"



# models.py (ADD THIS TO YOUR EXISTING FILE)

class BlacklistedToken(models.Model):
    """
    Stores invalidated JWT tokens to prevent reuse after logout
    """
    token = models.CharField(max_length=500, unique=True, db_index=True)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='blacklisted_tokens')
    blacklisted_at = models.DateTimeField(auto_now_add=True)
    
    # Optional: Track additional info
    ip_address = models.GenericIPAddressField(null=True, blank=True)
    user_agent = models.CharField(max_length=255, blank=True)

    class Meta:
        db_table = 'blacklisted_tokens'
        ordering = ['-blacklisted_at']
        indexes = [
            models.Index(fields=['token']),
            models.Index(fields=['blacklisted_at']),
        ]

    def __str__(self):
        return f"Token for {self.user.username} (blacklisted {self.blacklisted_at})"
    
# ═══════════════════════════════════════════════════════════════════════════════
#                                CLIENT MODEL
# ═══════════════════════════════════════════════════════════════════════════════

class Client(models.Model):
    """
    Client model
    Relations: INPUT (paiements), ORDER (commandes), OUTPUT (destination)
    """

    class Type(models.TextChoices):
        NEW = 'new', 'New'
        OLD = 'old', 'Old'

    name = models.CharField(max_length=100, db_index=True)
    phone = models.CharField(max_length=20, blank=True)
    address = models.TextField(blank=True)
    credit_balance = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal('0.00'),
        help_text="Solde crédit du client (avances - dettes)"
    )
    client_type = models.CharField(
        max_length=10,
        choices=Type.choices,
        default=Type.NEW,
        help_text="Indique si le client est nouveau ou ancien"
    )
    notes = models.TextField(blank=True)
    is_active = models.BooleanField(default=True, help_text="Client actif ou désactivé")

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'clients'
        ordering = ['name']

    def __str__(self):
        return self.name



# # ═══════════════════════════════════════════════════════════════════════════════
# #                                SUPPLIER MODEL
# # ═══════════════════════════════════════════════════════════════════════════════

class Supplier(models.Model):
    """
    Supplier model (for workshop/fabrication)
    Represents providers or manufacturers you buy from.
    """

    name = models.CharField(max_length=100, db_index=True)
    phone = models.CharField(max_length=20, blank=True)
    address = models.TextField(blank=True)
    notes = models.TextField(blank=True)
    is_active = models.BooleanField(default=True, help_text="Set to false instead of deleting the supplier")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'suppliers'
        ordering = ['name']

    def __str__(self):
        return self.name

# ═══════════════════════════════════════════════════════════════════════════════
#                                ORDER MODEL
# ═══════════════════════════════════════════════════════════════════════════════

# ==========================================================
#  ORDER MODEL
# ==========================================================
class Order(models.Model):
    """
    Order model with financial tracking.
    Auto-generates a unique order_number per year like '2025-00001'.
    """

    class Status(models.TextChoices):
        PENDING = 'pending', 'Pending'
        IN_PROGRESS = 'in_progress', 'In Progress'
        COMPLETED = 'completed', 'Completed'
        CANCELLED = 'cancelled', 'Cancelled'

    client = models.ForeignKey(
        'Client',
        on_delete=models.PROTECT,
        related_name='orders'
    )

    order_number = models.CharField(
        max_length=50,
        unique=True,
        db_index=True,
        blank=True
    )

    total_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.00'))]
    )

    # ️ REMOVED: paid_amount field - now calculated dynamically
    # paid_amount is now a @property that calculates from related Inputs

    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING,
        db_index=True
    )

    description = models.TextField(blank=True)
    delivery_date = models.DateField(null=True, blank=True, db_index=True)
    order_date = models.DateTimeField(db_index=True, default=timezone.now)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'orders'
        ordering = ['-order_date']
        indexes = [
            models.Index(fields=['client', 'status']),
            models.Index(fields=['status', '-order_date']),
            models.Index(fields=['-order_date', 'client']),
            models.Index(fields=['delivery_date', 'status']),
        ]
        # ️ REMOVED: Check constraint for paid_amount (no longer a database field)

    def __str__(self):
        return f"Order {self.order_number} - {self.client.name}"

    # -----------------------------
    #  Financial Calculations
    # -----------------------------
    @property
    def paid_amount(self):
        """
        Calculate total paid amount by summing all CLIENT_PAYMENT type Inputs
        for this order.
        """
        result = (
            Input.objects
            .filter(order=self, type=Input.Type.CLIENT_PAYMENT)
            .aggregate(total=Sum('amount'))['total']
        )
        return result or Decimal('0.00')

    @property
    def total_expenses(self):
        """Sum of all related outputs (expenses)."""
        result = self.order_outputs.aggregate(total=Sum('amount'))['total']
        return result or Decimal('0.00')

    @property
    def total_benefit(self):
        """
        Total benefit (profit) = total_amount - total_expenses.
        """
        return self.total_amount - self.total_expenses

    @property
    def remaining_amount(self):
        """Remaining unpaid amount."""
        return self.total_amount - self.paid_amount

    @property
    def is_fully_paid(self):
        return self.paid_amount >= self.total_amount

    # -----------------------------
    #  Auto-generate Order Number
    # -----------------------------
    def _generate_order_number(self):
        """
        Generate unique order reference: {CLIENT_ABBR}-ORD-{YYMM}-{SEQ}
        Example: ALI-ORD-2510-0001 (Ali's order in Oct 2025)
        Sequential numbering is UNLIMITED and will continue incrementing indefinitely.
        """
        now = datetime.date.today()
        year = str(now.year)[-2:]
        month = now.strftime("%m")
        
        client_abbr = create_meaningful_slug(self.client.name, max_len=3)
        base_prefix = f"{client_abbr}-ORD-{year}{month}"
        
        # Unlimited retry mechanism - increased from 10 to 100
        for attempt in range(100):
            try:
                with transaction.atomic():
                    last_order = (
                        Order.objects
                        .select_for_update(nowait=False)
                        .filter(order_number__startswith=base_prefix)
                        .order_by('-order_number')
                        .first()
                    )
                    
                    last_number = 0
                    if last_order and last_order.order_number:
                        try:
                            parts = last_order.order_number.split('-')
                            if len(parts) >= 4:
                                last_number = int(parts[3])
                        except (IndexError, ValueError):
                            pass
                    
                    # Increment without any limit - can grow infinitely
                    new_number = last_number + 1
                    new_reference = f"{base_prefix}-{new_number:04d}"
                    
                    if not Order.objects.filter(order_number=new_reference).exists():
                        return new_reference
                    
            except IntegrityError:
                continue
        
        # Fallback with timestamp + random suffix
        timestamp = now.strftime("%H%M%S%f")[:8]
        random_suffix = secrets.token_hex(3)
        return f"{base_prefix}-{new_number + 1:04d}-{timestamp}-{random_suffix}"

    # -----------------------------
    #  Save Override
    # -----------------------------
    def save(self, *args, **kwargs):
        """
        Auto-assign order_number on creation.
        Status logic:
        - COMPLETED only when fully paid
        - IN_PROGRESS when not fully paid (even if was COMPLETED before)
        - Respects CANCELLED and PENDING status
        """
        if not self.order_number:
            # Generate order number on first save
            for attempt in range(100):
                self.order_number = self._generate_order_number()
                try:
                    with transaction.atomic():
                        return super().save(*args, **kwargs)
                except IntegrityError:
                    self.order_number = ''
                    if attempt == 99:
                        raise IntegrityError(
                            "Could not generate a unique order number after 100 attempts. "
                            "This should never happen under normal conditions."
                        )

        # Auto-adjust status based on payment (only if not CANCELLED or PENDING)
        if self.status not in [self.Status.CANCELLED, self.Status.PENDING]:
            if self.is_fully_paid:
                # Fully paid -> mark as COMPLETED
                self.status = self.Status.COMPLETED
            elif self.status == self.Status.COMPLETED:
                # Was completed but no longer fully paid -> revert to IN_PROGRESS
                self.status = self.Status.IN_PROGRESS

        return super().save(*args, **kwargs)

# ═══════════════════════════════════════════════════════════════════════════════
#                                INPUT MODEL
# ═══════════════════════════════════════════════════════════════════════════════



class Input(models.Model):
    class Type(models.TextChoices):
        CLIENT_PAYMENT = 'client_payment', 'Client Payment'
        SHOP_DEPOSIT = 'shop_deposit', 'Shop Deposit'

    created_by = models.ForeignKey(User, on_delete=models.PROTECT, related_name='inputs')
    order = models.ForeignKey(
        'Order',
        on_delete=models.PROTECT,
        related_name='payments',
        null=True,
        blank=True,
        help_text="Required for CLIENT_PAYMENT type"
    )
    type = models.CharField(max_length=20, choices=Type.choices, db_index=True)
    amount = models.DecimalField(max_digits=12, decimal_places=2, validators=[MinValueValidator(Decimal('0.01'))])
    description = models.TextField(blank=True)
    reference = models.CharField(max_length=50, unique=True, db_index=True, blank=True)
    date = models.DateTimeField(default=timezone.now, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'inputs'
        ordering = ['-date']

    def __str__(self):
        return f"{self.reference} - {self.amount} DA"
    
    def _gen_reference(self):
        """
        Generate unique input reference with UNLIMITED numbering:
        - CLIENT_PAYMENT: {CLIENT_ABBR}-PAY-{YYMM}-{SEQ}
        Example: ALI-PAY-2510-0001 (payment from Ali)
        - SHOP_DEPOSIT: DEP-{USER_ABBR}-{YYMM}-{SEQ}
        Example: DEP-ADM-2510-0001 (deposit by admin)
        """
        now = timezone.now()
        year = str(now.year)[-2:]
        month = now.strftime("%m")
        
        if self.type == self.Type.CLIENT_PAYMENT and self.order:
            client_abbr = create_meaningful_slug(self.order.client.name, max_len=3)
            base_prefix = f"{client_abbr}-PAY-{year}{month}"
        else:
            user_abbr = create_meaningful_slug(self.created_by.username, max_len=3)
            base_prefix = f"DEP-{user_abbr}-{year}{month}"
        
        # Unlimited retry mechanism - increased from 10 to 100
        for attempt in range(100):
            try:
                with transaction.atomic():
                    last_input = (
                        Input.objects
                        .select_for_update(nowait=False)
                        .filter(reference__startswith=base_prefix)
                        .order_by('-id')
                        .first()
                    )
                    
                    last_num = 0
                    if last_input and last_input.reference:
                        try:
                            parts = last_input.reference.split('-')
                            if len(parts) >= 4:
                                last_num = int(parts[3])
                        except (ValueError, IndexError):
                            pass
                    
                    # Increment WITHOUT LIMIT - can grow to any number
                    new_num = last_num + 1
                    new_reference = f"{base_prefix}-{new_num:04d}"
                    
                    if not Input.objects.filter(reference=new_reference).exists():
                        return new_reference
                        
            except IntegrityError:
                continue
        
        # Fallback with timestamp + random suffix
        timestamp = now.strftime("%H%M%S%f")[:8]
        random_suffix = secrets.token_hex(3)
        return f"{base_prefix}-{last_num + 1:04d}-{timestamp}-{random_suffix}"

    def save(self, *args, **kwargs):
        """Auto-generate reference with unlimited retries"""
        self.full_clean()

        if not self.reference:
            # Increased from 5 to 100 retries for unlimited generation
            for attempt in range(100):
                self.reference = self._gen_reference()
                try:
                    with transaction.atomic():
                        super().save(*args, **kwargs)
                        
                        #  After saving, check if order should be marked as completed
                        if self.order and self.type == self.Type.CLIENT_PAYMENT:
                            if self.order.is_fully_paid and self.order.status != Order.Status.COMPLETED:
                                self.order.status = Order.Status.COMPLETED
                                self.order.save(update_fields=['status'])
                        return
                except IntegrityError:
                    self.reference = ''
                    if attempt == 99:
                        raise IntegrityError(
                            "Could not generate unique reference after 100 attempts. "
                            "This should never happen under normal conditions."
                        )
        
        super().save(*args, **kwargs)
        
        #  After saving, check if order should be marked as completed
        if self.order and self.type == self.Type.CLIENT_PAYMENT:
            if self.order.is_fully_paid and self.order.status != Order.Status.COMPLETED:
                self.order.status = Order.Status.COMPLETED
                self.order.save(update_fields=['status'])

# # ═══════════════════════════════════════════════════════════════════════════════
# #                                PRODUCT MODEL
# # ═══════════════════════════════════════════════════════════════════════════════



class Product(models.Model):
    """
    Product model with stock tracking
    (Top 6 most relevant units for kitchen furniture fabrication)
    """
    class Unit(models.TextChoices):
        PIECE = 'piece', 'Piece'
        METER = 'm', 'Meter'
        SQUARE_METER = 'm²', 'Square Meter'
        LITER = 'L', 'Liter'
        KILOGRAM = 'kg', 'Kilogram'
        GRAM = 'g', 'Gram'
        NONE = 'none', 'Unitless'

    name = models.CharField(max_length=100, db_index=True)
    unit = models.CharField(
        max_length=20,
        choices=Unit.choices,
        default=Unit.PIECE,
        db_index=True
    )
    # price = models.DecimalField(
    #     max_digits=12,
    #     decimal_places=2,
    #     validators=[MinValueValidator(Decimal('0.00'))],
    #     default=Decimal('0.00'),  # <-- set default here

    # )
    current_quantity = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))]
    )
    description = models.TextField(blank=True)
    reference = models.CharField(max_length=100, unique=True, blank=True, db_index=True)
    is_active = models.BooleanField(default=True, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'products'
        ordering = ['name']
        indexes = [
            models.Index(fields=['is_active', 'name']),
        ]

    def __str__(self):
        return f"{self.name} ({self.current_quantity} {self.get_unit_display()})"

    def save(self, *args, **kwargs):
        """
        Generate unique product reference: {PRODUCT_ABBR}-{YYMM}-{SEQ}
        Example: WP-2510-0001 (Wood Panel)
        Sequential numbering is UNLIMITED.
        """
        if not self.reference:
            now = timezone.now()
            year = str(now.year)[-2:]
            month = now.strftime("%m")
            
            product_abbr = create_meaningful_slug(self.name, max_len=3)
            base_prefix = f"{product_abbr}-{year}{month}"
            
            # Unlimited retry mechanism - increased from 10 to 100
            for attempt in range(100):
                try:
                    with transaction.atomic():
                        last_product = (
                            Product.objects
                            .select_for_update(nowait=False)
                            .filter(reference__startswith=base_prefix)
                            .order_by('-id')
                            .first()
                        )
                        
                        counter = 1
                        if last_product and last_product.reference:
                            try:
                                parts = last_product.reference.split('-')
                                if len(parts) >= 3:
                                    counter = int(parts[2]) + 1
                            except (ValueError, IndexError):
                                pass
                        
                        # Increment WITHOUT LIMIT - can grow to any number
                        new_reference = f"{base_prefix}-{counter:04d}"
                        
                        if not Product.objects.filter(reference=new_reference).exists():
                            self.reference = new_reference
                            break
                            
                except IntegrityError:
                    continue
            
            # Fallback with timestamp + random suffix
            if not self.reference:
                timestamp = now.strftime("%H%M%S%f")[:8]
                random_suffix = secrets.token_hex(3)
                self.reference = f"{base_prefix}-{counter:04d}-{timestamp}-{random_suffix}"
        
        super(Product, self).save(*args, **kwargs)






# ==========================================================
#  ORDER OUTPUT MODEL (Expenses)
# ==========================================================
class OrderOutput(models.Model):
    """
    Represents an expense or output linked to an order.
    Used to track costs for each order (e.g., product consumption or supplier payment).
    """

    class OutputType(models.TextChoices):
        PRODUCT_CONSUMPTION = 'product_consumption', 'Product Consumption'
        SUPPLIER_PAYMENT = 'supplier_payment', 'Supplier Payment'
        OTHER_EXPENSE = 'other_expense', 'Other Expense'

    amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.00'))]
    )
    order = models.ForeignKey(
        'Order',
        on_delete=models.CASCADE,
        related_name='order_outputs'
    )
    type = models.CharField(
        max_length=30,
        choices=OutputType.choices
                )
    
    created_by_output = models.ForeignKey(
        'Output',
        on_delete=models.PROTECT,
        related_name='order_outputs',
        null=True,
        blank=True
    )

    created_by_stock_movement = models.ForeignKey(
        'StockMovement',
        on_delete=models.PROTECT,
        related_name='order_outputs',   
        null=True,
        blank=True
    )
    description = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'order_outputs'
        ordering = ['-created_at']

    def __str__(self):
        return f"OrderOutput #{self.id} - {self.amount} DA ({self.get_type_display()}) for Order {self.order.order_number}"

    
class Output(models.Model):
    """
    Output — Money leaving the shop.
    Represents all expense transactions (e.g., supplier payment, consumable, withdrawal, etc.)
    """

    class Type(models.TextChoices):
        WITHDRAWAL = 'withdrawal', 'Withdrawal'  # must be responsible role or admin  
        SUPPLIER_PAYMENT = 'supplier_payment', 'Supplier Payment'  # requires supplier + order
        CONSUMABLE = 'consumable', 'Consumable'  # direct expense (not linked to order)
        GLOBAL_STOCK_PURCHASE = 'global_stock_purchase', 'Global Stock Purchase'  # adds to stock (via stock movement) need product
        CLIENT_STOCK_USAGE = 'client_stock_usage', 'Client Stock Usage'  # links to client order, adds/removes stock
        OTHER_EXPENSE = 'other_expense', 'Other Expense'  # order can be added optionally

    created_by = models.ForeignKey(
        'User',
        on_delete=models.PROTECT,
        related_name='outputs'
    )
    source_input = models.ForeignKey(
        'Input',
        on_delete=models.PROTECT,
        related_name='outputs'
    )
    order = models.ForeignKey(
        'Order',
        on_delete=models.PROTECT,
        related_name='outputs',
        null=True,
        blank=True,
        help_text="(Required for SUPPLIER_PAYMENT and CLIENT_STOCK_USAGE) or optionally for OTHER_EXPENSE."
    )
    supplier = models.ForeignKey(
        'Supplier',
        on_delete=models.PROTECT,
        related_name='outputs',
        null=True,
        blank=True,
        help_text="Required for SUPPLIER_PAYMENT."
    )
    product = models.ForeignKey(
        'Product',
        on_delete=models.PROTECT,
        related_name='outputs',
        null=True,
        blank=True,
        help_text="Required for GLOBAL_STOCK_PURCHASE and CLIENT_STOCK_USAGE."
    )
    type = models.CharField(max_length=30, choices=Type.choices, db_index=True)
    amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.01'))],
        default= 0
    )
    description = models.TextField(blank=True)
    reference = models.CharField(max_length=50, blank=True, db_index=True)
    date = models.DateTimeField(default=timezone.now, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'outputs'
        ordering = ['-date']
        indexes = [
            models.Index(fields=['-date', 'type']),
            models.Index(fields=['order', '-date']),
            models.Index(fields=['supplier', '-date']),
            models.Index(fields=['created_by', '-date']),
        ]

    def __str__(self):
        return f"Output #{self.id} - {self.amount} DA ({self.get_type_display()})"

    # ----------------------------
    # VALIDATION LOGIC
    # ----------------------------
    def clean(self):
        """Validate that required fields match the output type."""

        # Base rule: amount > 0
        if self.amount <= 0:
            raise ValidationError("Amount must be positive.")

        # Type-specific logic
        if self.type == self.Type.WITHDRAWAL:
            if any([self.order, self.supplier, self.product]):
                raise ValidationError("WITHDRAWAL must not be linked to order, supplier, or product.")

        elif self.type == self.Type.SUPPLIER_PAYMENT:
            if not self.supplier:
                raise ValidationError("SUPPLIER_PAYMENT requires a supplier.")
            if not self.order:
                raise ValidationError("SUPPLIER_PAYMENT requires an order.")
            if any([self.product]):
                raise ValidationError("SUPPLIER_PAYMENT must not have a product.")

        elif self.type == self.Type.CONSUMABLE:
            if any([self.order, self.supplier, self.product]):
                raise ValidationError("CONSUMABLE must not be linked to order, supplier, or product.")

        elif self.type == self.Type.GLOBAL_STOCK_PURCHASE:
            if not self.product:
                raise ValidationError("GLOBAL_STOCK_PURCHASE requires a product.")
            if any([self.order, self.supplier]):
                raise ValidationError("GLOBAL_STOCK_PURCHASE must not have order or supplier.")

        elif self.type == self.Type.CLIENT_STOCK_USAGE:
            if not self.order:
                raise ValidationError("CLIENT_STOCK_USAGE requires an order.")
            if not self.product:
                raise ValidationError("CLIENT_STOCK_USAGE requires a product.")
            if any([self.supplier]):
                raise ValidationError("CLIENT_STOCK_USAGE must not have a supplier.")

        elif self.type == self.Type.OTHER_EXPENSE:
            # order optional, others not allowed
            if any([self.supplier, self.product]):
                raise ValidationError("OTHER_EXPENSE must not have supplier or product.")

        else:
            raise ValidationError(f"Unknown output type: {self.type}")
        
        total_used = (
            self.source_input.outputs.exclude(pk=self.pk).aggregate(models.Sum('amount'))['amount__sum']
            or Decimal('0.00')
        )
        remaining = self.source_input.amount - total_used

        if self.amount > remaining:
            raise ValidationError(
                f"Insufficient funds in input {self.source_input.reference}. "
                f"Remaining: {remaining} DA, tried to spend: {self.amount} DA."
            )

    # ----------------------------
    # REFERENCE GENERATION (UNLIMITED)
    # ----------------------------
    def _generate_reference(self):
        """
        Generate contextual output references based on type with UNLIMITED numbering.
        Numbers can grow infinitely beyond 9999.
        
        WITHDRAWAL: WD-{USER_ABBR}-{YYMM}-{SEQ}
            Example: WD-ADM-2510-0001 (withdrawal by admin)
        
        SUPPLIER_PAYMENT: {SUPPLIER_ABBR}-PAY-{YYMM}-{SEQ}
            Example: ACME-PAY-2510-0001 (payment to ACME Supplier)
        
        CONSUMABLE: CONS-{YYMM}-{SEQ}
            Example: CONS-2510-0008 (consumable expense)
        
        GLOBAL_STOCK_PURCHASE: {PRODUCT_ABBR}-BUY-{YYMM}-{SEQ}
            Example: WP-BUY-2510-0003 (bought Wood Panel for stock)
        
        CLIENT_STOCK_USAGE: {CLIENT_ABBR}-USE-{YYMM}-{SEQ}
            Example: ALI-USE-2510-0027 (Ali used from stock)
        
        OTHER_EXPENSE: EXP-{YYMM}-{SEQ}
            Example: EXP-2510-0005 (other expense)
        """
        now = timezone.now()
        year = str(now.year)[-2:]
        month = now.strftime("%m")
        
        # Generate prefix based on output type
        if self.type == self.Type.WITHDRAWAL:
            user_abbr = create_meaningful_slug(self.created_by.username, max_len=3)
            base_prefix = f"WD-{user_abbr}-{year}{month}"
        
        elif self.type == self.Type.SUPPLIER_PAYMENT:
            supplier_abbr = create_meaningful_slug(self.supplier.name, max_len=4)
            base_prefix = f"{supplier_abbr}-PAY-{year}{month}"
        
        elif self.type == self.Type.CONSUMABLE:
            base_prefix = f"CONS-{year}{month}"
        
        elif self.type == self.Type.GLOBAL_STOCK_PURCHASE:
            product_abbr = create_meaningful_slug(self.product.name, max_len=3)
            base_prefix = f"{product_abbr}-BUY-{year}{month}"
        
        elif self.type == self.Type.CLIENT_STOCK_USAGE:
            client_abbr = create_meaningful_slug(self.order.client.name, max_len=3)
            base_prefix = f"{client_abbr}-USE-{year}{month}"
        
        else:  # OTHER_EXPENSE
            base_prefix = f"EXP-{year}{month}"
        
        # Unlimited retry mechanism - will keep trying until successful
        max_attempts = 100  # Increased from 10 to handle high concurrency
        for attempt in range(max_attempts):
            try:
                with transaction.atomic():
                    last_output = (
                        Output.objects
                        .select_for_update(nowait=False)
                        .filter(reference__startswith=base_prefix)
                        .order_by('-id')
                        .first()
                    )
                    
                    last_num = 0
                    if last_output and last_output.reference:
                        try:
                            parts = last_output.reference.split('-')
                            # Extract last numeric part
                            for part in reversed(parts):
                                try:
                                    last_num = int(part)
                                    break
                                except ValueError:
                                    continue
                        except (ValueError, IndexError):
                            pass
                    
                    # Increment WITHOUT LIMIT - can grow to any number
                    new_num = last_num + 1
                    new_reference = f"{base_prefix}-{new_num:04d}"
                    
                    if not Output.objects.filter(reference=new_reference).exists():
                        return new_reference
                        
            except IntegrityError:
                continue
        
        # Fallback with timestamp + random suffix for extreme edge cases
        timestamp = now.strftime("%H%M%S%f")[:8]
        random_suffix = secrets.token_hex(3)
        return f"{base_prefix}-{new_num + 1:04d}-{timestamp}-{random_suffix}"

    def save(self, *args, **kwargs):
        """Ensure validation and reference generation with unlimited retries."""
        self.full_clean()
        
        if not self.reference:
            # Keep trying until we get a reference - no hard limit
            max_retries = 100
            for attempt in range(max_retries):
                self.reference = self._generate_reference()
                try:
                    with transaction.atomic():
                        super().save(*args, **kwargs)
                        return
                except IntegrityError:
                    self.reference = ''
                    if attempt == max_retries - 1:
                        raise IntegrityError(
                            f"Could not generate unique reference after {max_retries} attempts. "
                            "This should never happen under normal conditions."
                        )
        else:
            super().save(*args, **kwargs)




class StockMovement(models.Model):
    """
    StockMovement — tracks every change in product stock.
    - Always linked to a Product.
    - Order is required only when stock moves OUT (to a client).
    """

    class MovementType(models.TextChoices):
        IN = 'in', 'In'
        OUT = 'out', 'Out'

    product = models.ForeignKey(
        'Product',
        on_delete=models.PROTECT,
        related_name='stock_movements'
    )

    order = models.ForeignKey(
        'Order',
        on_delete=models.PROTECT,
        related_name='stock_movements',
        null=True,
        blank=True,
        help_text="Required when movement_type is OUT (client usage)."
    )



    price = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.00'))],
        default=Decimal('0.00')
    )
   
    movement_type = models.CharField(
        max_length=3,
        choices=MovementType.choices,
        db_index=True
    )

    quantity = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.01'))]
    )

    date = models.DateTimeField(default=timezone.now, db_index=True)
    created_at = models.DateTimeField(auto_now_add=True)
    created_by = models.ForeignKey(
        'User',
        on_delete=models.PROTECT,
        related_name='stock_movements',
        null=True,
        blank=True
    )
    created_by_output= models.ForeignKey(
        'Output',
        on_delete=models.PROTECT,
        related_name='stock_movements',
        null=True,
        blank=True
    )

    class Meta:
        db_table = 'stock_movements'
        ordering = ['-date']
        indexes = [
            models.Index(fields=['-date', 'movement_type']),
            models.Index(fields=['product', '-date']),
            models.Index(fields=['order', '-date']),
        ]

    def __str__(self):
        direction = "IN" if self.movement_type == self.MovementType.IN else "OUT"
        return f"{self.product.name} ({direction}) - {self.quantity} units"

    @property
    def signed_quantity(self):
        """Return +quantity for IN, -quantity for OUT."""
        return self.quantity if self.movement_type == self.MovementType.IN else -self.quantity

    def clean(self):
        """Business rule validation."""
        if self.movement_type == self.MovementType.OUT and not self.order:
            raise ValidationError("An order is required when stock movement type is OUT.")

        if self.movement_type == self.MovementType.IN and self.order is not None:
            raise ValidationError("IN movements must not be linked to an order.")

        if self.quantity <= 0:
            raise ValidationError("Quantity must be positive.")

    def save(self, *args, **kwargs):
        """Validate and save safely."""
        self.full_clean()  # ensures clean() rules always apply
        super().save(*args, **kwargs)
