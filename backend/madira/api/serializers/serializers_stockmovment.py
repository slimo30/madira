from rest_framework import serializers
from decimal import Decimal
from django.utils import timezone
from django.db import models, transaction
from ..models import StockMovement, OrderOutput


class StockMovementDisplaySerializer(serializers.ModelSerializer):
    """
    Main serializer for StockMovement display.
    Shows movement type (IN/OUT) and related information.
    """
    product_name = serializers.CharField(source='product.name', read_only=True)
    order_number = serializers.CharField(source='order.order_number', read_only=True)
    
    class Meta:
        model = StockMovement
        fields = [
            'id',
            'product',
            'product_name',
            'order',
            'order_number',
            'movement_type',
            'quantity',
            'price',
            'date',
            'created_at',
        ]
        read_only_fields = ['id', 'created_at', 'price', 'movement_type']


class StockMovementCreateSerializer(serializers.ModelSerializer):
    """
    Serializer for creating OUT stock movements using MEAN (Average) pricing.
    Allows optional manual price override.
    """
    
    price = serializers.DecimalField(
        max_digits=12, 
        decimal_places=2, 
        required=False,
        allow_null=True,
        help_text="Optional: Manual price override. If not provided, uses average price."
    )
    
    class Meta:
        model = StockMovement
        fields = ['product', 'order', 'quantity', 'date', 'price']
    
    def get_average_price(self, product):
        """
        Calculate weighted average price from all available stock.
        Returns: Decimal (average price per unit) rounded to 2 decimal places
        """
        # Get all IN movements for this product
        in_movements = StockMovement.objects.filter(
            product=product,
            movement_type=StockMovement.MovementType.IN
        )
        
        if not in_movements.exists():
            return Decimal('0.00')
        
        # Calculate total cost and total quantity
        total_cost = Decimal('0.00')
        total_quantity = Decimal('0.00')
        
        for in_mov in in_movements:
            # Cost for this batch
            batch_cost = in_mov.quantity * in_mov.price
            total_cost += batch_cost
            total_quantity += in_mov.quantity
        
        # Calculate weighted average price and round to 2 decimal places
        if total_quantity > Decimal('0.00'):
            average_price = total_cost / total_quantity
            # Round to 2 decimal places to fit in DecimalField(max_digits=12, decimal_places=2)
            return average_price.quantize(Decimal('0.01'))
        
        return Decimal('0.00')
    
    def validate(self, data):
        """Validate stock availability and order."""
        if not data.get('order'):
            raise serializers.ValidationError({'order': 'Order is required.'})
        
        product = data.get('product')
        quantity = data.get('quantity')
        manual_price = data.get('price')
        
        if product and quantity:
            quantity = Decimal(str(quantity))
            
            if quantity <= Decimal('0.00'):
                raise serializers.ValidationError({'quantity': 'Quantity must be greater than 0.'})
            
            available = Decimal(str(product.current_quantity))
            if available < quantity:
                raise serializers.ValidationError({
                    'quantity': f'Insufficient stock. Available: {available}, Requested: {quantity}'
                })
        
        # Validate manual price if provided
        if manual_price is not None:
            manual_price = Decimal(str(manual_price))
            if manual_price < Decimal('0.00'):
                raise serializers.ValidationError({
                    'price': 'Price cannot be negative.'
                })
        
        return data
    
    @transaction.atomic
    def create(self, validated_data):
        """
        CREATE LOGIC with flexible pricing:
        1. Use manual price if provided, otherwise calculate average
        2. Create ONE StockMovement with chosen price
        3. Create ONE OrderOutput with total amount
        4. Adjust product quantity
        """
        product = validated_data['product']
        order = validated_data['order']
        quantity = Decimal(str(validated_data['quantity']))
        date = validated_data.get('date', timezone.now())
        user = self.context.get('request').user if self.context.get('request') else None
        
        # Check if manual price is provided
        manual_price = validated_data.get('price')
        
        if manual_price is not None:
            # Use manual price provided by user
            final_price = Decimal(str(manual_price))
            price_type = "manual"
        else:
            # Calculate average price automatically
            final_price = self.get_average_price(product)
            price_type = "avg"
            
            # Allow zero price but warn about it
            if final_price == Decimal('0.00'):
                # Use zero price but mark as such
                final_price = Decimal('0.00')
                price_type = "zero (no cost basis)"
        
        # Calculate total amount
        total_amount = quantity * final_price
        
        # Create ONE StockMovement
        stock_movement = StockMovement.objects.create(
            product=product,
            order=order,
            movement_type=StockMovement.MovementType.OUT,
            quantity=quantity,
            price=final_price,
            date=date,
            created_by=user
        )
        
        # Create ONE OrderOutput
        OrderOutput.objects.create(
            order=order,
            amount=total_amount,
            type=OrderOutput.OutputType.PRODUCT_CONSUMPTION,
            description=f"Stock OUT: {quantity} units of {product.name} @ {final_price} DA/unit ({price_type})",
            created_by_stock_movement=stock_movement
        )
        
        # Adjust product stock
        product.current_quantity = Decimal(str(product.current_quantity)) - quantity
        product.save(update_fields=['current_quantity'])
        
        return stock_movement


