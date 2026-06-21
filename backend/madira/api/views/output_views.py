from rest_framework import viewsets, status, permissions, filters
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from django.shortcuts import get_object_or_404
from django.db.models import Sum, Count
from django_filters.rest_framework import DjangoFilterBackend
import django_filters

from ..models import Output
from ..serializers.serializers_output import OutputSerializer
from ..permissions import IsAdminOrResponsible


class OutputFilter(django_filters.FilterSet):
    type = django_filters.ChoiceFilter(field_name='type', choices=Output.Type.choices)
    amount_min = django_filters.NumberFilter(field_name='amount', lookup_expr='gte')
    amount_max = django_filters.NumberFilter(field_name='amount', lookup_expr='lte')
    date_from = django_filters.DateTimeFilter(field_name='date', lookup_expr='gte')
    date_to = django_filters.DateTimeFilter(field_name='date', lookup_expr='lte')
    
    # Order-related filters
    order = django_filters.NumberFilter(field_name='order__id')
    order_number = django_filters.CharFilter(field_name='order__order_number', lookup_expr='icontains')
    client = django_filters.NumberFilter(field_name='order__client__id')
    client_name = django_filters.CharFilter(field_name='order__client__name', lookup_expr='icontains')
    
    # Supplier filters
    supplier = django_filters.NumberFilter(field_name='supplier__id')
    supplier_name = django_filters.CharFilter(field_name='supplier__name', lookup_expr='icontains')
    
    # Product filters
    product = django_filters.NumberFilter(field_name='product__id')
    product_name = django_filters.CharFilter(field_name='product__name', lookup_expr='icontains')
    
    # Input filters
    source_input = django_filters.NumberFilter(field_name='source_input__id')
    source_input_reference = django_filters.CharFilter(field_name='source_input__reference', lookup_expr='icontains')
    
    # User filters
    created_by = django_filters.NumberFilter(field_name='created_by__id')
    created_by_username = django_filters.CharFilter(field_name='created_by__username', lookup_expr='icontains')
    
    class Meta:
        model = Output
        fields = [
            'type', 'amount_min', 'amount_max', 'date_from', 'date_to',
            'order', 'order_number', 'client', 'client_name',
            'supplier', 'supplier_name', 'product', 'product_name',
            'source_input', 'source_input_reference',
            'created_by', 'created_by_username'
        ]


# ---------------------------
# Pagination
# ---------------------------
class OutputPagination(PageNumberPagination):
    page_size = 10
    page_size_query_param = 'page_size'
    max_page_size = 100


