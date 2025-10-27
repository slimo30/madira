from rest_framework import viewsets, status, permissions, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from django.shortcuts import get_object_or_404
from django.db.models import Sum, Count, Q
from django.db import transaction
from decimal import Decimal

from ..models import StockMovement, Product, Order, OrderOutput
from ..serializers.serializers_stockmovment import (
    StockMovementDisplaySerializer, 
    StockMovementCreateSerializer, 
    StockMovementUpdateSerializer
)
from ..permissions import IsAdminOrResponsible


# ---------------------------
# Pagination
# ---------------------------
class StockMovementPagination(PageNumberPagination):
    page_size = 20
    page_size_query_param = 'page_size'
    max_page_size = 100


# ---------------------------
# Simplified StockMovement ViewSet
# ---------------------------
class StockMovementViewSet(viewsets.ModelViewSet):
    """
    Simplified ViewSet for StockMovements with essential operations only.
    
    Endpoints:
    - POST /stock-movements/ - Create new OUT movement (deducts stock)
    - PUT /stock-movements/{id}/ - Update movement (adjusts stock accordingly)
    - DELETE /stock-movements/{id}/ - Delete movement (returns stock)
    - GET /stock-movements/by_product/?product_id=X - Filter by product
    - GET /stock-movements/statistics/ - Get movement statistics
    """

    queryset = StockMovement.objects.select_related(
        'product', 'order', 'created_by'
    ).prefetch_related(
        'order__client'
    ).order_by('-date')

    permission_classes = [permissions.IsAuthenticated]
    pagination_class = StockMovementPagination

    def get_serializer_class(self):
        """Return appropriate serializer based on action."""
        if self.action == 'create':
            return StockMovementCreateSerializer
        elif self.action in ['update', 'partial_update']:
            return StockMovementUpdateSerializer
        return StockMovementDisplaySerializer

    # Disable list and retrieve endpoints
    def list(self, request, *args, **kwargs):
        return Response(
            {'detail': 'List endpoint disabled. Use by_product endpoint instead.'}, 
            status=status.HTTP_405_METHOD_NOT_ALLOWED
        )
    
    def retrieve(self, request, *args, **kwargs):
        return Response(
            {'detail': 'Retrieve endpoint disabled.'}, 
            status=status.HTTP_405_METHOD_NOT_ALLOWED
        )

    def create(self, request, *args, **kwargs):
        """
        Create new OUT stock movement.
        Automatically calculates FIFO price and updates related records.
        """
        serializer = self.get_serializer(data=request.data, context={'request': request})
        serializer.is_valid(raise_exception=True)
        
        with transaction.atomic():
            stock_movement = serializer.save()
            
        # Return the created movement with full details
        response_serializer = StockMovementDisplaySerializer(stock_movement)
        headers = self.get_success_headers(response_serializer.data)
        
        return Response(
            response_serializer.data, 
            status=status.HTTP_201_CREATED, 
            headers=headers
        )

    def update(self, request, *args, **kwargs):
        """
        Update stock movement with smart stock adjustment.
        Only admin or responsible users can update movements.
        """
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        
        serializer = self.get_serializer(
            instance, 
            data=request.data, 
            partial=partial,
            context={'request': request}
        )
        serializer.is_valid(raise_exception=True)
        
        with transaction.atomic():
            updated_instance = serializer.save()
        
        # Return updated data
        response_serializer = StockMovementDisplaySerializer(updated_instance)
        return Response(response_serializer.data)

    @transaction.atomic
    def destroy(self, request, *args, **kwargs):
        """
        DELETE LOGIC:
        1. Find all related StockMovements (same operation)
        2. Delete all OrderOutputs
        3. ADJUST product quantity (return stock)
        4. Delete all StockMovements
        """
        instance = self.get_object()
        
        # STEP 1: Find all related StockMovements from same operation
        related_movements = StockMovement.objects.filter(
            product=instance.product,
            order=instance.order,
            movement_type=StockMovement.MovementType.OUT,
            created_by=instance.created_by,
            date=instance.date
        )
        
        # Calculate total quantity to return
        total_qty_to_return = Decimal('0.00')
        deleted_order_outputs_count = 0
        
        # STEP 2: Delete all OrderOutputs and sum quantities
        for mov in related_movements:
            order_outputs = OrderOutput.objects.filter(created_by_stock_movement=mov)
            deleted_order_outputs_count += order_outputs.count()
            order_outputs.delete()
            
            total_qty_to_return += mov.quantity
        
        # STEP 3: ADJUST product quantity (return stock for OUT movements)
        if instance.movement_type == StockMovement.MovementType.OUT:
            product = instance.product
            product.current_quantity += total_qty_to_return
            product.save(update_fields=['current_quantity'])
        
        # Get data for response before deletion
        movement_data = StockMovementDisplaySerializer(instance).data
        
        # STEP 4: Delete all related StockMovements
        deleted_movements_count = related_movements.count()
        related_movements.delete()
        
        return Response({
            'message': 'Stock movement deleted successfully',
            'returned_quantity': float(total_qty_to_return),
            'product_name': instance.product.name,
            'deleted_movements_count': deleted_movements_count,
            'deleted_order_outputs_count': deleted_order_outputs_count,
            'deleted_movement': movement_data
        }, status=status.HTTP_200_OK)

    @action(detail=False, methods=['get'])
    def by_product(self, request):
        """GET /stock-movements/by_product/?product_id=X"""
        product_id = request.query_params.get('product_id')
        if not product_id:
            return Response(
                {'error': 'product_id parameter is required'}, 
                status=status.HTTP_400_BAD_REQUEST
            )
        
        try:
            product = Product.objects.get(id=product_id)
        except Product.DoesNotExist:
            return Response(
                {'error': 'Product not found'}, 
                status=status.HTTP_404_NOT_FOUND
            )
        
        queryset = self.get_queryset().filter(product=product)
        
        # Calculate stock statistics
        in_movements = queryset.filter(movement_type=StockMovement.MovementType.IN)
        out_movements = queryset.filter(movement_type=StockMovement.MovementType.OUT)
        
        total_in = in_movements.aggregate(total=Sum('quantity'))['total'] or Decimal('0.00')
        total_out = out_movements.aggregate(total=Sum('quantity'))['total'] or Decimal('0.00')
        calculated_stock = total_in - total_out
        
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response({
                'product': {
                    'id': product.id, 
                    'name': product.name,
                    'current_quantity': float(product.current_quantity),
                    'unit': product.get_unit_display(),
                    'calculated_from_movements': float(calculated_stock),
                    'total_in': float(total_in),
                    'total_out': float(total_out)
                },
                'movements': serializer.data
            })
        
        serializer = self.get_serializer(queryset, many=True)
        return Response({
            'product': {
                'id': product.id, 
                'name': product.name,
                'current_quantity': float(product.current_quantity),
                'unit': product.get_unit_display(),
                'calculated_from_movements': float(calculated_stock),
                'total_in': float(total_in),
                'total_out': float(total_out)
            },
            'movements': serializer.data
        })

    @action(detail=False, methods=['get'])
    def statistics(self, request):
        """GET /stock-movements/statistics/ - Get comprehensive statistics"""
        # Overall stats
        total_movements = self.get_queryset().count()
        
        # By movement type
        by_type = StockMovement.objects.values('movement_type').annotate(
            count=Count('id'),
            total_quantity=Sum('quantity')
        )
        
        # By product (top 10 most moved)
        by_product = StockMovement.objects.values(
            'product__name', 'product__id'
        ).annotate(
            total_movements=Count('id'),
            total_quantity=Sum('quantity')
        ).order_by('-total_quantity')[:10]
        
        # Recent activity (last 7 days)
        from datetime import datetime, timedelta
        week_ago = datetime.now() - timedelta(days=7)
        recent_activity = StockMovement.objects.filter(
            date__gte=week_ago
        ).count()
        
        return Response({
            'overview': {
                'total_movements': total_movements,
                'recent_activity_7_days': recent_activity,
            },
            'by_movement_type': list(by_type),
            'top_products': list(by_product),
        })