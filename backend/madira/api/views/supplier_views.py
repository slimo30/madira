from rest_framework import generics, permissions, filters, status
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from ..models import Supplier
from ..serializers.serializers import SupplierSerializer


# ---------------------------
# Pagination
# ---------------------------
class SupplierPagination(PageNumberPagination):
    page_size = 10
    page_size_query_param = 'page_size'
    max_page_size = 100


# ---------------------------
# List + Create Suppliers
# ---------------------------
class SupplierListCreateView(generics.ListCreateAPIView):
    queryset = Supplier.objects.filter(is_active=True).order_by('-created_at')
    serializer_class = SupplierSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = SupplierPagination
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name', 'phone', 'address', 'notes']
    ordering_fields = ['name', 'created_at']


# ---------------------------
# Retrieve + Update + Deactivate Supplier
# ---------------------------
class SupplierRetrieveUpdateDeleteView(generics.RetrieveUpdateDestroyAPIView):
    queryset = Supplier.objects.all()
    serializer_class = SupplierSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_destroy(self, instance):
        # Soft delete (deactivate)
        instance.is_active = False
        instance.save()