class StockMovementUpdateSerializer(serializers.ModelSerializer):
    """
    Serializer for updating OUT stock movements with optional manual price override.
    """
    
    price = serializers.DecimalField(
        max_digits=12, 
        decimal_places=2, 
        required=False,
        allow_null=True,
        help_text="Optional: Manual price override. If not provided, uses average price."
    )
    
    class Meta:
        model = StockMovement
        fields = ['product', 'order', 'quantity', 'date', 'price']
    
    def get_average_price(self, product):
        """
        Calculate weighted average price from all available stock.
        Returns: Decimal (average price per unit) rounded to 2 decimal places
        """
        # Get all IN movements for this product
        in_movements = StockMovement.objects.filter(
            product=product,
            movement_type=StockMovement.MovementType.IN
        )
        
        if not in_movements.exists():
            return Decimal('0.00')
        
        # Calculate total cost and total quantity
        total_cost = Decimal('0.00')
        total_quantity = Decimal('0.00')
        
        for in_mov in in_movements:
            # Cost for this batch
            batch_cost = in_mov.quantity * in_mov.price
            total_cost += batch_cost
            total_quantity += in_mov.quantity
        
        # Calculate weighted average price and round to 2 decimal places
        if total_quantity > Decimal('0.00'):
            average_price = total_cost / total_quantity
            # Round to 2 decimal places to fit in DecimalField(max_digits=12, decimal_places=2)
            return average_price.quantize(Decimal('0.01'))
        
        return Decimal('0.00')
    
    def validate(self, data):
        """Validate update data with stock availability check."""
        order = data.get('order', self.instance.order)
        if not order:
            raise serializers.ValidationError({'order': 'Order is required.'})
        
        quantity = data.get('quantity')
        if quantity is not None:
            quantity = Decimal(str(quantity))
            if quantity <= Decimal('0.00'):
                raise serializers.ValidationError({'quantity': 'Quantity must be greater than 0.'})
        
        # Validate manual price if provided
        manual_price = data.get('price')
        if manual_price is not None:
            manual_price = Decimal(str(manual_price))
            if manual_price < Decimal('0.00'):
                raise serializers.ValidationError({
                    'price': 'Price cannot be negative.'
                })
        
        # CRITICAL: Validate stock availability for updates
        old_product = self.instance.product
        old_quantity = Decimal(str(self.instance.quantity))
        
        new_product = data.get('product', old_product)
        new_quantity = Decimal(str(data.get('quantity', old_quantity)))
        
        # Calculate what the stock would be after the update
        if new_product.id != old_product.id:
            # Product changed - check new product has enough stock
            available_stock = Decimal(str(new_product.current_quantity))
            if available_stock < new_quantity:
                raise serializers.ValidationError({
                    'quantity': f'Insufficient stock in {new_product.name}. Available: {available_stock}, Requested: {new_quantity}'
                })
        else:
            # Same product - check if change in quantity is acceptable
            stock_difference = new_quantity - old_quantity
            current_stock = Decimal(str(new_product.current_quantity))
            
            # Calculate what stock would be after update
            projected_stock = current_stock - stock_difference
            
            if projected_stock < Decimal('0.00'):
                available_for_increase = current_stock + old_quantity
                raise serializers.ValidationError({
                    'quantity': f'Insufficient stock. Current: {current_stock}, Available for this order: {available_for_increase}, Requested: {new_quantity}'
                })
        
        return data
    
    @transaction.atomic
    def update(self, instance, validated_data):
        """
        UPDATE LOGIC with flexible pricing:
        1. Delete existing OrderOutput
        2. Adjust product quantity (return old, deduct new)
        3. Use manual price if provided, otherwise calculate average
        4. Update StockMovement and create new OrderOutput
        """
        old_product = instance.product
        old_quantity = Decimal(str(instance.quantity))
        
        new_product = validated_data.get('product', old_product)
        new_order = validated_data.get('order', instance.order)
        new_quantity = Decimal(str(validated_data.get('quantity', old_quantity)))
        new_date = validated_data.get('date', instance.date)
        
        # STEP 1: Delete existing OrderOutput
        OrderOutput.objects.filter(created_by_stock_movement=instance).delete()
        
        # STEP 2: Adjust product quantities
        if new_product.id != old_product.id:
            # Product changed
            old_product.current_quantity = Decimal(str(old_product.current_quantity)) + old_quantity
            old_product.save(update_fields=['current_quantity'])
            
            new_product.current_quantity = Decimal(str(new_product.current_quantity)) - new_quantity
            new_product.save(update_fields=['current_quantity'])
        else:
            # Same product - adjust by difference
            diff = new_quantity - old_quantity
            new_product.current_quantity = Decimal(str(new_product.current_quantity)) - diff
            new_product.save(update_fields=['current_quantity'])
        
        # STEP 3: Determine price to use
        manual_price = validated_data.get('price')
        
        if manual_price is not None:
            # Use manual price provided by user
            final_price = Decimal(str(manual_price))
            price_type = "manual"
        else:
            # Calculate average price automatically
            final_price = self.get_average_price(new_product)
            price_type = "avg"
            
            if final_price == Decimal('0.00'):
                raise serializers.ValidationError({
                    'product': f'No stock purchase records found for {new_product.name}. '
                               f'Please provide a manual price.'
                })
        
        # Calculate new amount
        total_amount = new_quantity * final_price
        
        # STEP 4: Update StockMovement
        instance.product = new_product
        instance.order = new_order
        instance.quantity = new_quantity
        instance.price = final_price
        instance.date = new_date
        instance.save()
        
        # Create new OrderOutput
        OrderOutput.objects.create(
            order=new_order,
            amount=total_amount,
            type=OrderOutput.OutputType.PRODUCT_CONSUMPTION,
            description=f"Stock OUT: {new_quantity} units of {new_product.name} @ {final_price} DA/unit ({price_type} price)",
            created_by_stock_movement=instance
        )
        
        return instance