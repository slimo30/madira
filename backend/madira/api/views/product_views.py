from rest_framework import generics, permissions, status
from rest_framework.response import Response
from django.db import transaction
from ..models import Product, StockMovement
from ..serializers.serializers import ProductSerializer
from rest_framework.pagination import PageNumberPagination
from rest_framework import filters
from decimal import Decimal

class OrderPagination(PageNumberPagination):
    page_size = 10
    page_size_query_param = 'page_size'
    max_page_size = 100

# ---------------------------
# List and Create
# ---------------------------
class ProductListCreateView(generics.ListCreateAPIView):
    queryset = Product.objects.filter(is_active=True).order_by('name')
    serializer_class = ProductSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = OrderPagination
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name', 'reference']
    ordering_fields = ['name', 'created_at']

    def perform_create(self, serializer):
        """
        Create product and automatically create StockMovement (IN) 
        if initial quantity > 0
        """
        with transaction.atomic():
            product = serializer.save()
            
            # If product has initial quantity > 0, create a stock movement
            if product.current_quantity > Decimal('0.00'):
                StockMovement.objects.create(
                    product=product,
                    movement_type=StockMovement.MovementType.IN,
                    quantity=product.current_quantity,
                    price=Decimal('0.00'),  # Initial stock, no price needed
                    created_by=self.request.user,
                    order=None  # No order for initial stock
                )

# ---------------------------
# Retrieve, Update, Deactivate (instead of Delete)
# ---------------------------
class ProductRetrieveUpdateDeactivateView(generics.RetrieveUpdateAPIView):
    queryset = Product.objects.all()
    serializer_class = ProductSerializer
    permission_classes = [permissions.IsAuthenticated]

    def delete(self, request, *args, **kwargs):
        """
        Soft delete → deactivate instead of delete
        """
        product = self.get_object()
        product.is_active = False
        product.save()
        return Response({'detail': f'{product.name} has been deactivated.'},
                        status=status.HTTP_200_OK)
