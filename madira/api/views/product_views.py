from rest_framework import generics, permissions, status
from rest_framework.response import Response
from ..models import Product
from ..serializers import ProductSerializer
from rest_framework.pagination import PageNumberPagination
from rest_framework import filters

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
    search_fields = ['name', 'refrence']
    ordering_fields = ['name', 'price', 'created_at']   

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
