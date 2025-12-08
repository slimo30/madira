from rest_framework import serializers
from ..models import User

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'full_name', 'role', 'is_active', 'created_at']
        read_only_fields = ['id', 'created_at']


class CreateUserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True)

    class Meta:
        model = User
        fields = ['username', 'full_name', 'password', 'role']

    def create(self, validated_data):
        password = validated_data.pop('password')
        user = User.objects.create_user(**validated_data)
        user.set_password(password)
        user.save()
        return user


from ..models import Client , Supplier


class ClientSerializer(serializers.ModelSerializer):
    class Meta:
        model = Client
        exclude = ['updated_at']
        read_only_fields = ['id', 'created_at']

class SupplierSerializer(serializers.ModelSerializer):
    class Meta:
        model = Supplier
        exclude = ['updated_at']
        read_only_fields = ['id', 'created_at']


from rest_framework import serializers
from ..models import Order


class OrderSerializer(serializers.ModelSerializer):
    #  Custom read-only fields
    client_name = serializers.CharField(source='client.name', read_only=True)
    total_expenses = serializers.DecimalField(
        max_digits=12, decimal_places=2, read_only=True
    )
    total_benefit = serializers.DecimalField(
        max_digits=12, decimal_places=2, read_only=True
    )
    remaining_amount = serializers.DecimalField(
        max_digits=12, decimal_places=2, read_only=True
    )
    is_fully_paid = serializers.BooleanField(read_only=True)

    class Meta:
        model = Order
        fields = [
            'id',
            'order_number',
            'client',
            'client_name',
            'total_amount',
            'paid_amount',
            'remaining_amount',
            'total_expenses',
            'total_benefit',
            'is_fully_paid',
            'status',
            'description',
            'delivery_date',
            'order_date',
            'created_at',
            'updated_at',
        ]
        read_only_fields = [
            'order_number',
            'created_at',
            'updated_at',
            'total_expenses',
            'total_benefit',
            'remaining_amount',
            'is_fully_paid',
        ]


from rest_framework import serializers
from ..models import Input
from django.db.models import Sum

class InputSerializer(serializers.ModelSerializer):
    created_by_name = serializers.CharField(source='created_by.username', read_only=True)
    order_number = serializers.CharField(source='order.order_number', read_only=True)
    client_name = serializers.CharField(source='order.client.name', read_only=True)
    remaining_amount = serializers.SerializerMethodField(read_only=True)

    class Meta:
        model = Input
        fields = [
            'id', 'reference', 'type', 'amount', 'description',
            'order', 'order_number', 'client_name',
            'created_by', 'created_by_name',
            'remaining_amount',
            'date', 'created_at', 'updated_at'
        ]
        read_only_fields = ['reference', 'created_at', 'updated_at', 'created_by']

    def get_remaining_amount(self, obj):
        """Calculate remaining amount = input amount - total outputs from this input"""
        total_outputs = obj.outputs.aggregate(total=Sum('amount'))['total'] or 0
        return obj.amount - total_outputs

    def validate(self, data):
        typ = data.get('type') or getattr(self.instance, 'type', None)
        order = data.get('order') if 'order' in data else getattr(self.instance, 'order', None)

        if typ == Input.Type.CLIENT_PAYMENT and not order:
            raise serializers.ValidationError({'order': 'Order is required for client_payment.'})
        if typ == Input.Type.SHOP_DEPOSIT and order:
            raise serializers.ValidationError({'order': 'Order must be empty for shop_deposit.'})
        return data


from rest_framework import serializers
from ..models import Product

class ProductSerializer(serializers.ModelSerializer):
    # Name is optional for updates
    name = serializers.CharField(required=False)
    
    # Add initial_price field for new products with stock
    initial_price = serializers.DecimalField(
        max_digits=12, 
        decimal_places=2, 
        required=False,
        write_only=True,
        help_text="Required when creating product with initial quantity > 0"
    )

    class Meta:
        model = Product
        fields = '__all__'
        read_only_fields = ['id', 'created_at', 'updated_at', 'reference']
    
    def validate(self, data):
        """Validate that initial_price is provided when current_quantity > 0"""
        current_quantity = data.get('current_quantity', 0)
        initial_price = data.get('initial_price')
        
        # Only validate for creation (when instance doesn't exist)
        if not self.instance and current_quantity and current_quantity > 0:
            if initial_price is None:
                raise serializers.ValidationError({
                    'initial_price': 'Initial price is required when creating product with stock quantity.'
                })
            if initial_price < 0:
                raise serializers.ValidationError({
                    'initial_price': 'Initial price cannot be negative.'
                })
        
        return data














