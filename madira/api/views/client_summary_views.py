from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db.models import Sum, Count, Q, F, DecimalField, Avg
from django.db.models.functions import Coalesce
from decimal import Decimal
from datetime import datetime, timedelta
from ..models import Client, Order, Input, OrderOutput




class ClientCompleteDetailsView(APIView):
    """
    🎯 SINGLE API FOR FLUTTER DESKTOP - COMPLETE CLIENT DETAILS
    
    Returns EVERYTHING for ONE client in a single response:
    - Client basic info
    - All orders with their complete details
    - Each order includes:
        - All inputs (payments) for that order
        - All outputs (expenses) for that order
        - Paid/Unpaid status
        - Benefit calculation per order
    - Overall financial summary
    - Total benefits across all orders
    
    Perfect for displaying complete client information in one Flutter screen!
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request, client_id):
        try:
            client = Client.objects.get(id=client_id, is_active=True)
        except Client.DoesNotExist:
            return Response(
                {"error": "Client not found or inactive"},
                status=status.HTTP_404_NOT_FOUND
            )

        # ============================================
        # 1. CLIENT BASIC INFORMATION
        # ============================================
        client_info = {
            'id': client.id,
            'name': client.name,
            'phone': client.phone,
            'address': client.address,
            'client_type': client.client_type,
            'credit_balance': client.credit_balance,
            'notes': client.notes,
            'is_active': client.is_active,
            'created_at': client.created_at,
        }

        # ============================================
        # 2. ALL ORDERS WITH COMPLETE NESTED DATA
        # ============================================
        orders = Order.objects.filter(client=client).order_by('-order_date')
        
        orders_complete_data = []
        total_all_orders = Decimal('0.00')
        total_all_paid = Decimal('0.00')
        total_all_expenses = Decimal('0.00')
        
        for order in orders:
            # --- ORDER BASIC INFO ---
            order_data = {
                'id': order.id,
                'order_number': order.order_number,
                'order_date': order.order_date,
                'delivery_date': order.delivery_date,
                'status': order.status,
                'description': order.description,
                'total_amount': order.total_amount,
                'paid_amount': order.paid_amount,
                'remaining_amount': order.total_amount - order.paid_amount,
                'is_fully_paid': order.paid_amount >= order.total_amount,
            }
            
            # --- ALL INPUTS (PAYMENTS) FOR THIS ORDER ---
            order_inputs = Input.objects.filter(
                order=order,
                type=Input.Type.CLIENT_PAYMENT
            ).select_related('created_by').order_by('-date')
            
            inputs_list = []
            for inp in order_inputs:
                inputs_list.append({
                    'id': inp.id,
                    'reference': inp.reference,
                    'amount': inp.amount,
                    'date': inp.date,
                    'description': inp.description,
                    'created_by': inp.created_by.username if inp.created_by else None,
                    'created_at': inp.created_at,
                })
            
            order_data['inputs'] = inputs_list
            order_data['total_inputs'] = sum(inp['amount'] for inp in inputs_list)
            
            # --- ALL OUTPUTS (EXPENSES) FOR THIS ORDER ---
            order_outputs = OrderOutput.objects.filter(
                order=order
            ).order_by('-created_at')
            
            outputs_list = []
            for out in order_outputs:
                outputs_list.append({
                    'id': out.id,
                    'type': out.type,
                    'amount': out.amount,
                    'description': out.description,
                    'created_at': out.created_at,
                })
            
            order_data['outputs'] = outputs_list
            order_data['total_expenses'] = sum(out['amount'] for out in outputs_list)
            
            # --- BENEFIT CALCULATION FOR THIS ORDER ---
            # Benefit = Order Amount - Total Expenses (Outputs)
            order_data['benefit'] = order.total_amount - order_data['total_expenses']
            
            # --- PAYMENT STATUS DETAILS ---
            order_data['payment_status'] = {
                'is_paid': order.paid_amount >= order.total_amount,
                'is_unpaid': order.paid_amount == 0,
                'is_partially_paid': 0 < order.paid_amount < order.total_amount,
                'paid_percentage': round((order.paid_amount / order.total_amount * 100), 2) if order.total_amount > 0 else 0,
            }
            
            # Add to totals
            total_all_orders += order.total_amount
            total_all_paid += order.paid_amount
            total_all_expenses += order_data['total_expenses']
            
            orders_complete_data.append(order_data)

        # ============================================
        # 3. OVERALL FINANCIAL SUMMARY (WITH CREDIT BALANCE)
        # ============================================
        total_unpaid = total_all_orders - total_all_paid
        total_benefit = total_all_orders - total_all_expenses
        
        # 💰 FINAL BALANCE CALCULATION:
        # If credit_balance is POSITIVE: Client paid advance (we owe them or they have credit)
        # If credit_balance is NEGATIVE: Client owes us initial debt
        # Final Balance = total_unpaid - credit_balance
        # Example 1: Client owes 5000, has +1000 credit → Final: 5000 - 1000 = 4000 (they owe less)
        # Example 2: Client owes 5000, has -1000 debt → Final: 5000 - (-1000) = 6000 (they owe more)
        final_balance = total_unpaid - client.credit_balance
        
        financial_summary = {
            'total_orders_count': len(orders_complete_data),
            'total_orders_amount': total_all_orders,
            'total_paid': total_all_paid,
            'total_unpaid': total_unpaid,
            'total_expenses': total_all_expenses,
            'total_benefit': total_benefit,
            'initial_credit_balance': client.credit_balance,  # Initial credit/debt when client created
            'final_balance': final_balance,  # Final amount client owes (considering initial credit)
            'average_order_value': round(total_all_orders / len(orders_complete_data), 2) if len(orders_complete_data) > 0 else Decimal('0.00'),
            'average_benefit_per_order': round(total_benefit / len(orders_complete_data), 2) if len(orders_complete_data) > 0 else Decimal('0.00'),
        }

        # ============================================
        # 4. ORDERS BY STATUS SUMMARY
        # ============================================
        orders_by_status = {
            'completed': orders.filter(status=Order.Status.COMPLETED).count(),
            'pending': orders.filter(status=Order.Status.PENDING).count(),
            'in_progress': orders.filter(status=Order.Status.IN_PROGRESS).count(),
            'cancelled': orders.filter(status=Order.Status.CANCELLED).count(),
        }

        # ============================================
        # 5. PAYMENT STATUS SUMMARY
        # ============================================
        fully_paid_orders = sum(1 for o in orders_complete_data if o['is_fully_paid'])
        unpaid_orders = sum(1 for o in orders_complete_data if o['paid_amount'] == 0)
        partially_paid_orders = sum(1 for o in orders_complete_data if 0 < o['paid_amount'] < o['total_amount'])
        
        payment_summary = {
            'fully_paid_orders': fully_paid_orders,
            'unpaid_orders': unpaid_orders,
            'partially_paid_orders': partially_paid_orders,
            'payment_completion_rate': round((fully_paid_orders / len(orders_complete_data) * 100), 2) if len(orders_complete_data) > 0 else 0,
        }

        # ============================================
        # FINAL RESPONSE - EVERYTHING IN ONE PLACE
        # ============================================
        response_data = {
            'client': client_info,
            'financial_summary': financial_summary,
            'orders_by_status': orders_by_status,
            'payment_summary': payment_summary,
            'orders': orders_complete_data,  # Complete nested data for each order
        }

        return Response(response_data, status=status.HTTP_200_OK)


