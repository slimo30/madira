from django.contrib import admin
from .models import User, BlacklistedToken, Client, Supplier, Order, Input , Product

# ---------------------------
# USER ADMIN
# ---------------------------
@admin.register(User)
class UserAdmin(admin.ModelAdmin):
    list_display = ('username', 'full_name', 'role', 'is_active', 'is_staff', 'created_at')
    list_filter = ('role', 'is_active', 'is_staff')
    search_fields = ('username', 'full_name')
    ordering = ('-created_at',)


# ---------------------------
# BLACKLISTED TOKEN ADMIN
# ---------------------------
@admin.register(BlacklistedToken)
class BlacklistedTokenAdmin(admin.ModelAdmin):
    list_display = ('token', 'user', 'blacklisted_at')
    search_fields = ('token', 'user__username')
    list_filter = ('blacklisted_at',)


# ---------------------------
# CLIENT ADMIN
# ---------------------------
@admin.register(Client)
class ClientAdmin(admin.ModelAdmin):
    list_display = ('name', 'phone', 'credit_balance', 'client_type', 'is_active')
    search_fields = ('name', 'phone')
    list_filter = ('client_type', 'is_active')
    ordering = ('name',)


# ---------------------------
# SUPPLIER ADMIN
# ---------------------------
@admin.register(Supplier)
class SupplierAdmin(admin.ModelAdmin):
    list_display = ('name', 'phone', 'is_active')
    search_fields = ('name', 'phone')
    list_filter = ('is_active',)
    ordering = ('name',)


# ---------------------------
# ORDER ADMIN
# ---------------------------
from django.contrib import admin
from .models import Order, OrderOutput


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = (
        'order_number',
        'client',
        'status',
        'total_amount',
        'paid_amount',
        'remaining_amount_display',
        'total_expenses_display',
        'total_benefit_display',
        'order_date',
    )
    search_fields = ('order_number', 'client__name')
    list_filter = ('status', 'order_date')
    ordering = ('-order_date',)

    # -----------------------------
    #  Display Computed Values
    # -----------------------------
    def total_expenses_display(self, obj):
        return f"{obj.total_expenses:.2f} DA"
    total_expenses_display.short_description = "Total Expenses"

    def total_benefit_display(self, obj):
        return f"{obj.total_benefit:.2f} DA"
    total_benefit_display.short_description = "Benefit"

    def remaining_amount_display(self, obj):
        return f"{obj.remaining_amount:.2f} DA"
    remaining_amount_display.short_description = "Remaining"


@admin.register(OrderOutput)
class OrderOutputAdmin(admin.ModelAdmin):
    list_display = ('id', 'order', 'amount', 'type', 'created_at')  # fix typo here
    search_fields = ('order__order_number',)
    list_filter = ('created_at',)
    ordering = ('-created_at',)


# ---------------------------
# INPUT ADMIN
# ---------------------------
@admin.register(Input)
class InputAdmin(admin.ModelAdmin):
    list_display = ('reference', 'created_by', 'order', 'type', 'amount', 'date',)
    search_fields = ('reference', 'created_by__username', 'order__order_number')
    list_filter = ('type', 'date')
    ordering = ('-date',)


@admin.register(Product)
class ProductAdmin(admin.ModelAdmin):   
    list_display = ('name', 'is_active', 'created_at')
    search_fields = ('name','refrence')
    list_filter = ('is_active', 'created_at')
    ordering = ('name',)


from django.contrib import admin
from .models import Output

@admin.register(Output)
class OutputAdmin(admin.ModelAdmin):
    list_display = (
        'id',
        'reference',
        'type',
        'amount',
        'order',
        'supplier',
        'product',
        'created_by',
        'date',
        'description',
    )
    list_filter = ('type', 'created_by', 'date', 'supplier')
    search_fields = ('reference', 'description', 'order__order_number', 'supplier__name')
    readonly_fields = ('reference', 'created_at', 'updated_at')
    ordering = ('-date',)





from .models import StockMovement

@admin.register(StockMovement)
class StockMovementAdmin(admin.ModelAdmin):
    list_display = (
        'id',
        'product',
        'movement_type',
        'quantity',
        'signed_quantity_display',
        'price',
        'order',
        'created_by',
        'created_by_output',
        'date',
    )
    list_filter = ('movement_type', 'created_at', 'product', 'created_by')
    search_fields = ('product__name', 'order__order_number', 'created_by__username')
    readonly_fields = ('created_at',)
    ordering = ('-date',)
    
    def signed_quantity_display(self, obj):
        """Display quantity with +/- sign based on movement type"""
        return f"{obj.signed_quantity:+.2f}"
    signed_quantity_display.short_description = "Signed Qty"
    signed_quantity_display.admin_order_field = 'quantity'