from django.db import models

from django.db import models
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.core.validators import MinValueValidator
from decimal import Decimal

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


# # ═══════════════════════════════════════════════════════════════════════════════
# #                                INPUT MODEL
# # ═══════════════════════════════════════════════════════════════════════════════

# class Input(models.Model):
#     """
#     Input (Entrée) - Money coming into the shop
#     Relations: USER (créateur), CLIENT (optionnel), OUTPUT (source), ORDER_PAYMENT (optionnel)
#     """
    
#     class Type(models.TextChoices):
#         CLIENT_PAYMENT = 'client_payment', 'Client Payment'
#         SHOP_DEPOSIT = 'shop_deposit', 'Shop Deposit'
    
#     # USER (1,1) ←→ (0,n) INPUT
#     created_by = models.ForeignKey(
#         User,
#         on_delete=models.PROTECT,
#         related_name='inputs'
#     )
    
#     # CLIENT (1,1) ←→ (0,n) INPUT (optional for shop_deposit)
#     client = models.ForeignKey(
#         Client,
#         on_delete=models.PROTECT,
#         related_name='inputs',
#         null=True,
#         blank=True
#     )
    
#     type = models.CharField(
#         max_length=20,
#         choices=Type.choices
#     )
#     amount = models.DecimalField(
#         max_digits=12,
#         decimal_places=2,
#         validators=[MinValueValidator(Decimal('0.01'))]
#     )
#     description = models.TextField(blank=True)
#     reference = models.CharField(max_length=50, blank=True)
#     date = models.DateTimeField(db_index=True)
#     created_at = models.DateTimeField(auto_now_add=True)
#     updated_at = models.DateTimeField(auto_now=True)
    
#     class Meta:
#         db_table = 'inputs'
#         ordering = ['-date']
#         indexes = [
#             models.Index(fields=['-date', 'type']),
#         ]
    
#     def __str__(self):
#         return f"Input #{self.id} - {self.amount} DA ({self.get_type_display()})"


# # ═══════════════════════════════════════════════════════════════════════════════
# #                                OUTPUT MODEL
# # ═══════════════════════════════════════════════════════════════════════════════

# class Output(models.Model):
#     """
#     Output (Sortie) - Money leaving the shop
#     Relations: USER (créateur), INPUT (source obligatoire), CLIENT (destination opt.),
#                SUPPLIER (destination opt.), ORDER_OUTPUT (opt.), STOCK_MOVEMENT (opt.)
#     """
    
#     class Type(models.TextChoices):
#         WITHDRAWAL = 'withdrawal', 'Withdrawal'
#         SUPPLIER_PAYMENT = 'supplier_payment', 'Supplier Payment'
#         CONSUMABLE = 'consumable', 'Consumable'
#         GLOBAL_STOCK_PURCHASE = 'global_stock_purchase', 'Global Stock Purchase'
#         CLIENT_STOCK_USAGE = 'client_stock_usage', 'Client Stock Usage'
#         OTHER_EXPENSE = 'other_expense', 'Other Expense'
    
#     # USER (1,1) ←→ (0,n) OUTPUT
#     created_by = models.ForeignKey(
#         User,
#         on_delete=models.PROTECT,
#         related_name='outputs'
#     )
    
#     # INPUT (1,1) ←→ (0,n) OUTPUT
#     source_input = models.ForeignKey(
#         Input,
#         on_delete=models.PROTECT,
#         related_name='outputs'
#     )
    
#     # CLIENT (0,1) ←→ (0,n) OUTPUT
#     client = models.ForeignKey(
#         Client,
#         on_delete=models.PROTECT,
#         related_name='outputs',
#         null=True,
#         blank=True
#     )
    
#     # SUPPLIER (0,1) ←→ (0,n) OUTPUT
#     supplier = models.ForeignKey(
#         Supplier,
#         on_delete=models.PROTECT,
#         related_name='outputs',
#         null=True,
#         blank=True
#     )
    
#     type = models.CharField(
#         max_length=30,
#         choices=Type.choices
#     )
#     amount = models.DecimalField(
#         max_digits=12,
#         decimal_places=2,
#         validators=[MinValueValidator(Decimal('0.01'))]
#     )
#     description = models.TextField()
#     reference = models.CharField(max_length=50, blank=True)
#     date = models.DateTimeField(db_index=True)
#     created_at = models.DateTimeField(auto_now_add=True)
#     updated_at = models.DateTimeField(auto_now=True)
    
#     class Meta:
#         db_table = 'outputs'
#         ordering = ['-date']
#         indexes = [
#             models.Index(fields=['-date', 'type']),
#         ]
    
#     def __str__(self):
#         return f"Output #{self.id} - {self.amount} DA ({self.get_type_display()})"


# # ═══════════════════════════════════════════════════════════════════════════════
# #                                ORDER MODEL
# # ═══════════════════════════════════════════════════════════════════════════════

