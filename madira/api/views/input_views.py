from rest_framework import generics, permissions, filters, status
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from django.db import transaction
from django.core.exceptions import ValidationError
from decimal import Decimal
from ..models import Input, Order
from ..serializers.serializers import InputSerializer
from ..permissions import IsAdminOrResponsible


class InputPagination(PageNumberPagination):
    page_size = 10
    page_size_query_param = 'page_size'
    max_page_size = 100


class InputListCreateView(generics.ListCreateAPIView):
    """
    List all inputs or create a new one.
    Only Admins or Responsibles can add a shop deposit (create).
    Prevents overpayment on CLIENT_PAYMENT type.
    """
    queryset = Input.objects.select_related('created_by', 'order__client').order_by('-date')
    serializer_class = InputSerializer
    permission_classes = [permissions.IsAuthenticated, IsAdminOrResponsible]
    pagination_class = InputPagination
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['reference', 'description', 'order__order_number', 'order__client__name']
    ordering_fields = ['date', 'amount', 'type']

    def create(self, request, *args, **kwargs):
        """Create with overpayment validation"""
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        
        # Validate overpayment for CLIENT_PAYMENT type
        input_type = serializer.validated_data.get('type')
        order = serializer.validated_data.get('order')
        amount = serializer.validated_data.get('amount')
        
        if input_type == Input.Type.CLIENT_PAYMENT and order:
            # Calculate current paid amount
            current_paid = order.paid_amount
            
            # Check if new payment would exceed order total
            total_after = current_paid + amount
            
            if total_after > order.total_amount:
                return Response(
                    {
                        "error": "Payment would exceed order total",
                        "details": {
                            "order_number": order.order_number,
                            "order_total": str(order.total_amount),
                            "already_paid": str(current_paid),
                            "remaining": str(order.remaining_amount),
                            "attempted_payment": str(amount),
                            "would_total": str(total_after),
                            "overpayment": str(total_after - order.total_amount)
                        }
                    },
                    status=status.HTTP_400_BAD_REQUEST
                )
        
        # Proceed with creation
        self.perform_create(serializer)
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)

    def perform_create(self, serializer):
        """Set the current user automatically when creating an Input"""
        with transaction.atomic():
            serializer.save(created_by=self.request.user)


