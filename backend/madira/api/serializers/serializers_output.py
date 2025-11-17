from rest_framework import serializers
from decimal import Decimal, ROUND_HALF_UP
from django.db import transaction
from ..models import (
    Output, Input, Order, Supplier, Product, 
    StockMovement, OrderOutput, User
)


class OrderOutputSerializer(serializers.ModelSerializer):
    """Nested serializer for OrderOutput with creation info."""
    type_display = serializers.CharField(source='get_type_display', read_only=True)
    created_by_output_reference = serializers.CharField(
        source='created_by_output.reference', 
        read_only=True,
        help_text="Reference of the Output that created this OrderOutput"
    )
    
    class Meta:
        model = OrderOutput
        fields = [
            'id', 'amount', 'type', 'type_display', 'description',
            'created_by_output', 'created_by_output_reference',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']


class StockMovementSerializer(serializers.ModelSerializer):
    """Nested serializer for StockMovement with creation info."""
    product_name = serializers.CharField(source='product.name', read_only=True)
    order_number = serializers.CharField(source='order.order_number', read_only=True)
    movement_type_display = serializers.CharField(source='get_movement_type_display', read_only=True)
    
    created_by_username = serializers.CharField(source='created_by.username', read_only=True)
    created_by_output_reference = serializers.CharField(
        source='created_by_output.reference',
        read_only=True,
        help_text="Reference of the Output that created this StockMovement"
    )
    
    class Meta:
        model = StockMovement
        fields = [
            'id', 'product', 'product_name', 'order', 'order_number',
            'movement_type', 'movement_type_display', 'quantity', 'price', 'signed_quantity',
            'date', 'created_by', 'created_by_username',
            'created_by_output', 'created_by_output_reference',
            'created_at'
        ]
        read_only_fields = ['id', 'signed_quantity', 'created_at']


class OutputSerializer(serializers.ModelSerializer):
    """
    Unified Output serializer handling CREATE, UPDATE, and DELETE:
    - Auto-calculates amount for stock operations using price from request
    - Auto-generates descriptions
    - Creates/Updates/Deletes OrderOutput and StockMovement instances
    - Shows related OrderOutputs and StockMovements
    - Handles proper rollback on update/delete
    - Enforces type-specific field constraints on updates
    """
    
    # Read-only display fields
    created_by_username = serializers.CharField(source='created_by.username', read_only=True)
    source_input_reference = serializers.CharField(source='source_input.reference', read_only=True)
    order_number = serializers.CharField(source='order.order_number', read_only=True)
    client_id = serializers.IntegerField(source='order.client.id', read_only=True)
    client_name = serializers.CharField(source='order.client.name', read_only=True)
    supplier_name = serializers.CharField(source='supplier.name', read_only=True)
    product_name = serializers.CharField(source='product.name', read_only=True)
    type_display = serializers.CharField(source='get_type_display', read_only=True)
    
    # Related instances created by this Output
    related_order_outputs = OrderOutputSerializer(
        source='order_outputs',
        many=True,
        read_only=True,
        help_text="OrderOutputs created by this Output"
    )
    related_stock_movements = StockMovementSerializer(
        source='stock_movements',
        many=True,
        read_only=True,
        help_text="StockMovements created by this Output"
    )
    
    # Helper fields for stock operations
    quantity = serializers.DecimalField(
        max_digits=10, 
        decimal_places=2, 
        required=False,
        write_only=True,
        help_text="Required for GLOBAL_STOCK_PURCHASE and CLIENT_STOCK_USAGE"
    )
    
    price = serializers.DecimalField(
        max_digits=12,
        decimal_places=2,
        required=False,
        write_only=True,
        help_text="Price per unit for stock operations (required for GLOBAL_STOCK_PURCHASE and CLIENT_STOCK_USAGE)"
    )
    
    class Meta:
        model = Output
        fields = [
            'id', 'type', 'type_display', 'amount', 'description', 'reference', 'date',
            'created_by', 'created_by_username',
            'source_input', 'source_input_reference',
            'order', 'order_number',
            'client_id', 'client_name',
            'supplier', 'supplier_name',
            'product', 'product_name',
            'quantity', 'price',
            'related_order_outputs',
            'related_stock_movements',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'reference', 'created_at', 'updated_at']
        extra_kwargs = {
            'amount': {'required': False},
            'description': {'required': False},
            'created_by': {'required': False},  # Will be set from request.user
        }
    
    def _clean_fields_for_type(self, data, output_type):
        """
        Clean fields based on output type to respect model constraints.
        This ensures that forbidden fields are set to None.
        """
        cleaned = data.copy()
        
        if output_type == Output.Type.WITHDRAWAL:
            # Cannot have order, supplier, or product
            cleaned['order'] = None
            cleaned['supplier'] = None
            cleaned['product'] = None
        
        elif output_type == Output.Type.SUPPLIER_PAYMENT:
            # Cannot have product
            cleaned['product'] = None
        
        elif output_type == Output.Type.CONSUMABLE:
            # Cannot have order, supplier, or product
            cleaned['order'] = None
            cleaned['supplier'] = None
            cleaned['product'] = None
        
        elif output_type == Output.Type.GLOBAL_STOCK_PURCHASE:
            # Cannot have order or supplier
            cleaned['order'] = None
            cleaned['supplier'] = None
        
        elif output_type == Output.Type.CLIENT_STOCK_USAGE:
            # Cannot have supplier
            cleaned['supplier'] = None
        
        elif output_type == Output.Type.OTHER_EXPENSE:
            # Cannot have supplier or product
            cleaned['supplier'] = None
            cleaned['product'] = None
        
        return cleaned
    
    def validate(self, data):
        """Validate and auto-calculate amount if needed."""
        # For updates, merge with existing instance data
        if self.instance:
            output_type = data.get('type', self.instance.type)
            order = data.get('order', self.instance.order)
            supplier = data.get('supplier', self.instance.supplier)
            product = data.get('product', self.instance.product)
            quantity = data.get('quantity')
            price = data.get('price')
            amount = data.get('amount', self.instance.amount)
            source_input = data.get('source_input', self.instance.source_input)
            
            # If type changed, enforce field cleanup
            if 'type' in data and data['type'] != self.instance.type:
                data = self._clean_fields_for_type(data, output_type)
                # Re-extract after cleaning
                order = data.get('order')
                supplier = data.get('supplier')
                product = data.get('product')
        else:
            output_type = data.get('type')
            order = data.get('order')
            supplier = data.get('supplier')
            product = data.get('product')
            quantity = data.get('quantity')
            price = data.get('price')
            amount = data.get('amount')
            source_input = data.get('source_input')
        
        # Type-specific validation
        if output_type == Output.Type.WITHDRAWAL:
            if order or supplier or product:
                raise serializers.ValidationError(
                    "WITHDRAWAL cannot have order, supplier, or product."
                )
            if not amount:
                raise serializers.ValidationError("Amount is required for WITHDRAWAL.")
        
        elif output_type == Output.Type.SUPPLIER_PAYMENT:
            if not supplier:
                raise serializers.ValidationError("SUPPLIER_PAYMENT requires a supplier.")
            if not order:
                raise serializers.ValidationError("SUPPLIER_PAYMENT requires an order.")
            if product:
                raise serializers.ValidationError("SUPPLIER_PAYMENT cannot have a product.")
            if not amount:
                raise serializers.ValidationError("Amount is required for SUPPLIER_PAYMENT.")
        
        elif output_type == Output.Type.CONSUMABLE:
            if order or supplier or product:
                raise serializers.ValidationError(
                    "CONSUMABLE cannot have order, supplier, or product."
                )
            if not amount:
                raise serializers.ValidationError("Amount is required for CONSUMABLE.")
        
        elif output_type == Output.Type.GLOBAL_STOCK_PURCHASE:
            if not product:
                raise serializers.ValidationError("GLOBAL_STOCK_PURCHASE requires a product.")
            if order or supplier:
                raise serializers.ValidationError(
                    "GLOBAL_STOCK_PURCHASE cannot have order or supplier."
                )
            if not quantity:
                raise serializers.ValidationError(
                    "Quantity is required for GLOBAL_STOCK_PURCHASE."
                )
            if not price:
                raise serializers.ValidationError(
                    "Price is required for GLOBAL_STOCK_PURCHASE."
                )
            # Auto-calculate amount and round it
            calculated_amount = Decimal(str(quantity)) * Decimal(str(price))
            data['amount'] = calculated_amount.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)
        
        elif output_type == Output.Type.CLIENT_STOCK_USAGE:
            if not order:
                raise serializers.ValidationError("CLIENT_STOCK_USAGE requires an order.")
            if not product:
                raise serializers.ValidationError("CLIENT_STOCK_USAGE requires a product.")
            if supplier:
                raise serializers.ValidationError("CLIENT_STOCK_USAGE cannot have a supplier.")
            if not quantity:
                raise serializers.ValidationError("Quantity is required for CLIENT_STOCK_USAGE.")
            if not price:
                raise serializers.ValidationError(
                    "Price is required for CLIENT_STOCK_USAGE."
                )
            # Auto-calculate amount and round it
            calculated_amount = Decimal(str(quantity)) * Decimal(str(price))
            data['amount'] = calculated_amount.quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)
        
        elif output_type == Output.Type.OTHER_EXPENSE:
            if supplier or product:
                raise serializers.ValidationError(
                    "OTHER_EXPENSE cannot have supplier or product."
                )
            if not amount:
                raise serializers.ValidationError("Amount is required for OTHER_EXPENSE.")
        
        # Round amount if it exists and hasn't been auto-calculated (for non-stock operations)
        if 'amount' in data and data['amount'] is not None:
            # Only round if it wasn't already calculated above
            if output_type not in [Output.Type.GLOBAL_STOCK_PURCHASE, Output.Type.CLIENT_STOCK_USAGE]:
                data['amount'] = Decimal(str(data['amount'])).quantize(Decimal('0.01'), rounding=ROUND_HALF_UP)
        
        # Validate source_input has sufficient balance
        if source_input:
            # Get the amount we're trying to use (from data or instance)
            amount_to_use = data.get('amount', amount if self.instance else None)
            
            if amount_to_use:
                # For updates, exclude current instance amount
                if self.instance:
                    total_used = source_input.outputs.exclude(pk=self.instance.pk).aggregate(
                        total=serializers.models.Sum('amount')
                    )['total'] or Decimal('0.00')
                else:
                    total_used = source_input.outputs.aggregate(
                        total=serializers.models.Sum('amount')
                    )['total'] or Decimal('0.00')
                
                remaining = source_input.amount - total_used
                
                if amount_to_use > remaining:
                    raise serializers.ValidationError(
                        f"Insufficient funds in input {source_input.reference}. "
                        f"Available: {remaining} DA"
                    )

        return data
    
    def _generate_description(self, validated_data, quantity=None, price=None, instance=None):
        """Auto-generate description based on output type."""
        # Get values from validated_data or fallback to instance
        if instance:
            output_type = validated_data.get('type', instance.type)
            amount = validated_data.get('amount', instance.amount)
            created_by = validated_data.get('created_by', instance.created_by)
            supplier = validated_data.get('supplier', instance.supplier)
            order = validated_data.get('order', instance.order)
            product = validated_data.get('product', instance.product)
        else:
            output_type = validated_data['type']
            amount = validated_data['amount']
            created_by = validated_data['created_by']
            supplier = validated_data.get('supplier')
            order = validated_data.get('order')
            product = validated_data.get('product')
        
        if output_type == Output.Type.WITHDRAWAL:
            return f"Withdrawal of {amount} DA by {created_by.username}"
        
        elif output_type == Output.Type.SUPPLIER_PAYMENT:
            return f"Payment of {amount} DA to {supplier.name} for order {order.order_number}"
        
        elif output_type == Output.Type.CONSUMABLE:
            return f"Consumable expense of {amount} DA"
        
        elif output_type == Output.Type.GLOBAL_STOCK_PURCHASE:
            qty = quantity or 0
            unit_price = price or 0
            return f"Stock purchase: {qty} {product.get_unit_display()} of {product.name} at {unit_price} DA/unit (Total: {amount} DA)"
        
        elif output_type == Output.Type.CLIENT_STOCK_USAGE:
            qty = quantity or 0
            unit_price = price or 0
            return f"Stock usage: {qty} {product.get_unit_display()} of {product.name} at {unit_price} DA/unit for order {order.order_number} (Total: {amount} DA)"
        
        elif output_type == Output.Type.OTHER_EXPENSE:
            if order:
                return f"Other expense of {amount} DA for order {order.order_number}"
            return f"Other expense of {amount} DA"
        
        return f"Output of {amount} DA"
    
    def _rollback_related_instances(self, instance):
        """
        IMPROVED: Delete and reverse effects of related OrderOutputs and StockMovements.
        Ensures complete cleanup with proper product quantity adjustments.
        """
        # Get all related stock movements BEFORE deletion
        stock_movements = list(instance.stock_movements.select_related('product').all())
        
        # Track product quantity changes
        product_adjustments = {}
        
        # Calculate all quantity adjustments first
        for stock_movement in stock_movements:
            product_id = stock_movement.product.id
            
            if product_id not in product_adjustments:
                product_adjustments[product_id] = {
                    'product': stock_movement.product,
                    'adjustment': Decimal('0.00')
                }
            
            # Reverse the movement: if it was IN, we subtract; if OUT, we add
            if stock_movement.movement_type == StockMovement.MovementType.IN:
                product_adjustments[product_id]['adjustment'] -= stock_movement.quantity
            else:  # OUT
                product_adjustments[product_id]['adjustment'] += stock_movement.quantity
        
        # Apply all adjustments to products in bulk
        products_to_update = []
        for product_data in product_adjustments.values():
            product = product_data['product']
            adjustment = product_data['adjustment']
            
            # Refresh from DB to get latest quantity
            product.refresh_from_db()
            
            # Apply adjustment
            product.current_quantity += adjustment
            
            # Ensure non-negative quantity
            if product.current_quantity < 0:
                product.current_quantity = Decimal('0.00')
            
            products_to_update.append(product)
        
        # Bulk update products
        if products_to_update:
            Product.objects.bulk_update(products_to_update, ['current_quantity'])
        
        # Delete all related OrderOutputs (cascading will handle relations)
        deleted_order_outputs = instance.order_outputs.all().delete()
        
        # Delete all related StockMovements
        deleted_stock_movements = instance.stock_movements.all().delete()
        
        return {
            'order_outputs_deleted': deleted_order_outputs[0] if deleted_order_outputs else 0,
            'stock_movements_deleted': deleted_stock_movements[0] if deleted_stock_movements else 0,
            'products_adjusted': len(products_to_update)
        }
    
    def _create_related_instances(self, output, quantity=None, price=None):
        """
        IMPROVED: Create OrderOutput and StockMovement instances for the output.
        Ensures proper product quantity updates with validation.
        """
        output_type = output.type
        
        # Create OrderOutput for order-related expenses
        if output_type in [
            Output.Type.SUPPLIER_PAYMENT,
            Output.Type.CLIENT_STOCK_USAGE,
            Output.Type.OTHER_EXPENSE
        ] and output.order:
            order_output_type = {
                Output.Type.SUPPLIER_PAYMENT: OrderOutput.OutputType.SUPPLIER_PAYMENT,
                Output.Type.CLIENT_STOCK_USAGE: OrderOutput.OutputType.PRODUCT_CONSUMPTION,
                Output.Type.OTHER_EXPENSE: OrderOutput.OutputType.OTHER_EXPENSE,
            }[output_type]
            
            OrderOutput.objects.create(
                order=output.order,
                amount=output.amount,
                type=order_output_type,
                description=output.description,
                created_by_output=output
            )
        
        # Handle stock operations
        if output_type == Output.Type.GLOBAL_STOCK_PURCHASE and quantity and price:
            # Stock IN - increase quantity
            product = output.product
            product.refresh_from_db()  # Ensure latest data
            
            StockMovement.objects.create(
                product=product,
                movement_type=StockMovement.MovementType.IN,
                quantity=quantity,
                price=price,
                date=output.date,
                created_by=output.created_by,
                created_by_output=output
            )
            
            product.current_quantity += quantity
            product.save(update_fields=['current_quantity'])

        elif output_type == Output.Type.CLIENT_STOCK_USAGE and quantity and price:
            product = output.product
            product.refresh_from_db()  # Ensure latest data
            
            # Create IN instance first (history of reception)
            StockMovement.objects.create(
                product=product,
                movement_type=StockMovement.MovementType.IN,
                quantity=quantity,
                price=price,
                date=output.date,
                created_by=output.created_by,
                created_by_output=output
            )
            product.current_quantity += quantity
            product.save(update_fields=['current_quantity'])

            # Then create OUT instance (actual usage)
            StockMovement.objects.create(
                product=product,
                order=output.order,
                movement_type=StockMovement.MovementType.OUT,
                quantity=quantity,
                price=price,
                date=output.date,
                created_by=output.created_by,
                created_by_output=output
            )
            
            # Validate sufficient stock before deducting
            product.refresh_from_db()
            if product.current_quantity < quantity:
                raise serializers.ValidationError(
                    f"Insufficient stock for {product.name}. "
                    f"Available: {product.current_quantity}, Required: {quantity}"
                )
            
            product.current_quantity -= quantity
            product.save(update_fields=['current_quantity'])
    
    @transaction.atomic
    def create(self, validated_data):
        """Create Output with related instances."""
        
        quantity = validated_data.pop('quantity', None)
        price = validated_data.pop('price', None)
        
        # Auto-generate description if not provided
        if not validated_data.get('description'):
            validated_data['description'] = self._generate_description(validated_data, quantity, price)
        
        # Create Output first
        output = Output.objects.create(**validated_data)
        
        # Create related instances
        self._create_related_instances(output, quantity, price)
        
        return output
    
    @transaction.atomic
    def update(self, instance, validated_data):
        """
        IMPROVED: Update Output with proper rollback and re-creation:
        1. Check if type is changing and clean incompatible fields
        2. Rollback ALL related instances (OrderOutputs + StockMovements)
        3. Update Output fields
        4. Re-create related instances with new data
        5. Validate product quantities remain non-negative
        """
        
        quantity = validated_data.pop('quantity', None)
        price = validated_data.pop('price', None)
        
        # Step 1: If type is changing, clean incompatible fields
        if 'type' in validated_data and validated_data['type'] != instance.type:
            validated_data = self._clean_fields_for_type(validated_data, validated_data['type'])
        
        # Step 2: Rollback ALL related instances
        rollback_info = self._rollback_related_instances(instance)
        
        # Step 3: Auto-generate description if not provided
        if 'description' not in validated_data:
            validated_data['description'] = self._generate_description(
                validated_data, quantity, price, instance
            )
        
        # Step 4: Update Output fields
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        
        # Step 5: Call full_clean to trigger model-level validation
        try:
            instance.full_clean()
        except Exception as e:
            raise serializers.ValidationError(str(e))
        
        instance.save()
        
        # Step 6: Re-create related instances with new data
        self._create_related_instances(instance, quantity, price)
        
        return instance
    
    @transaction.atomic
    def delete(self):
        """
        IMPROVED: Delete Output with complete cleanup:
        1. Rollback all StockMovements and restore product quantities
        2. Delete all related OrderOutputs
        3. Delete the Output itself
        4. Return detailed cleanup information
        """
        instance = self.instance
        
        if not instance:
            raise serializers.ValidationError("No output instance provided.")
        
        # Store info before deletion
        output_id = instance.id
        output_reference = instance.reference
        output_type = instance.get_type_display()
        
        # Rollback all related instances and get cleanup info
        cleanup_info = self._rollback_related_instances(instance)
        
        # Delete the Output (will cascade to any remaining related objects)
        instance.delete()
        
        return {
            'id': output_id,
            'reference': output_reference,
            'type': output_type,
            'message': 'Output deleted successfully with all related data cleaned up.',
            'cleanup_details': {
                'order_outputs_removed': cleanup_info['order_outputs_deleted'],
                'stock_movements_removed': cleanup_info['stock_movements_deleted'],
                'products_quantity_restored': cleanup_info['products_adjusted']
            }
        }