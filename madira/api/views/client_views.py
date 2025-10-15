from rest_framework import generics, permissions, filters, status
from rest_framework.response import Response
from ..models import Client
from ..serializers import ClientSerializer
from rest_framework.pagination import PageNumberPagination


class ClientPagination(PageNumberPagination):
    page_size = 10
    page_size_query_param = 'page_size'
    max_page_size = 100


# ---------------------------
# List + Create Clients
# ---------------------------
class ClientListCreateView(generics.ListCreateAPIView):
    queryset = Client.objects.filter(is_active=True).order_by('name')
    serializer_class = ClientSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = ClientPagination
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['name', 'phone', 'address', 'client_type', 'notes']
    ordering_fields = ['name', 'credit_balance', 'created_at']


# ---------------------------
# Retrieve + Update + Deactivate Client
# ---------------------------
class ClientRetrieveUpdateDeleteView(generics.RetrieveUpdateAPIView):
    queryset = Client.objects.all()
    serializer_class = ClientSerializer
    permission_classes = [permissions.IsAuthenticated]

    def delete(self, request, *args, **kwargs):
        """Instead of deleting, deactivate the client."""
        client = self.get_object()
        client.is_active = False
        client.save()
        return Response({"detail": "Client has been deactivated."}, status=status.HTTP_200_OK)