class InputRetrieveUpdateDeleteView(generics.RetrieveUpdateDestroyAPIView):
    """
    Retrieve, update, or delete an input.
    The paid_amount is automatically calculated from the sum of all inputs.
    Prevents overpayment when updating CLIENT_PAYMENT type.
    """
    queryset = Input.objects.select_related('created_by', 'order__client').all()
    serializer_class = InputSerializer
    permission_classes = [permissions.IsAuthenticated]

    def update(self, request, *args, **kwargs):
        """Update with comprehensive overpayment validation for all scenarios"""
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        
        # Get old and new values
        old_type = instance.type
        old_order = instance.order
        old_amount = instance.amount
        
        new_type = serializer.validated_data.get('type', instance.type)
        new_order = serializer.validated_data.get('order', instance.order)
        new_amount = serializer.validated_data.get('amount', instance.amount)
        
        # Only validate if it's a CLIENT_PAYMENT type (old or new)
        if new_type == Input.Type.CLIENT_PAYMENT and new_order:
            
            # CASE 1: Changing to a different order
            if old_order and new_order and old_order.id != new_order.id:
                # Check if new order would have overpayment
                new_order_current_paid = new_order.paid_amount
                new_order_total_after = new_order_current_paid + new_amount
                
                if new_order_total_after > new_order.total_amount:
                    return Response(
                        {
                            "error": "Payment would exceed the new order's total",
                            "details": {
                                "old_order": old_order.order_number,
                                "new_order": new_order.order_number,
                                "new_order_total": str(new_order.total_amount),
                                "new_order_already_paid": str(new_order_current_paid),
                                "new_order_remaining": str(new_order.remaining_amount),
                                "payment_amount": str(new_amount),
                                "would_total": str(new_order_total_after),
                                "overpayment": str(new_order_total_after - new_order.total_amount),
                                "message": f"Cannot move this payment of {new_amount} DA to order {new_order.order_number}. "
                                          f"That order only has {new_order.remaining_amount} DA remaining unpaid."
                            }
                        },
                        status=status.HTTP_400_BAD_REQUEST
                    )
            
            # CASE 2: Same order, changing amount
            elif new_order.id == (old_order.id if old_order else None):
                # Calculate current paid amount (excluding this input's old amount)
                current_paid = new_order.paid_amount - old_amount
                
                # Check if updated payment would exceed order total
                total_after = current_paid + new_amount
                
                if total_after > new_order.total_amount:
                    return Response(
                        {
                            "error": "Updated payment would exceed order total",
                            "details": {
                                "order_number": new_order.order_number,
                                "order_total": str(new_order.total_amount),
                                "old_payment": str(old_amount),
                                "new_payment": str(new_amount),
                                "other_payments": str(current_paid),
                                "remaining_before_update": str(new_order.remaining_amount),
                                "would_total": str(total_after),
                                "overpayment": str(total_after - new_order.total_amount),
                                "message": f"Cannot change payment from {old_amount} DA to {new_amount} DA. "
                                          f"Order currently has {current_paid} DA paid (excluding this payment). "
                                          f"Maximum allowed for this payment: {new_order.total_amount - current_paid} DA"
                            }
                        },
                        status=status.HTTP_400_BAD_REQUEST
                    )
            
            # CASE 3: Changing from SHOP_DEPOSIT to CLIENT_PAYMENT (adding to an order)
            elif old_type != Input.Type.CLIENT_PAYMENT and new_type == Input.Type.CLIENT_PAYMENT:
                new_order_current_paid = new_order.paid_amount
                total_after = new_order_current_paid + new_amount
                
                if total_after > new_order.total_amount:
                    return Response(
                        {
                            "error": "Converting this deposit to a payment would exceed order total",
                            "details": {
                                "order_number": new_order.order_number,
                                "order_total": str(new_order.total_amount),
                                "order_already_paid": str(new_order_current_paid),
                                "order_remaining": str(new_order.remaining_amount),
                                "deposit_amount": str(new_amount),
                                "would_total": str(total_after),
                                "overpayment": str(total_after - new_order.total_amount),
                                "message": f"Cannot convert this {new_amount} DA deposit to a payment for order {new_order.order_number}. "
                                          f"That order only has {new_order.remaining_amount} DA remaining unpaid."
                            }
                        },
                        status=status.HTTP_400_BAD_REQUEST
                    )
        
        # Proceed with update
        self.perform_update(serializer)
        
        if getattr(instance, '_prefetched_objects_cache', None):
            instance._prefetched_objects_cache = {}
        
        return Response(serializer.data)

    def perform_update(self, serializer):
        """
        When updating an Input, just save it.
        The Order.paid_amount property will automatically calculate the sum.
        Optionally update order status if it becomes fully paid.
        """
        with transaction.atomic():
            instance = serializer.save()
            
            # Update order status if it becomes fully paid
            if instance.order and instance.type == Input.Type.CLIENT_PAYMENT:
                if instance.order.is_fully_paid and instance.order.status != Order.Status.COMPLETED:
                    instance.order.status = Order.Status.COMPLETED
                    instance.order.save(update_fields=['status'])

    def delete(self, request, *args, **kwargs):
        """
        When deleting an Input, just delete it.
        The Order.paid_amount property will automatically recalculate.
        """
        instance = self.get_object()
        order = instance.order
        ref = instance.reference

        with transaction.atomic():
            instance.delete()
            
            # Update order status if it's no longer fully paid
            if order and order.is_fully_paid is False and order.status == Order.Status.COMPLETED:
                # If order was completed but now isn't fully paid, revert to IN_PROGRESS
                order.status = Order.Status.IN_PROGRESS
                order.save(update_fields=['status'])

        return Response(
            {"detail": f"Input {ref} deleted successfully."},
            status=status.HTTP_200_OK
        )


class ClientInputsListView(generics.ListAPIView):
    serializer_class = InputSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = InputPagination
    filter_backends = [filters.OrderingFilter]
    ordering_fields = ['date', 'amount', 'type']
    ordering = ['-date']

    def get_queryset(self):
        client_id = self.kwargs.get("client_id")
        return Input.objects.filter(order__client_id=client_id).order_by('-date')


class OrderInputsListView(generics.ListAPIView):
    serializer_class = InputSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = InputPagination
    filter_backends = [filters.OrderingFilter]
    ordering_fields = ['date', 'amount', 'type']
    ordering = ['-date']

    def get_queryset(self):
        order_id = self.kwargs.get("order_id")
        return Input.objects.filter(order_id=order_id).order_by('-date')