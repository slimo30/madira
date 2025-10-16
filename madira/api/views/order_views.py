from rest_framework import generics, permissions, filters, status
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from django.db import transaction
from ..models import Order
from ..serializers import OrderSerializer
from ..permissions import IsAdminOrResponsible


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
    List all active (non-cancelled) orders or create a new one.
    Automatically shows client name in response (via serializer).
    """
    serializer_class = OrderSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = OrderPagination
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['order_number', 'client__name', 'description']
    ordering_fields = ['order_date', 'total_amount', 'paid_amount', 'status']

    def get_queryset(self):
        """Exclude cancelled orders from the list."""
        return Order.objects.select_related('client').exclude(status='cancelled').order_by('-order_date')

    def perform_create(self, serializer):
        with transaction.atomic():
            serializer.save()



# ---------------------------
# Retrieve + Update + Cancel (No Delete)
# ---------------------------
class OrderRetrieveUpdateDeleteView(generics.RetrieveUpdateAPIView):
    """
    Retrieve or update an order.
    DELETE = Cancel the order (set status to 'cancelled')
    """
    queryset = Order.objects.select_related('client').all()
    serializer_class = OrderSerializer
    permission_classes = [permissions.IsAuthenticated]

    def delete(self, request, *args, **kwargs):
        order = self.get_object()
        print(f"[DELETE] Attempting to cancel order: {order.order_number} (Current status: {order.status})")

        # Only cancel if it's not already cancelled
        if order.status != 'cancelled':
            Order.objects.filter(pk=order.pk).update(status='cancelled')
            order.refresh_from_db()
            print(f"[DELETE] Order {order.order_number} status updated to: {order.status}")
            message = f"Order {order.order_number} has been cancelled."
        else:
            print(f"[DELETE] Order {order.order_number} is already cancelled.")
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
