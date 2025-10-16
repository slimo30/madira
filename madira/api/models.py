from django.db import models

from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.core.validators import MinValueValidator
from decimal import Decimal
import re
import secrets
from decimal import Decimal
from django.db import models, transaction, IntegrityError
from django.core.validators import MinValueValidator
from django.utils import timezone
from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.core.validators import MinValueValidator
from decimal import Decimal
import re
import secrets
from django.db import transaction, IntegrityError
from django.utils import timezone
from django.core.exceptions import ValidationError


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

from decimal import Decimal
from django.db import models


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

from django.db import models


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
import datetime
from decimal import Decimal
from django.db import models, transaction, IntegrityError
from django.core.validators import MinValueValidator
from django.db.models import F, Q, Max


from decimal import Decimal
from django.db import models, transaction, IntegrityError
from django.db.models import Sum, F, Q, Max
from django.core.validators import MinValueValidator
import datetime


from decimal import Decimal
from django.db import models, transaction, IntegrityError
from django.db.models import Sum, F, Q, Max
from django.core.validators import MinValueValidator
import datetime


# ==========================================================
# 🧾 ORDER MODEL
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

    paid_amount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))]
    )

    status = models.CharField(
        max_length=20,
        choices=Status.choices,
        default=Status.PENDING,
        db_index=True
    )

    description = models.TextField(blank=True)
    delivery_date = models.DateField(null=True, blank=True, db_index=True)
    order_date = models.DateTimeField(db_index=True)
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
        constraints = [
            models.CheckConstraint(
                check=Q(paid_amount__lte=F('total_amount')),
                name='paid_amount_not_exceed_total'
            ),
        ]

    def __str__(self):
        return f"Order {self.order_number} - {self.client.name}"

    # -----------------------------
    # 💰 Financial Calculations
    # -----------------------------
    @property
    def total_expenses(self):
        """Sum of all related outputs (expenses)."""
        result = self.outputs.aggregate(total=Sum('ammount'))['total']
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
    # 🔢 Auto-generate Order Number
    # -----------------------------
    def _generate_order_number(self):
        """Generate a unique order number per year (e.g. 2025-00001)."""
        year = datetime.date.today().year
        prefix = str(year)

        last_order = (
            Order.objects.filter(order_number__startswith=prefix)
            .aggregate(max_num=Max('order_number'))
        )

        last_number = 0
        if last_order['max_num']:
            try:
                last_number = int(last_order['max_num'].split('-')[1])
            except (IndexError, ValueError):
                last_number = 0

        new_number = last_number + 1
        return f"{prefix}-{new_number:05d}"

    # -----------------------------
    # 💾 Save Override
    # -----------------------------
    def save(self, *args, **kwargs):
        """Auto-assign order_number and update status if fully paid."""
        if not self.order_number:
            for _ in range(5):
                self.order_number = self._generate_order_number()
                try:
                    with transaction.atomic():
                        if self.is_fully_paid:
                            self.status = self.Status.COMPLETED
                        return super().save(*args, **kwargs)
                except IntegrityError:
                    self.order_number = ''
            raise IntegrityError("Could not generate a unique order number.")

        # Update status if payment completed later
        if self.is_fully_paid and self.status != self.Status.COMPLETED:
            self.status = self.Status.COMPLETED

        return super().save(*args, **kwargs)


