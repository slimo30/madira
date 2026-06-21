from rest_framework import generics, permissions, filters, status
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from django.db import transaction
from django_filters.rest_framework import DjangoFilterBackend
import django_filters
from ..models import Order
from ..serializers.serializers import OrderSerializer
from ..permissions import IsAdminOrResponsible
from django.db.models import Sum, Q, F


class OrderFilter(django_filters.FilterSet):
    # Payment status filter based on paid amount vs total amount
    payment_status = django_filters.ChoiceFilter(
        method='filter_payment_status',
        choices=[
            ('unpaid', 'Unpaid'),
            ('partially_paid', 'Partially Paid'),
            ('fully_paid', 'Fully Paid'),
        ]
    )
    
    # Order status filter
    status = django_filters.ChoiceFilter(field_name='status', choices=Order.Status.choices)
    
    # Client filter
    client = django_filters.NumberFilter(field_name='client__id')
    client_name = django_filters.CharFilter(field_name='client__name', lookup_expr='icontains')
    
    # Amount filters
    total_amount_min = django_filters.NumberFilter(field_name='total_amount', lookup_expr='gte')
    total_amount_max = django_filters.NumberFilter(field_name='total_amount', lookup_expr='lte')
    
    # Date filters
    order_date_from = django_filters.DateTimeFilter(field_name='order_date', lookup_expr='gte')
    order_date_to = django_filters.DateTimeFilter(field_name='order_date', lookup_expr='lte')
    delivery_date_from = django_filters.DateFilter(field_name='delivery_date', lookup_expr='gte')
    delivery_date_to = django_filters.DateFilter(field_name='delivery_date', lookup_expr='lte')
    
    def filter_payment_status(self, queryset, name, value):
        """Custom filter for payment status based on paid_amount vs total_amount"""
        if value == 'unpaid':
            # Filter orders where paid_amount = 0
            return queryset.filter(payments__isnull=True).distinct()
        elif value == 'partially_paid':
            # Filter orders where 0 < paid_amount < total_amount
            return queryset.annotate(
                total_paid=Sum('payments__amount', filter=Q(payments__type='client_payment'))
            ).filter(
                total_paid__gt=0,
                total_paid__lt=F('total_amount')
            ).distinct()
        elif value == 'fully_paid':
            # Filter orders where paid_amount >= total_amount
            return queryset.annotate(
                total_paid=Sum('payments__amount', filter=Q(payments__type='client_payment'))
            ).filter(
                total_paid__gte=F('total_amount')
            ).distinct()
        return queryset
    
    class Meta:
        model = Order
        fields = [
            'payment_status', 'status', 'client', 'client_name',
            'total_amount_min', 'total_amount_max',
            'order_date_from', 'order_date_to',
            'delivery_date_from', 'delivery_date_to'
        ]


# ---------------------------
# Pagination
# ---------------------------
class OrderPagination(PageNumberPagination):
    page_size = 10
    page_size_query_param = 'page_size'
    max_page_size = 100


# ---------------------------
# List + Create Orders
# ---------------------------
class OrderListCreateView(generics.ListCreateAPIView):
    """
    List all orders with comprehensive filtering and sorting.
    
    Filtering options:
    - payment_status: unpaid, partially_paid, fully_paid
    - status: pending, in_progress, completed, cancelled
    - client: client ID number
    - client_name: client name (partial match)
    - total_amount_min/max: amount range
    - order_date_from/to: order date range
    - delivery_date_from/to: delivery date range
    
    Ordering options:
    - order_date, -order_date
    - total_amount, -total_amount
    - delivery_date, -delivery_date
    - created_at, -created_at
    - status, -status
    """
    serializer_class = OrderSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = OrderPagination
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_class = OrderFilter
    search_fields = ['order_number', 'client__name', 'description']
    ordering_fields = ['order_date', 'total_amount', 'delivery_date', 'created_at', 'status']
    ordering = ['-created_at']  # Default ordering

    def get_queryset(self):
        """Get all orders with related data."""
        return Order.objects.select_related('client').prefetch_related('payments').order_by('-created_at')

    def perform_create(self, serializer):
        with transaction.atomic():
            serializer.save()


