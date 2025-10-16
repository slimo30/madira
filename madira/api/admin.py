from django.contrib import admin
from .models import User, BlacklistedToken, Client, Supplier, Order, Input

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
    # 🧠 Display Computed Values
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
    list_display = ('id', 'order', 'ammount', 'created_at')
    search_fields = ('order__order_number',)
    list_filter = ('created_at',)
    ordering = ('-created_at',)


# ---------------------------
# INPUT ADMIN
# ---------------------------
@admin.register(Input)
class InputAdmin(admin.ModelAdmin):
    list_display = ('reference', 'created_by', 'order', 'type', 'amount', 'date')
    search_fields = ('reference', 'created_by__username', 'order__order_number')
    list_filter = ('type', 'date')
    ordering = ('-date',)
