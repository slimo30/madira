from rest_framework import serializers
from .models import User

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
    




from .models import Client , Supplier


class ClientSerializer(serializers.ModelSerializer):
    class Meta:
        model = Client
        fields = '__all__'

class SupplierSerializer(serializers.ModelSerializer):
    class Meta:
        model = Supplier
        fields = '__all__'





from rest_framework import serializers
from .models import Input

class InputSerializer(serializers.ModelSerializer):
    created_by = serializers.ReadOnlyField(source='created_by.username')
    reference = serializers.ReadOnlyField()

    class Meta:
        model = Input
        fields = [
            'id', 'type', 'client', 'amount', 'description', 'reference',
            'date', 'created_by', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'reference', 'created_by', 'created_at', 'updated_at']

    def validate(self, data):
        typ = data.get('type') or getattr(self.instance, 'type', None)
        client = data.get('client') if 'client' in data else getattr(self.instance, 'client', None)

        if typ == Input.Type.CLIENT_PAYMENT and not client:
            raise serializers.ValidationError({'client': 'Client is required for client_payment.'})
        if typ == Input.Type.SHOP_DEPOSIT and client:
            raise serializers.ValidationError({'client': 'Client must be empty for shop_deposit.'})
        return data





from rest_framework import serializers
from .models import Order, Client


class ClientSerializer(serializers.ModelSerializer):
    class Meta:
        model = Client
        fields = ['id', 'name']


from rest_framework import serializers
from .models import Order


class OrderSerializer(serializers.ModelSerializer):
    # ✅ Custom read-only fields
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
from .models import Input

class InputSerializer(serializers.ModelSerializer):
    created_by_name = serializers.CharField(source='created_by.username', read_only=True)
    order_number = serializers.CharField(source='order.order_number', read_only=True)

    class Meta:
        model = Input
        fields = [
            'id', 'reference', 'type', 'amount', 'description',
            'order', 'order_number',
            'created_by', 'created_by_name',
            'date', 'created_at', 'updated_at'
        ]
        read_only_fields = ['reference', 'created_at', 'updated_at', 'created_by']



from rest_framework import serializers
from .models import Product

class ProductSerializer(serializers.ModelSerializer):
    # Name is optional for updates
    name = serializers.CharField(required=False)

    class Meta:
        model = Product
        fields = '__all__'
        read_only_fields = ['id', 'created_at', 'updated_at', 'reference']