# ---------------------------
# Retrieve + Update + Cancel (No Delete)
# ---------------------------
# class OrderRetrieveUpdateDeleteView(generics.RetrieveUpdateAPIView):
#     """
#     Retrieve or update an order.
#     DELETE = Cancel the order (set status to 'cancelled')
#     Status is COMPLETED only when fully paid, otherwise IN_PROGRESS.
#     """
#     queryset = Order.objects.select_related('client').all()
#     serializer_class = OrderSerializer
#     permission_classes = [permissions.IsAuthenticated]

#     def perform_update(self, serializer):
#         """
#         Update order and automatically adjust status based on payment:
#         - If fully paid -> COMPLETED
#         - If not fully paid -> IN_PROGRESS (even if it was COMPLETED before)
#         - Respects CANCELLED and PENDING status
#         """
#         with transaction.atomic():
#             instance = serializer.save()
            
#             # Only auto-adjust status if order is not CANCELLED or PENDING
#             if instance.status not in [Order.Status.CANCELLED, Order.Status.PENDING]:
#                 if instance.is_fully_paid:
#                     # Fully paid -> mark as COMPLETED
#                     if instance.status != Order.Status.COMPLETED:
#                         instance.status = Order.Status.COMPLETED
#                         instance.save(update_fields=['status'])
#                 else:
#                     # Not fully paid -> mark as IN_PROGRESS
#                     if instance.status == Order.Status.COMPLETED:
#                         instance.status = Order.Status.IN_PROGRESS
#                         instance.save(update_fields=['status'])

#     def delete(self, request, *args, **kwargs):
#         order = self.get_object()
#         print(f"[DELETE] Attempting to cancel order: {order.order_number} (Current status: {order.status})")

#         # Only cancel if it's not already cancelled
#         if order.status != 'cancelled':
#             Order.objects.filter(pk=order.pk).update(status='cancelled')
#             order.refresh_from_db()
#             print(f"[DELETE] Order {order.order_number} status updated to: {order.status}")
#             message = f"Order {order.order_number} has been cancelled."
#         else:
#             print(f"[DELETE] Order {order.order_number} is already cancelled.")
#             message = f"Order {order.order_number} was already cancelled."

#         return Response({"detail": message}, status=status.HTTP_200_OK)

class OrderRetrieveUpdateDeleteView(generics.RetrieveUpdateAPIView):
    """
    Retrieve or update an order.
    - PUT/PATCH: fully manual status updates (including 'cancelled')
    - DELETE: also cancels the order (sets status='cancelled')
    """
    queryset = Order.objects.select_related('client').all()
    serializer_class = OrderSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_update(self, serializer):
        """
        Save the order exactly as sent by the user, including status.
        No automatic rules. No full-payment checks.
        """
        with transaction.atomic():
            instance = serializer.save()
            # No auto status logic
            return instance

    def delete(self, request, *args, **kwargs):
        """
        DELETE = Another way to cancel the order.
        """
        order = self.get_object()

        if order.status != Order.Status.CANCELLED:
            order.status = Order.Status.CANCELLED
            order.save(update_fields=['status'])
            message = f"Order {order.order_number} has been cancelled."
        else:
            message = f"Order {order.order_number} was already cancelled."

        return Response({"detail": message}, status=status.HTTP_200_OK)

class ClientOrdersListView(generics.ListAPIView):
    serializer_class = OrderSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = OrderPagination
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['order_number', 'description']
    ordering_fields = ['order_date', 'total_amount', 'paid_amount', 'status']

    def get_queryset(self):
        client_id = self.kwargs.get("client_id")
        return Order.objects.filter(client_id=client_id).order_by('-order_date')
