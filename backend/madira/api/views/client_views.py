from rest_framework import generics, permissions, filters, status
from rest_framework.response import Response
from django_filters.rest_framework import DjangoFilterBackend
import django_filters
from ..models import Client
from ..serializers.serializers import ClientSerializer
from rest_framework.pagination import PageNumberPagination


class ClientFilter(django_filters.FilterSet):
    is_active = django_filters.BooleanFilter(field_name='is_active')
    client_type = django_filters.ChoiceFilter(field_name='client_type', choices=Client.Type.choices)
    name = django_filters.CharFilter(field_name='name', lookup_expr='icontains')
    phone = django_filters.CharFilter(field_name='phone', lookup_expr='icontains')
    credit_balance_min = django_filters.NumberFilter(field_name='credit_balance', lookup_expr='gte')
    credit_balance_max = django_filters.NumberFilter(field_name='credit_balance', lookup_expr='lte')
    
    class Meta:
        model = Client
        fields = ['is_active', 'client_type', 'name', 'phone', 'credit_balance_min', 'credit_balance_max']


class ClientPagination(PageNumberPagination):
    page_size = 10
    page_size_query_param = 'page_size'
    max_page_size = 100


# ---------------------------
# List + Create Clients
# ---------------------------
class ClientListCreateView(generics.ListCreateAPIView):
    """
    List all clients with comprehensive filtering and sorting.
    
    Filtering options:
    - is_active: true/false
    - client_type: new, old
    - name: client name (partial match)
    - phone: phone number (partial match)
    - credit_balance_min/max: balance range
    
    Search fields: name, phone, address, notes
    Ordering options: name, created_at, credit_balance
    """
    serializer_class = ClientSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = ClientPagination
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_class = ClientFilter
    search_fields = ['name', 'phone', 'address', 'client_type', 'notes']
    ordering_fields = ['name', 'created_at', 'credit_balance']
    ordering = ['-created_at']

    def get_queryset(self):
        """
        Override to handle is_active filtering properly:
        - By default, show only active clients
        - When is_active=false is explicitly passed, show only inactive clients
        - When is_active=true is explicitly passed, show only active clients
        """
        queryset = Client.objects.all()
        
        # Check if is_active parameter is explicitly provided
        is_active_param = self.request.query_params.get('is_active', None)
        
        if is_active_param is not None:
            # Convert string to boolean
            if is_active_param.lower() == 'true':
                queryset = queryset.filter(is_active=True)
            elif is_active_param.lower() == 'false':
                queryset = queryset.filter(is_active=False)
        else:
            # Default behavior: show only active clients
            queryset = queryset.filter(is_active=True)
            
        return queryset.order_by('name')


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



