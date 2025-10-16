from rest_framework import generics, permissions, filters, status
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from django.db import transaction
from ..models import Input
from ..serializers import InputSerializer

from rest_framework import generics, permissions, filters, status
from rest_framework.response import Response
from rest_framework.pagination import PageNumberPagination
from django.db import transaction
from ..models import Input
from ..serializers import InputSerializer


class InputPagination(PageNumberPagination):
    page_size = 10
    page_size_query_param = 'page_size'
    max_page_size = 100


from ..permissions import IsAdminOrResponsible
class InputListCreateView(generics.ListCreateAPIView):
    """
    List all inputs or create a new one.
    Only Admins or Responsibles can add a shop deposit (create).
    """
    queryset = Input.objects.select_related('created_by', 'order__client').order_by('-date')
    serializer_class = InputSerializer
    permission_classes = [permissions.IsAuthenticated, IsAdminOrResponsible]
    pagination_class = InputPagination
    filter_backends = [filters.SearchFilter, filters.OrderingFilter]
    search_fields = ['reference', 'description', 'order__order_number', 'order__client__name']
    ordering_fields = ['date', 'amount', 'type']

    def perform_create(self, serializer):
        """Set the current user automatically when creating an Input"""
        with transaction.atomic():
            serializer.save(created_by=self.request.user)


from rest_framework import generics, permissions, status
from rest_framework.response import Response
from django.db import transaction
from django.db import models
from ..models import Input, Order
from ..serializers import InputSerializer


class InputRetrieveUpdateDeleteView(generics.RetrieveUpdateDestroyAPIView):
    """
    Retrieve, update, or delete an input.
    Automatically updates the related order's paid amount after any change.
    """
    queryset = Input.objects.select_related('created_by', 'order__client').all()
    serializer_class = InputSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_update(self, serializer):
        """
        When updating an Input:
        - Save new data
        - Recalculate the related order's paid amount
        """
        with transaction.atomic():
            instance = serializer.save()
            self._update_order_paid_amount(instance.order)

    def delete(self, request, *args, **kwargs):
        """
        When deleting an Input:
        - Delete it
        - Recalculate the related order's paid amount
        """
        instance = self.get_object()
        order = instance.order
        ref = instance.reference

        with transaction.atomic():
            instance.delete()
            if order:
                self._update_order_paid_amount(order)

        return Response(
            {"detail": f"Input {ref} deleted and order updated."},
            status=status.HTTP_200_OK
        )

    # 🔁 Helper function to recalculate the order's paid amount
    def _update_order_paid_amount(self, order):
        if not order:
            return

        total_paid = (
            Input.objects.filter(order=order, type=Input.Type.CLIENT_PAYMENT)
            .aggregate(total=models.Sum('amount'))
            .get('total') or 0
        )

        order.paid_amount = total_paid
        order.save(update_fields=['paid_amount'])