# class Order(models.Model):
#     """
#     Order (Commande) - Client orders
#     Relations: CLIENT (propriétaire), ORDER_PAYMENT (paiements), ORDER_OUTPUT (dépenses liées)
#     """
    
#     class Status(models.TextChoices):
#         PENDING = 'pending', 'Pending'
#         IN_PROGRESS = 'in_progress', 'In Progress'
#         COMPLETED = 'completed', 'Completed'
#         DELIVERED = 'delivered', 'Delivered'
#         CANCELLED = 'cancelled', 'Cancelled'
    
#     # CLIENT (1,1) ←→ (0,n) ORDER
#     client = models.ForeignKey(
#         Client,
#         on_delete=models.PROTECT,
#         related_name='orders'
#     )
    
#     order_number = models.CharField(max_length=50, unique=True, db_index=True)
#     total_amount = models.DecimalField(
#         max_digits=12,
#         decimal_places=2,
#         validators=[MinValueValidator(Decimal('0.00'))]
#     )
#     paid_amount = models.DecimalField(
#         max_digits=12,
#         decimal_places=2,
#         default=Decimal('0.00'),
#         validators=[MinValueValidator(Decimal('0.00'))]
#     )
#     status = models.CharField(
#         max_length=20,
#         choices=Status.choices,
#         default=Status.PENDING
#     )
#     description = models.TextField(blank=True)
#     delivery_date = models.DateField(null=True, blank=True)
#     order_date = models.DateTimeField(db_index=True)
#     created_at = models.DateTimeField(auto_now_add=True)
#     updated_at = models.DateTimeField(auto_now=True)
    
#     class Meta:
#         db_table = 'orders'
#         ordering = ['-order_date']
    
#     def __str__(self):
#         return f"Order {self.order_number} - {self.client.name}"
    
#     @property
#     def remaining_amount(self):
#         return self.total_amount - self.paid_amount


# # ═══════════════════════════════════════════════════════════════════════════════
# #                          ORDER_PAYMENT (Association Table)
# # ═══════════════════════════════════════════════════════════════════════════════

# class OrderPayment(models.Model):
#     """
#     OrderPayment - Links orders to their payments (inputs)
#     Relations: ORDER (commande), INPUT (paiement)
#     Contrainte: Doit obligatoirement être un INPUT de type CLIENT_PAYMENT
#     """
    
#     # ORDER (1,1) ←→ (1,n) ORDER_PAYMENT
#     order = models.ForeignKey(
#         Order,
#         on_delete=models.PROTECT,
#         related_name='order_payments'
#     )
    
#     # INPUT (1,1) ←→ (0,1) ORDER_PAYMENT
#     input = models.OneToOneField(
#         Input,
#         on_delete=models.PROTECT,
#         related_name='order_payment'
#     )
    
#     amount = models.DecimalField(
#         max_digits=12,
#         decimal_places=2,
#         validators=[MinValueValidator(Decimal('0.01'))]
#     )
#     notes = models.TextField(blank=True)
#     created_at = models.DateTimeField(auto_now_add=True)
    
#     class Meta:
#         db_table = 'order_payments'
#         ordering = ['-created_at']
#         unique_together = [['order', 'input']]
    
#     def __str__(self):
#         return f"Payment {self.amount} DA for Order {self.order.order_number}"


# # ═══════════════════════════════════════════════════════════════════════════════
# #                          ORDER_OUTPUT (Association Table)
# # ═══════════════════════════════════════════════════════════════════════════════

# class OrderOutput(models.Model):
#     """
#     OrderOutput - Links orders to their expenses (outputs)
#     Relations: ORDER (commande), OUTPUT (dépense), STOCK_MOVEMENT (mouvements stock opt.)
#     """
    
#     # ORDER (1,1) ←→ (0,n) ORDER_OUTPUT
#     order = models.ForeignKey(
#         Order,
#         on_delete=models.PROTECT,
#         related_name='order_outputs'
#     )
    
#     # OUTPUT (1,1) ←→ (0,1) ORDER_OUTPUT
#     output = models.OneToOneField(
#         Output,
#         on_delete=models.PROTECT,
#         related_name='order_output'
#     )
    
#     notes = models.TextField(blank=True)
#     created_at = models.DateTimeField(auto_now_add=True)
    
#     class Meta:
#         db_table = 'order_outputs'
#         ordering = ['-created_at']
    
#     def __str__(self):
#         return f"Output {self.output.amount} DA for Order {self.order.order_number}"


# # ═══════════════════════════════════════════════════════════════════════════════
# #                                PRODUCT MODEL
# # ═══════════════════════════════════════════════════════════════════════════════

# class Product(models.Model):
#     """
#     Product model for stock management
#     Relations: STOCK_MOVEMENT (mouvements)
#     """
    
