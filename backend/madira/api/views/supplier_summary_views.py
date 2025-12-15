from rest_framework import permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from django.shortcuts import get_object_or_404
from django.db.models import Sum
from django.utils import timezone
from ..models import Supplier, Output
from ..serializers.serializers import SupplierSerializer

class SupplierSummaryView(APIView):
    """
    Returns a complete summary for a specific supplier:
    - Supplier details
    - Total amount paid to the supplier
    - List of payments grouped by Order with partial totals
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, supplier_id):
        supplier = get_object_or_404(Supplier, pk=supplier_id)
        
        # Get all payments (Outputs) made to this supplier
        payments_query = Output.objects.filter(
            supplier=supplier
        ).select_related('order', 'created_by').order_by('-date')

        # Calculate global total paid
        total_paid = payments_query.aggregate(total=Sum('amount'))['total'] or 0

        # Group payments by Order
        orders_summary = {}
        
        for payment in payments_query:
            # Use order ID as key, or 'misc' if no order (though model enforces order for supplier_payment)
            order_id = payment.order.id if payment.order else 'misc'
            
            if order_id not in orders_summary:
                orders_summary[order_id] = {
                    'order_id': payment.order.id if payment.order else None,
                    'order_number': payment.order.order_number if payment.order else 'N/A',
                    'client_name': payment.order.client.name if payment.order and payment.order.client else 'N/A',
                    'order_date': payment.order.order_date if payment.order else None,
                    'total_paid': 0,
                    'payments': []
                }
            
            orders_summary[order_id]['total_paid'] += payment.amount
            
            orders_summary[order_id]['payments'].append({
                'id': payment.id,
                'reference': payment.reference,
                'amount': payment.amount,
                'date': payment.date,
                'description': payment.description,
                'type': payment.get_type_display(),
                'created_by': payment.created_by.username,
            })

        # Convert to list
        # Since we iterated through payments ordered by date desc, the orders are roughly sorted by recent activity
        orders_list = list(orders_summary.values())

        # Serialize Supplier details
        supplier_data = SupplierSerializer(supplier).data

        response_data = {
            'supplier': supplier_data,
            'stats': {
                'total_paid': total_paid,
                'transaction_count': payments_query.count(),
            },
            'orders': orders_list
        }

        return Response(response_data, status=status.HTTP_200_OK)
