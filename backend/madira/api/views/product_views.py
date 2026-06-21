from rest_framework import generics, permissions, status
from rest_framework.response import Response
from django.db import transaction
from ..models import Product, StockMovement
from ..serializers.serializers import ProductSerializer
from rest_framework.pagination import PageNumberPagination
from rest_framework import filters
from django_filters.rest_framework import DjangoFilterBackend
import django_filters
from decimal import Decimal

class ProductFilter(django_filters.FilterSet):
    is_active = django_filters.BooleanFilter(field_name='is_active')
    unit = django_filters.ChoiceFilter(field_name='unit', choices=Product.Unit.choices)
    name = django_filters.CharFilter(field_name='name', lookup_expr='icontains')
    
    class Meta:
        model = Product
        fields = ['is_active', 'unit', 'name']

class OrderPagination(PageNumberPagination):
    page_size = 10
    page_size_query_param = 'page_size'
    max_page_size = 100

# ---------------------------
# List and Create
# ---------------------------
class ProductListCreateView(generics.ListCreateAPIView):
    serializer_class = ProductSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = OrderPagination
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_class = ProductFilter
    search_fields = ['name', 'reference']
    ordering_fields = ['name', 'created_at', 'current_quantity', 'unit']
    ordering = ['name']  # Default ordering

    def get_queryset(self):
        """
        Override to handle is_active filtering properly:
        - By default, show only active products
        - When is_active=false is explicitly passed, show only inactive products
        - When is_active=true is explicitly passed, show only active products
        """
        queryset = Product.objects.all()
        
        # Check if is_active parameter is explicitly provided
        is_active_param = self.request.query_params.get('is_active', None)
        
        if is_active_param is not None:
            # Convert string to boolean
            if is_active_param.lower() == 'true':
                queryset = queryset.filter(is_active=True)
            elif is_active_param.lower() == 'false':
                queryset = queryset.filter(is_active=False)
        else:
            # Default behavior: show only active products
            queryset = queryset.filter(is_active=True)
            
        return queryset.order_by('name')

    def perform_create(self, serializer):
        """
        Create product and automatically create StockMovement (IN) 
        if initial quantity > 0 with proper pricing
        """
        with transaction.atomic():
            # Extract initial_price before saving
            initial_price = serializer.validated_data.pop('initial_price', None)
            product = serializer.save()
            
            # If product has initial quantity > 0, create a stock movement with price
            if product.current_quantity > Decimal('0.00'):
                StockMovement.objects.create(
                    product=product,
                    movement_type=StockMovement.MovementType.IN,
                    quantity=product.current_quantity,
                    price=initial_price or Decimal('0.00'),  # Use provided price or default to 0
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