# ==========================================================
# 💸 ORDER OUTPUT MODEL (Expenses)
# ==========================================================
class OrderOutput(models.Model):
    """
    Represents an expense or output linked to an order.
    Used to track costs for each order.
    """
    ammount = models.DecimalField(
        max_digits=12,
        decimal_places=2,
        validators=[MinValueValidator(Decimal('0.00'))]
    )
    order = models.ForeignKey(
        Order,
        on_delete=models.CASCADE,
        related_name='outputs'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'order_outputs'
        ordering = ['-created_at']

    def __str__(self):
        return f"OrderOutput #{self.id} - {self.ammount} DA for Order {self.order.order_number}"



# ═══════════════════════════════════════════════════════════════════════════════
#                                INPUT MODEL
# ═══════════════════════════════════════════════════════════════════════════════

import secrets
import re
from decimal import Decimal
from django.db import models, transaction, IntegrityError
from django.core.exceptions import ValidationError
from django.utils import timezone
from django.core.validators import MinValueValidator

SLUG_RE = re.compile(r'[^a-z0-9]+')

def slugify_short(value: str, max_len=12) -> str:
    """Convert names to lowercase short slug"""
    v = value.lower().strip()
    v = SLUG_RE.sub('-', v).strip('-')
    return v[:max_len] or 'na'


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
        """Generate a human-readable, short, and meaningful reference like INP-25O5-CSL-0003."""
        now = timezone.now()
        year = str(now.year)[-2:]  # last two digits of year
        month = now.strftime("%m")  # month as 01–12

        # Abbreviation from user or client name
        if self.type == self.Type.CLIENT_PAYMENT and self.order:
            who = slugify_short(self.order.client.name)[:3].upper()
        else:
            who = slugify_short(self.created_by.username)[:3].upper()

        # Sequential number per year
        last_input = Input.objects.filter(reference__startswith=f"INP-{year}{month}-{who}").order_by('-id').first()
        if last_input and "-" in last_input.reference:
            try:
                last_num = int(last_input.reference.split('-')[-1])
            except ValueError:
                last_num = 0
        else:
            last_num = 0

        new_num = f"{last_num + 1:04d}"
        return f"INP-{year}{month}-{who}-{new_num}"

    def clean(self):
        """Business rules"""
        if self.type == self.Type.CLIENT_PAYMENT and not self.order:
            raise ValidationError("CLIENT_PAYMENT type requires an order.")
        if self.type == self.Type.SHOP_DEPOSIT and self.order:
            raise ValidationError("SHOP_DEPOSIT cannot have an order.")

    def save(self, *args, **kwargs):
        """Auto-generate reference + prevent overpayment"""
        self.full_clean()

        if not self.reference:
            for _ in range(5):
                self.reference = self._gen_reference()
                try:
                    with transaction.atomic():
                        is_new = self.pk is None
                        old_amount = Decimal('0.00')

                        if not is_new:
                            old_amount = Input.objects.get(pk=self.pk).amount

                        # Prevent overpayment
                        if self.type == self.Type.CLIENT_PAYMENT and self.order:
                            total_after_payment = (
                                self.order.paid_amount - old_amount + self.amount
                            )
                            if total_after_payment > self.order.total_amount:
                                raise ValidationError("Overpayment is not allowed.")

                        super().save(*args, **kwargs)

                        # Update order paid amount
                        if self.order and self.type == self.Type.CLIENT_PAYMENT:
                            if is_new:
                                self.order.paid_amount += self.amount
                            else:
                                self.order.paid_amount = (
                                    self.order.paid_amount - old_amount + self.amount
                                )
                            self.order.save(update_fields=["paid_amount"])
                        return
                except IntegrityError:
                    self.reference = ''
            raise IntegrityError("Could not generate unique reference.")
        super().save(*args, **kwargs)

# ═══════════════════════════════════════════════════════════════════════════════
#                                OUTPUT MODEL
# ═══════════════════════════════════════════════════════════════════════════════

# class Output(models.Model):
#     """
#     Output - Money leaving the shop
#     Simplified with direct order relationship where needed
#     """
#     class Type(models.TextChoices):
#         WITHDRAWAL = 'withdrawal', 'Withdrawal'
#         SUPPLIER_PAYMENT = 'supplier_payment', 'Supplier Payment'
#         CONSUMABLE = 'consumable', 'Consumable'
#         GLOBAL_STOCK_PURCHASE = 'global_stock_purchase', 'Global Stock Purchase'
#         CLIENT_STOCK_USAGE = 'client_stock_usage', 'Client Stock Usage'
#         OTHER_EXPENSE = 'other_expense', 'Other Expense'
    
#     created_by = models.ForeignKey(
#         User,
#         on_delete=models.PROTECT,
#         related_name='outputs'
#     )
#     source_input = models.ForeignKey(
#         Input,
#         on_delete=models.PROTECT,
#         related_name='outputs'
#     )
#     order = models.ForeignKey(
#         'Order',
#         on_delete=models.PROTECT,
#         related_name='outputs',
#         null=True,
#         blank=True,
#         help_text="Required for SUPPLIER_PAYMENT and CLIENT_STOCK_USAGE"
#     )
#     supplier = models.ForeignKey(
#         Supplier,
#         on_delete=models.PROTECT,
#         related_name='outputs',
#         null=True,
#         blank=True,
#         help_text="Required for SUPPLIER_PAYMENT"
#     )
#     type = models.CharField(max_length=30, choices=Type.choices, db_index=True)
#     amount = models.DecimalField(
#         max_digits=12,
#         decimal_places=2,
#         validators=[MinValueValidator(Decimal('0.01'))]
#     )
#     description = models.TextField()
#     reference = models.CharField(max_length=50, blank=True, db_index=True)
#     date = models.DateTimeField(db_index=True)
#     created_at = models.DateTimeField(auto_now_add=True)
#     updated_at = models.DateTimeField(auto_now=True)
    
#     class Meta:
#         db_table = 'outputs'
#         ordering = ['-date']
#         indexes = [
#             models.Index(fields=['-date', 'type']),
#             models.Index(fields=['order', '-date']),  # Order expenses
#             models.Index(fields=['supplier', '-date']),  # Supplier payments
#             models.Index(fields=['created_by', '-date']),  # User activity
#         ]
#         constraints = [
#             models.CheckConstraint(
#                 check=(
#                     models.Q(type='supplier_payment', supplier__isnull=False, order__isnull=False) |
#                     models.Q(type='client_stock_usage', order__isnull=False) |
#                     ~models.Q(type__in=['supplier_payment', 'client_stock_usage'])
#                 ),
#                 name='output_type_requirements'
#             ),
#         ]
    
#     def __str__(self):
#         return f"Output #{self.id} - {self.amount} DA ({self.get_type_display()})"

#     def clean(self):
#         """Validate business rules"""
#         if self.type == self.Type.SUPPLIER_PAYMENT:
#             if not self.supplier:
#                 raise ValidationError("SUPPLIER_PAYMENT requires a supplier")
#             if not self.order:
#                 raise ValidationError("SUPPLIER_PAYMENT requires an order")
        
#         if self.type == self.Type.CLIENT_STOCK_USAGE and not self.order:
#             raise ValidationError("CLIENT_STOCK_USAGE requires an order")

#     def save(self, *args, **kwargs):
#         self.full_clean()
#         super().save(*args, **kwargs)


# # ═══════════════════════════════════════════════════════════════════════════════
# #                                PRODUCT MODEL
# # ═══════════════════════════════════════════════════════════════════════════════

from django.db import models
from decimal import Decimal
from django.core.validators import MinValueValidator

class Product(models.Model):
    """
    Product model with stock tracking
    (Top 6 most relevant units for kitchen furniture fabrication)
    """
    class Unit(models.TextChoices):
        PIECE = 'piece', 'Piece'              # Handles, hinges, screws
        METER = 'm', 'Meter'                  # Profiles, edges
        SQUARE_METER = 'm²', 'Square Meter'   # Panels, MDF boards
        LITER = 'L', 'Liter'                  # Glue, varnish, paint
        KILOGRAM = 'kg', 'Kilogram'           # Powder, resin, bulk materials
        GRAM = 'g', 'Gram'                    # Pigments, small amounts
        NONE = 'none', 'Unitless'             # Services, transport, labor

    name = models.CharField(max_length=100, unique=True, db_index=True)
    unit = models.CharField(
        max_length=20,
        choices=Unit.choices,
        default=Unit.PIECE,
        db_index=True
    )
    current_quantity = models.DecimalField(
        max_digits=10,
        decimal_places=2,
        default=Decimal('0.00'),
        validators=[MinValueValidator(Decimal('0.00'))]
    )
    description = models.TextField(blank=True)
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



# # ═══════════════════════════════════════════════════════════════════════════════
# #                            STOCK_MOVEMENT MODEL
# # ═══════════════════════════════════════════════════════════════════════════════

# class StockMovement(models.Model):
#     """
#     Stock Movement - Optimized with direct order relationship
    
#     Types:
#     1. ACHAT_GLOBAL: Global purchase (adds to stock) - no order
#     2. ACHAT_CLIENT: Client-specific purchase (no stock impact) - has order
#     3. UTILISATION: Usage from stock (reduces stock) - has order
#     """

    
#     class Type(models.TextChoices):
#         ACHAT_GLOBAL = 'achat_global', 'Global Purchase'
#         ACHAT_CLIENT = 'achat_client', 'Client Purchase'
#         UTILISATION = 'utilisation', 'Usage'
    
#     product = models.ForeignKey(
#         Product,
#         on_delete=models.PROTECT,
#         related_name='stock_movements'
#     )
#     created_by = models.ForeignKey(
#         User,
#         on_delete=models.PROTECT,
#         related_name='stock_movements'
#     )
#     output = models.ForeignKey(
#         Output,
#         on_delete=models.PROTECT,
#         related_name='stock_movements'
#     )
#     order = models.ForeignKey(
#         'Order',
#         on_delete=models.PROTECT,
#         related_name='stock_movements',
#         null=True,
#         blank=True,
#         help_text="Required for ACHAT_CLIENT and UTILISATION"
#     )
#     type = models.CharField(max_length=20, choices=Type.choices, db_index=True)
#     quantity = models.DecimalField(
#         max_digits=10,
#         decimal_places=2,
#         validators=[MinValueValidator(Decimal('0.01'))]
#     )
#     unit_price = models.DecimalField(
#         max_digits=12,
#         decimal_places=2,
#         validators=[MinValueValidator(Decimal('0.00'))]
#     )
#     total_price = models.DecimalField(
#         max_digits=12,
#         decimal_places=2,
#         validators=[MinValueValidator(Decimal('0.00'))]
#     )
#     notes = models.TextField(blank=True)
#     date = models.DateTimeField(db_index=True)
#     created_at = models.DateTimeField(auto_now_add=True)
#     updated_at = models.DateTimeField(auto_now=True)
    
#     class Meta:
#         db_table = 'stock_movements'
#         ordering = ['-date']
#         indexes = [
#             models.Index(fields=['-date', 'type']),
#             models.Index(fields=['product', '-date']),  # Product history
#             models.Index(fields=['order', '-date']),  # Order stock usage
#             models.Index(fields=['output']),  # Output linkage
#         ]
#         constraints = [
#             models.CheckConstraint(
#                 check=(
#                     models.Q(type='achat_global', order__isnull=True) |
#                     models.Q(type__in=['achat_client', 'utilisation'], order__isnull=False)
#                 ),
#                 name='stock_movement_order_requirements'
#             ),
#         ]
    
#     def __str__(self):
#         return f"{self.get_type_display()} - {self.product.name} ({self.quantity})"
    
#     def clean(self):
#         """Validate business rules"""
#         if self.type == self.Type.ACHAT_GLOBAL:
#             if self.order:
#                 raise ValidationError("ACHAT_GLOBAL cannot have an order")
#             if self.output.type != Output.Type.GLOBAL_STOCK_PURCHASE:
#                 raise ValidationError("ACHAT_GLOBAL requires GLOBAL_STOCK_PURCHASE output")
        
#         elif self.type in [self.Type.ACHAT_CLIENT, self.Type.UTILISATION]:
#             if not self.order:
#                 raise ValidationError(f"{self.type} requires an order")
#             if self.output.type != Output.Type.CLIENT_STOCK_USAGE:
#                 raise ValidationError(f"{self.type} requires CLIENT_STOCK_USAGE output")
        
#         # Validate sufficient stock for usage
#         if self.type == self.Type.UTILISATION:
#             if self.pk is None:  # New record
#                 if self.product.current_quantity < self.quantity:
#                     raise ValidationError(
#                         f"Insufficient stock for {self.product.name}. "
#                         f"Available: {self.product.current_quantity}, Required: {self.quantity}"
#                     )
    
#     def save(self, *args, **kwargs):
#         """Save with stock update"""
#         self.full_clean()
        
#         # Calculate total price
#         self.total_price = self.quantity * self.unit_price
        
#         is_new = self.pk is None
        
#         with transaction.atomic():
#             super().save(*args, **kwargs)
            
#             # Update product quantity only for new records
#             if is_new:
#                 if self.type == self.Type.ACHAT_GLOBAL:
#                     self.product.current_quantity += self.quantity
#                     self.product.save()
#                 elif self.type == self.Type.UTILISATION:
#                     self.product.current_quantity -= self.quantity
#                     self.product.save()
#                 # ACHAT_CLIENT doesn't affect global stock