#     name = models.CharField(max_length=100, db_index=True)
#     unit = models.CharField(
#         max_length=20,
#         help_text="Unit of measurement (kg, m, piece, etc.)"
#     )
#     current_quantity = models.DecimalField(
#         max_digits=10,
#         decimal_places=2,
#         default=Decimal('0.00'),
#         validators=[MinValueValidator(Decimal('0.00'))],
#         help_text="Current stock quantity"
#     )
#     description = models.TextField(blank=True)
#     created_at = models.DateTimeField(auto_now_add=True)
#     updated_at = models.DateTimeField(auto_now=True)
    
#     class Meta:
#         db_table = 'products'
#         ordering = ['name']
    
#     def __str__(self):
#         return f"{self.name} ({self.current_quantity} {self.unit})"


# # ═══════════════════════════════════════════════════════════════════════════════
# #                            STOCK_MOVEMENT MODEL
# # ═══════════════════════════════════════════════════════════════════════════════

# class StockMovement(models.Model):
#     """
#     StockMovement - Tracks product purchases and usage
#     Relations: PRODUCT (produit), USER (créateur obligatoire), 
#                OUTPUT (opt. selon type), ORDER_OUTPUT (opt. selon type)
    
#     Types:
#     1. ACHAT_GLOBAL: USER(1,1), OUTPUT(1,1), ORDER_OUTPUT(0,0)
#     2. ACHAT_CLIENT: USER(1,1), OUTPUT(1,1), ORDER_OUTPUT(1,1)
#     3. UTILISATION: USER(1,1), OUTPUT(1,1), ORDER_OUTPUT(1,1)
#     """
    
#     class Type(models.TextChoices):
#         ACHAT_GLOBAL = 'achat_global', 'Global Purchase'
#         ACHAT_CLIENT = 'achat_client', 'Client Purchase'
#         UTILISATION = 'utilisation', 'Usage'
    
#     # PRODUCT (1,1) ←→ (0,n) STOCK_MOVEMENT
#     product = models.ForeignKey(
#         Product,
#         on_delete=models.PROTECT,
#         related_name='stock_movements'
#     )
    
#     # USER (1,1) ←→ (0,n) STOCK_MOVEMENT
#     created_by = models.ForeignKey(
#         User,
#         on_delete=models.PROTECT,
#         related_name='stock_movements'
#     )
    
#     # OUTPUT (0,1) ←→ (0,n) STOCK_MOVEMENT
#     output = models.ForeignKey(
#         Output,
#         on_delete=models.PROTECT,
#         related_name='stock_movements',
#         null=True,
#         blank=True
#     )
    
#     # ORDER_OUTPUT (0,1) ←→ (0,n) STOCK_MOVEMENT
#     order_output = models.ForeignKey(
#         OrderOutput,
#         on_delete=models.PROTECT,
#         related_name='stock_movements',
#         null=True,
#         blank=True
#     )
    
#     type = models.CharField(
#         max_length=20,
#         choices=Type.choices
#     )
#     quantity = models.DecimalField(
#         max_digits=10,
#         decimal_places=2,
#         validators=[MinValueValidator(Decimal('0.01'))],
#         help_text="Quantity purchased or used"
#     )
#     unit_price = models.DecimalField(
#         max_digits=12,
#         decimal_places=2,
#         validators=[MinValueValidator(Decimal('0.00'))],
#         help_text="Price per unit"
#     )
#     total_price = models.DecimalField(
#         max_digits=12,
#         decimal_places=2,
#         validators=[MinValueValidator(Decimal('0.00'))],
#         help_text="Total price (quantity * unit_price)"
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
#         ]
    
#     def __str__(self):
#         return f"{self.get_type_display()} - {self.product.name} ({self.quantity} {self.product.unit})"
    
#     def save(self, *args, **kwargs):
#         # Calculate total_price
#         self.total_price = self.quantity * self.unit_price
        
#         # Validate business rules
#         if self.type == self.Type.ACHAT_GLOBAL:
#             if not self.output:
#                 raise ValueError("ACHAT_GLOBAL requires an OUTPUT")
#             if self.order_output:
#                 raise ValueError("ACHAT_GLOBAL cannot have an ORDER_OUTPUT")
        
#         elif self.type in [self.Type.ACHAT_CLIENT, self.Type.UTILISATION]:
#             if not self.output or not self.order_output:
#                 raise ValueError(f"{self.type} requires both OUTPUT and ORDER_OUTPUT")
        
#         super().save(*args, **kwargs)
        
#         # Update product quantity
#         if self.type in [self.Type.ACHAT_GLOBAL]:
#             # Add to stock
#             self.product.current_quantity += self.quantity
#         elif self.type == self.Type.UTILISATION:
#             # Remove from stock
#             self.product.current_quantity -= self.quantity
#         # ACHAT_CLIENT doesn't affect global stock
        
#         self.product.save()