# ---------------------------
# Output ViewSet
# ---------------------------
class OutputViewSet(viewsets.ModelViewSet):
    """
    ViewSet for managing Outputs with comprehensive search and filtering capabilities.
    
    Search fields (using ?search=query):
    - reference, description
    - order__order_number, order__client__name
    - supplier__name, product__name
    - created_by__username, source_input__reference
    
    Filter fields:
    - type: withdrawal, supplier_payment, consumable, etc.
    - amount_min/max: amount range
    - date_from/to: date range
    - order, order_number, client, client_name
    - supplier, supplier_name, product, product_name
    - source_input, source_input_reference
    - created_by, created_by_username
    
    Ordering fields:
    - created_at, amount, type, date, reference
    
    Example queries:
    - /outputs/?search=Garcia - searches all text fields for "Garcia"
    - /outputs/?type=supplier_payment&client_name=Ali - filter by type and client
    - /outputs/?amount_min=1000&ordering=-amount - outputs >= 1000 DA, ordered by amount desc
    """

    queryset = Output.objects.select_related(
        'created_by', 'source_input', 'order__client', 'supplier', 'product'
    ).prefetch_related(
        'order_outputs',
        'stock_movements',
        'stock_movements__product',
        'stock_movements__order'
    ).order_by('-created_at')

    serializer_class = OutputSerializer
    permission_classes = [permissions.IsAuthenticated]
    pagination_class = OutputPagination
    filter_backends = [DjangoFilterBackend, filters.SearchFilter, filters.OrderingFilter]
    filterset_class = OutputFilter
    search_fields = [
        'reference', 'description',
        'order__order_number', 'order__client__name',
        'supplier__name', 'product__name',
        'created_by__username', 'source_input__reference'
    ]
    ordering_fields = ['created_at', 'amount', 'type', 'date', 'reference']
    ordering = ['-created_at']  # Default ordering

    def get_permissions(self):
        """Custom permissions per action."""
        if self.action == 'destroy':
            return [permissions.IsAuthenticated(), IsAdminOrResponsible()]
        elif self.action == 'create':
            # Check if it's a withdrawal during creation
            request_data = getattr(self.request, 'data', {})
            if request_data.get('type') == 'withdrawal':
                return [permissions.IsAuthenticated(), IsAdminOrResponsible()]
        return [permissions.IsAuthenticated()]

    def perform_create(self, serializer):
        """Auto-assign created_by."""
        serializer.save(created_by=self.request.user)

    def create(self, request, *args, **kwargs):
        """Create Output with withdrawal permission check."""
        # Check if it's a withdrawal operation
        if request.data.get('type') == 'withdrawal':
            # Manually check IsAdminOrResponsible permission
            permission = IsAdminOrResponsible()
            if not permission.has_permission(request, self):
                from rest_framework.exceptions import PermissionDenied
                raise PermissionDenied("Only admin or responsible users can create withdrawals.")
        
        # Continue with normal creation
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        self.perform_create(serializer)
        headers = self.get_success_headers(serializer.data)
        return Response(serializer.data, status=status.HTTP_201_CREATED, headers=headers)

    def update(self, request, *args, **kwargs):
        """Full update (PUT) with withdrawal permission check."""
        # Check if trying to change to withdrawal type
        if request.data.get('type') == 'withdrawal':
            permission = IsAdminOrResponsible()
            if not permission.has_permission(request, self):
                from rest_framework.exceptions import PermissionDenied
                raise PermissionDenied("Only admin or responsible users can create or update withdrawals.")
        
        partial = kwargs.pop('partial', False)
        instance = self.get_object()
        serializer = self.get_serializer(instance, data=request.data, partial=partial)
        serializer.is_valid(raise_exception=True)
        self.perform_update(serializer)
        instance.refresh_from_db()
        return Response(self.get_serializer(instance).data)

    def partial_update(self, request, *args, **kwargs):
        """Partial update (PATCH) with withdrawal permission check."""
        # Check if trying to change to withdrawal type
        if request.data.get('type') == 'withdrawal':
            permission = IsAdminOrResponsible()
            if not permission.has_permission(request, self):
                from rest_framework.exceptions import PermissionDenied
                raise PermissionDenied("Only admin or responsible users can create or update withdrawals.")
        
        kwargs['partial'] = True
        return self.update(request, *args, **kwargs)

    def destroy(self, request, *args, **kwargs):
        """Delete Output with cleanup."""
        instance = self.get_object()
        serializer = self.get_serializer(instance)
        result = serializer.delete()
        return Response(result, status=status.HTTP_200_OK)

    # ---------------------------
    # Custom filters (like actions)
    # ---------------------------

    @action(detail=False, methods=['get'])
    def by_type(self, request):
        """GET /outputs/by_type/?type=withdrawal"""
        output_type = request.query_params.get('type')
        if not output_type:
            return Response({'error': 'type parameter is required'}, status=status.HTTP_400_BAD_REQUEST)
        queryset = self.filter_queryset(self.get_queryset().filter(type=output_type))
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def by_order(self, request):
        """GET /outputs/by_order/?order_id=1"""
        order_id = request.query_params.get('order_id')
        if not order_id:
            return Response({'error': 'order_id parameter is required'}, status=status.HTTP_400_BAD_REQUEST)
        queryset = self.filter_queryset(self.get_queryset().filter(order_id=order_id))
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

    @action(detail=False, methods=['get'])
    def by_input(self, request):
        """GET /outputs/by_input/?input_id=1"""
        input_id = request.query_params.get('input_id')
        if not input_id:
            return Response({'error': 'input_id parameter is required'}, status=status.HTTP_400_BAD_REQUEST)
        queryset = self.filter_queryset(self.get_queryset().filter(source_input_id=input_id))
        page = self.paginate_queryset(queryset)
        if page is not None:
            serializer = self.get_serializer(page, many=True)
            return self.get_paginated_response(serializer.data)
        serializer = self.get_serializer(queryset, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['get'])
    def related_data(self, request, pk=None):
        """GET /outputs/{id}/related_data/"""
        output = self.get_object()
        serializer = self.get_serializer(output)
        return Response({
            'output': serializer.data,
            'summary': {
                'total_order_outputs': output.order_outputs.count(),
                'total_stock_movements': output.stock_movements.count(),
                'order_outputs_total': sum(
                    oo.amount for oo in output.order_outputs.all()
                ),
            }
        })

    @action(detail=False, methods=['get'])
    def statistics(self, request):
        """GET /outputs/statistics/"""
        stats = Output.objects.aggregate(
            total_outputs=Count('id'),
            total_amount=Sum('amount'),
        )
        by_type = Output.objects.values('type').annotate(
            count=Count('id'),
            total=Sum('amount')
        )
        return Response({'overall': stats, 'by_type': list(by_type)})
