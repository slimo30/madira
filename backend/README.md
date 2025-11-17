# madira

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Lab: Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Cookbook: Useful Flutter samples](https://docs.flutter.dev/cookbook)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.
# from rest_framework import permissions, status
# from rest_framework.response import Response
# from rest_framework.views import APIView
# from django.db.models import Sum, Count, Avg, Max, Min, Q, F, DecimalField, Prefetch, OuterRef, Subquery
# from django.db.models.functions import Coalesce, TruncMonth, TruncWeek, TruncDate, TruncYear, TruncDay
# from decimal import Decimal
# from datetime import datetime, timedelta
# from django.utils import timezone
# from ..models import (
#     Client, Order, Input, Output, OrderOutput, 
#     Product, StockMovement, Supplier, User
# )


# class ComprehensiveDashboardView(APIView):
#     """
#     🎯 OPTIMIZED COMPREHENSIVE DASHBOARD ANALYTICS - SINGLE API
    
#     Provides complete business intelligence with optimized queries:
#     - Minimal database hits using aggregations
#     - Batch processing where possible
#     - Efficient filtering and annotations
#     - Daily, Monthly, and Yearly breakdowns
#     """
#     permission_classes = [permissions.IsAuthenticated]

#     def get(self, request):
#         # Get date range from query params for recent period (default: last 30 days)
#         days = int(request.query_params.get('days', 30))
#         recent_start = timezone.now() - timedelta(days=days)
#         today = timezone.now().date()
#         week_start = timezone.now() - timedelta(days=7)
#         month_start = timezone.now().replace(day=1, hour=0, minute=0, second=0, microsecond=0)
#         year_start = timezone.now().replace(month=1, day=1, hour=0, minute=0, second=0, microsecond=0)
        
#         # ============================================
#         # 📊 1. FINANCIAL OVERVIEW - ALL TIME (PRIMARY)
#         # ============================================
        
#         # ALL TIME AGGREGATES
#         orders_aggregate = Order.objects.aggregate(
#             # All-time totals
#             total_revenue=Coalesce(Sum('total_amount'), Decimal('0.00')),
#             total_orders=Count('id'),
#             avg_order=Coalesce(Avg('total_amount'), Decimal('0.00')),
#             completed=Count('id', filter=Q(status=Order.Status.COMPLETED)),
#             in_progress=Count('id', filter=Q(status=Order.Status.IN_PROGRESS)),
#             pending=Count('id', filter=Q(status=Order.Status.PENDING)),
#             cancelled=Count('id', filter=Q(status=Order.Status.CANCELLED)),
#             # Recent period for comparison
#             today_orders=Count('id', filter=Q(order_date__date=today)),
#             today_revenue=Coalesce(Sum('total_amount', filter=Q(order_date__date=today)), Decimal('0.00')),
#             month_orders=Count('id', filter=Q(order_date__gte=month_start)),
#             month_revenue=Coalesce(Sum('total_amount', filter=Q(order_date__gte=month_start)), Decimal('0.00')),
#             year_orders=Count('id', filter=Q(order_date__gte=year_start)),
#             year_revenue=Coalesce(Sum('total_amount', filter=Q(order_date__gte=year_start)), Decimal('0.00')),
#             recent_orders=Count('id', filter=Q(order_date__gte=recent_start)),
#             recent_revenue=Coalesce(Sum('total_amount', filter=Q(order_date__gte=recent_start)), Decimal('0.00')),
#         )
        
#         inputs_aggregate = Input.objects.aggregate(
#             # All-time totals
#             total_inputs=Coalesce(Sum('amount'), Decimal('0.00')),
#             client_payments=Coalesce(Sum('amount', filter=Q(type=Input.Type.CLIENT_PAYMENT)), Decimal('0.00')),
#             shop_deposits=Coalesce(Sum('amount', filter=Q(type=Input.Type.SHOP_DEPOSIT)), Decimal('0.00')),
#             total_transactions=Count('id'),
#             # Recent period for comparison
#             today_inputs=Coalesce(Sum('amount', filter=Q(date__date=today)), Decimal('0.00')),
#             today_transactions=Count('id', filter=Q(date__date=today)),
#             week_inputs=Coalesce(Sum('amount', filter=Q(date__gte=week_start)), Decimal('0.00')),
#             week_transactions=Count('id', filter=Q(date__gte=week_start)),
#             month_inputs=Coalesce(Sum('amount', filter=Q(date__gte=month_start)), Decimal('0.00')),
#             month_transactions=Count('id', filter=Q(date__gte=month_start)),
#             year_inputs=Coalesce(Sum('amount', filter=Q(date__gte=year_start)), Decimal('0.00')),
#             year_transactions=Count('id', filter=Q(date__gte=year_start)),
#             recent_inputs=Coalesce(Sum('amount', filter=Q(date__gte=recent_start)), Decimal('0.00')),
#             recent_collected=Coalesce(Sum('amount', filter=Q(type=Input.Type.CLIENT_PAYMENT, date__gte=recent_start)), Decimal('0.00')),
#         )
        
#         outputs_aggregate = Output.objects.aggregate(
#             # All-time totals
#             total_outputs=Coalesce(Sum('amount'), Decimal('0.00')),
#             withdrawals=Coalesce(Sum('amount', filter=Q(type=Output.Type.WITHDRAWAL)), Decimal('0.00')),
#             supplier_payments=Coalesce(Sum('amount', filter=Q(type=Output.Type.SUPPLIER_PAYMENT)), Decimal('0.00')),
#             consumables=Coalesce(Sum('amount', filter=Q(type=Output.Type.CONSUMABLE)), Decimal('0.00')),
#             stock_purchases=Coalesce(Sum('amount', filter=Q(type=Output.Type.GLOBAL_STOCK_PURCHASE)), Decimal('0.00')),
#             total_transactions=Count('id'),
#             # Recent period for comparison
#             today_outputs=Coalesce(Sum('amount', filter=Q(date__date=today)), Decimal('0.00')),
#             today_transactions=Count('id', filter=Q(date__date=today)),
#             week_outputs=Coalesce(Sum('amount', filter=Q(date__gte=week_start)), Decimal('0.00')),
#             week_transactions=Count('id', filter=Q(date__gte=week_start)),
#             month_outputs=Coalesce(Sum('amount', filter=Q(date__gte=month_start)), Decimal('0.00')),
#             month_transactions=Count('id', filter=Q(date__gte=month_start)),
#             year_outputs=Coalesce(Sum('amount', filter=Q(date__gte=year_start)), Decimal('0.00')),
#             year_transactions=Count('id', filter=Q(date__gte=year_start)),
#             recent_outputs=Coalesce(Sum('amount', filter=Q(date__gte=recent_start)), Decimal('0.00')),
#         )
        
#         order_outputs_aggregate = OrderOutput.objects.aggregate(
#             # All-time totals
#             total_expenses=Coalesce(Sum('amount'), Decimal('0.00')),
#             # Recent period for comparison
#             today_expenses=Coalesce(Sum('amount', filter=Q(created_at__date=today)), Decimal('0.00')),
#             month_expenses=Coalesce(Sum('amount', filter=Q(created_at__gte=month_start)), Decimal('0.00')),
#             year_expenses=Coalesce(Sum('amount', filter=Q(created_at__gte=year_start)), Decimal('0.00')),
#             recent_expenses=Coalesce(Sum('amount', filter=Q(created_at__gte=recent_start)), Decimal('0.00')),
#         )
        
#         # ============================================
#         # CALCULATE ALL-TIME FINANCIALS (PRIMARY)
#         # ============================================
        
#         # All-time values
#         total_revenue = orders_aggregate['total_revenue']
#         total_collected = inputs_aggregate['client_payments']
#         total_outstanding = total_revenue - total_collected
        
#         # ✅ Total benefits = Total Inputs - Total Outputs
#         total_inputs = inputs_aggregate['total_inputs']
#         total_outputs_spent = outputs_aggregate['total_outputs']
#         total_benefits = total_inputs - total_outputs_spent
        
#         # Order-specific expenses
#         total_order_expenses = order_outputs_aggregate['total_expenses']
        
#         # Profit margin
#         profit_margin = (total_benefits / total_inputs * Decimal('100')) if total_inputs > 0 else Decimal('0.00')
        
#         # Cash in hand
#         cash_in_hand = total_benefits
        
#         financial_overview = {
#             # ============ ALL-TIME DATA (PRIMARY) ============
#             'all_time': {
#                 'total_revenue': total_revenue,
#                 'total_collected': total_collected,
#                 'total_outstanding': total_outstanding,
#                 'collection_rate': round((total_collected / total_revenue * Decimal('100')), 2) if total_revenue > 0 else 0,
#                 'total_inputs': total_inputs,
#                 'total_outputs': total_outputs_spent,
#                 'total_benefits': total_benefits,
#                 'total_order_expenses': total_order_expenses,
#                 'profit_margin': round(profit_margin, 2),
#                 'cash_in_hand': cash_in_hand,
#                 'total_orders': orders_aggregate['total_orders'],
#                 'total_input_transactions': inputs_aggregate['total_transactions'],
#                 'total_output_transactions': outputs_aggregate['total_transactions'],
#             },
            
#             # ============ TODAY (FOR ADVANCEMENT) ============
#             'today': {
#                 'revenue': orders_aggregate['today_revenue'],
#                 'orders_count': orders_aggregate['today_orders'],
#                 'inputs': inputs_aggregate['today_inputs'],
#                 'input_transactions': inputs_aggregate['today_transactions'],
#                 'outputs': outputs_aggregate['today_outputs'],
#                 'output_transactions': outputs_aggregate['today_transactions'],
#                 'expenses': order_outputs_aggregate['today_expenses'],
#                 'net_profit': inputs_aggregate['today_inputs'] - outputs_aggregate['today_outputs'],
#             },
            
#             # ============ THIS MONTH (FOR ADVANCEMENT) ============
#             'this_month': {
#                 'revenue': orders_aggregate['month_revenue'],
#                 'orders_count': orders_aggregate['month_orders'],
#                 'inputs': inputs_aggregate['month_inputs'],
#                 'input_transactions': inputs_aggregate['month_transactions'],
#                 'outputs': outputs_aggregate['month_outputs'],
#                 'output_transactions': outputs_aggregate['month_transactions'],
#                 'expenses': order_outputs_aggregate['month_expenses'],
#                 'net_profit': inputs_aggregate['month_inputs'] - outputs_aggregate['month_outputs'],
#                 'percentage_of_total_revenue': round((orders_aggregate['month_revenue'] / total_revenue * Decimal('100')), 2) if total_revenue > 0 else 0,
#             },
            
#             # ============ THIS YEAR (FOR ADVANCEMENT) ============
#             'this_year': {
#                 'revenue': orders_aggregate['year_revenue'],
#                 'orders_count': orders_aggregate['year_orders'],
#                 'inputs': inputs_aggregate['year_inputs'],
#                 'input_transactions': inputs_aggregate['year_transactions'],
#                 'outputs': outputs_aggregate['year_outputs'],
#                 'output_transactions': outputs_aggregate['year_transactions'],
#                 'expenses': order_outputs_aggregate['year_expenses'],
#                 'net_profit': inputs_aggregate['year_inputs'] - outputs_aggregate['year_outputs'],
#                 'percentage_of_total_revenue': round((orders_aggregate['year_revenue'] / total_revenue * Decimal('100')), 2) if total_revenue > 0 else 0,
#             },
            
#             # ============ RECENT PERIOD (FOR ADVANCEMENT) ============
#             'recent_period': {
#                 'days': days,
#                 'revenue': orders_aggregate['recent_revenue'],
#                 'orders_count': orders_aggregate['recent_orders'],
#                 'collected': inputs_aggregate['recent_collected'],
#                 'inputs': inputs_aggregate['recent_inputs'],
#                 'outputs': outputs_aggregate['recent_outputs'],
#                 'expenses': order_outputs_aggregate['recent_expenses'],
#                 'profit': inputs_aggregate['recent_inputs'] - outputs_aggregate['recent_outputs'],
#                 'percentage_of_total_revenue': round((orders_aggregate['recent_revenue'] / total_revenue * Decimal('100')), 2) if total_revenue > 0 else 0,
#             },
            
#             # ============ BREAKDOWN BY TYPE ============
#             'input_breakdown': {
#                 'client_payments': inputs_aggregate['client_payments'],
#                 'shop_deposits': inputs_aggregate['shop_deposits'],
#             },
#             'output_breakdown': {
#                 'withdrawals': outputs_aggregate['withdrawals'],
#                 'supplier_payments': outputs_aggregate['supplier_payments'],
#                 'consumables': outputs_aggregate['consumables'],
#                 'stock_purchases': outputs_aggregate['stock_purchases'],
#             }
#         }

#         # ============================================
#         # 📈 2. ORDERS ANALYTICS - ALREADY AGGREGATED ABOVE
#         # ============================================
        
#         # Calculate payment status by summing CLIENT_PAYMENT inputs per order
#         # Since paid_amount is a property, we need to count it differently
#         orders_with_payments = Order.objects.annotate(
#             total_paid=Coalesce(
#                 Sum('payments__amount', filter=Q(payments__type=Input.Type.CLIENT_PAYMENT)),
#                 Decimal('0.00')
#             )
#         ).aggregate(
#             fully_paid=Count('id', filter=Q(total_paid__gte=F('total_amount'))),
#             partially_paid=Count('id', filter=Q(total_paid__gt=0, total_paid__lt=F('total_amount'))),
#             unpaid=Count('id', filter=Q(total_paid=0)),
#         )
        
#         # Top 5 Largest Orders - Optimized with select_related and prefetch
#         top_orders_qs = Order.objects.select_related('client').annotate(
#             expenses=Coalesce(Sum('order_outputs__amount'), Decimal('0.00'))
#         ).order_by('-total_amount')[:5]
        
#         top_orders = [{
#             'order_number': order.order_number,
#             'client_name': order.client.name,
#             'amount': order.total_amount,
#             'benefit': order.total_amount - order.expenses,
#             'status': order.status,
#             'date': order.order_date,
#         } for order in top_orders_qs]
        
#         orders_analytics = {
#             'total_orders': orders_aggregate['total_orders'],
#             'orders_by_status': {
#                 'completed': orders_aggregate['completed'],
#                 'in_progress': orders_aggregate['in_progress'],
#                 'pending': orders_aggregate['pending'],
#                 'cancelled': orders_aggregate['cancelled'],
#             },
#             'payment_status': {
#                 'fully_paid': orders_with_payments['fully_paid'],
#                 'partially_paid': orders_with_payments['partially_paid'],
#                 'unpaid': orders_with_payments['unpaid'],
#             },
#             'average_order_value': round(orders_aggregate['avg_order'], 2),
#             'recent_orders_7_days': orders_aggregate['recent_orders'],
#             'top_orders': top_orders,
#         }
        
#         # ============================================
#         # 👥 3. CLIENT ANALYTICS - OPTIMIZED
#         # ============================================
        
#         clients_aggregate = Client.objects.filter(is_active=True).aggregate(
#             total=Count('id'),
#             new=Count('id', filter=Q(client_type=Client.Type.NEW)),
#             old=Count('id', filter=Q(client_type=Client.Type.OLD)),
#         )
        
#         # Top 5 Clients - Single query with annotations
#         top_clients_qs = Client.objects.filter(
#             is_active=True
#         ).annotate(
#             revenue=Coalesce(Sum('orders__total_amount'), Decimal('0.00')),
#             orders_count=Count('orders')
#         ).filter(revenue__gt=0).order_by('-revenue')[:5]
        
#         top_clients = [{
#             'id': client.id,
#             'name': client.name,
#             'revenue': client.revenue,
#             'orders_count': client.orders_count,
#         } for client in top_clients_qs]
        
#         # Top 10 Debtors - Optimized with annotations
#         clients_with_debt_qs = Client.objects.filter(
#             is_active=True
#         ).annotate(
#             total_orders=Coalesce(Sum('orders__total_amount'), Decimal('0.00')),
#             total_paid=Coalesce(Sum('orders__payments__amount', filter=Q(orders__payments__type=Input.Type.CLIENT_PAYMENT)), Decimal('0.00'))
#         ).annotate(
#             outstanding=F('total_orders') - F('total_paid')
#         ).filter(outstanding__gt=0).order_by('-outstanding')[:10]
        
#         clients_with_debt = [{
#             'name': client.name,
#             'outstanding': client.outstanding,
#         } for client in clients_with_debt_qs]
        
#         client_analytics = {
#             'total_clients': clients_aggregate['total'],
#             'new_clients': clients_aggregate['new'],
#             'old_clients': clients_aggregate['old'],
#             'top_clients': top_clients,
#             'clients_with_outstanding': clients_with_debt,
#         }
        
#         # ============================================
#         # 💰 4. CASH FLOW ANALYTICS - ALREADY AGGREGATED
#         # ============================================
        
#         cash_flow = {
#             'cash_in_hand': cash_in_hand,
#             'today': {
#                 'inputs': inputs_aggregate['today_inputs'],
#                 'outputs': outputs_aggregate['today_outputs'],
#                 'net': inputs_aggregate['today_inputs'] - outputs_aggregate['today_outputs'],
#             },
#             'this_week': {
#                 'inputs': inputs_aggregate['week_inputs'],
#                 'outputs': outputs_aggregate['week_outputs'],
#                 'net': inputs_aggregate['week_inputs'] - outputs_aggregate['week_outputs'],
#             },
#             'this_month': {
#                 'inputs': inputs_aggregate['month_inputs'],
#                 'outputs': outputs_aggregate['month_outputs'],
#                 'net': inputs_aggregate['month_inputs'] - outputs_aggregate['month_outputs'],
#             },
#             'this_year': {
#                 'inputs': inputs_aggregate['year_inputs'],
#                 'outputs': outputs_aggregate['year_outputs'],
#                 'net': inputs_aggregate['year_inputs'] - outputs_aggregate['year_outputs'],
#             },
#             'input_breakdown': {
#                 'client_payments': inputs_aggregate['client_payments'],
#                 'shop_deposits': inputs_aggregate['shop_deposits'],
#             },
#             'output_breakdown': {
#                 'withdrawals': outputs_aggregate['withdrawals'],
#                 'supplier_payments': outputs_aggregate['supplier_payments'],
#                 'consumables': outputs_aggregate['consumables'],
#                 'stock_purchases': outputs_aggregate['stock_purchases'],
#             }
#         }
        
#         # ============================================
#         # 📦 5. INVENTORY & STOCK ANALYTICS - OPTIMIZED
#         # ============================================
        
#         products_aggregate = Product.objects.filter(is_active=True).aggregate(
#             total=Count('id'),
#             out_of_stock=Count('id', filter=Q(current_quantity=0)),
#         )
        
#         # Low stock items - limit to 10 for performance
#         low_stock_qs = Product.objects.filter(
#             is_active=True, 
#             current_quantity__lt=10,
#             current_quantity__gt=0
#         ).values('name', 'current_quantity', 'unit')[:10]
        
#         low_stock = [{
#             'name': item['name'],
#             'quantity': item['current_quantity'],
#             'unit': dict(Product.Unit.choices)[item['unit']],
#         } for item in low_stock_qs]
        
#         # Total stock value - optimized with subquery
#         stock_value_qs = Product.objects.filter(
#             is_active=True
#         ).annotate(
#             latest_price=Coalesce(
#                 Subquery(
#                     StockMovement.objects.filter(
#                         product=OuterRef('pk')
#                     ).order_by('-date').values('price')[:1]
#                 ),
#                 Decimal('0.00')
#             )
#         ).annotate(
#             value=F('current_quantity') * F('latest_price')
#         ).aggregate(
#             total=Coalesce(Sum('value'), Decimal('0.00'))
#         )
        
#         # Recent movements - select_related for efficiency
#         recent_movements_qs = StockMovement.objects.select_related(
#             'product', 'order'
#         ).order_by('-date')[:10]
        
#         recent_stock_movements = [{
#             'product': m.product.name,
#             'type': m.movement_type,
#             'quantity': m.quantity,
#             'price': m.price,
#             'date': m.date,
#             'order_number': m.order.order_number if m.order else None,
#         } for m in recent_movements_qs]
        
#         inventory_analytics = {
#             'total_products': products_aggregate['total'],
#             'low_stock_items': low_stock,
#             'out_of_stock_count': products_aggregate['out_of_stock'],
#             'total_stock_value': round(stock_value_qs['total'], 2),
#             'recent_movements': recent_stock_movements,
#         }
        
#         # ============================================
#         # 🏭 6. SUPPLIER ANALYTICS - OPTIMIZED
#         # ============================================
        
#         suppliers_aggregate = Supplier.objects.filter(is_active=True).aggregate(
#             total=Count('id')
#         )
        
#         # Top suppliers - single query with annotation
#         top_suppliers_qs = Supplier.objects.filter(
#             is_active=True
#         ).annotate(
#             total_paid=Coalesce(Sum('outputs__amount', filter=Q(outputs__type=Output.Type.SUPPLIER_PAYMENT)), Decimal('0.00'))
#         ).filter(total_paid__gt=0).order_by('-total_paid')[:5]
        
#         top_suppliers = [{
#             'name': supplier.name,
#             'total_paid': supplier.total_paid,
#             'phone': supplier.phone,
#         } for supplier in top_suppliers_qs]
        
#         supplier_analytics = {
#             'total_suppliers': suppliers_aggregate['total'],
#             'top_suppliers': top_suppliers,
#         }
        
#         # ============================================
#         # 👤 7. USER ACTIVITY ANALYTICS - OPTIMIZED
#         # ============================================
        
#         users_aggregate = User.objects.filter(is_active=True).aggregate(
#             total=Count('id'),
#             admin=Count('id', filter=Q(role=User.Role.ADMIN)),
#             responsible=Count('id', filter=Q(role=User.Role.RESPONSIBLE)),
#             simple_user=Count('id', filter=Q(role=User.Role.SIMPLE_USER)),
#         )
        
#         # Most active users - single query with annotation
#         active_users_qs = User.objects.filter(is_active=True).annotate(
#             input_count=Count('inputs'),
#             output_count=Count('outputs'),
#             total_transactions=F('input_count') + F('output_count')
#         ).filter(total_transactions__gt=0).order_by('-total_transactions')[:5]
        
#         active_users = [{
#             'username': user.username,
#             'full_name': user.full_name,
#             'role': user.get_role_display(),
#             'transactions': user.total_transactions,
#         } for user in active_users_qs]
        
#         user_analytics = {
#             'total_users': users_aggregate['total'],
#             'users_by_role': {
#                 'admin': users_aggregate['admin'],
#                 'responsible': users_aggregate['responsible'],
#                 'simple_user': users_aggregate['simple_user'],
#             },
#             'most_active_users': active_users,
#         }
        
#         # ============================================
#         # 📅 8. TIME-BASED TRENDS - OPTIMIZED WITH SINGLE QUERY
#         # ============================================
        
#         # Calculate 6 months of trends in one query using TruncMonth
#         six_months_ago = timezone.now() - timedelta(days=180)
        
#         monthly_orders = Order.objects.filter(
#             order_date__gte=six_months_ago
#         ).annotate(
#             month=TruncMonth('order_date')
#         ).values('month').annotate(
#             revenue=Coalesce(Sum('total_amount'), Decimal('0.00')),
#             count=Count('id')
#         ).order_by('month')
        
#         monthly_inputs = Input.objects.filter(
#             date__gte=six_months_ago
#         ).annotate(
#             month=TruncMonth('date')
#         ).values('month').annotate(
#             inputs=Coalesce(Sum('amount'), Decimal('0.00'))
#         ).order_by('month')
        
#         monthly_outputs = Output.objects.filter(
#             date__gte=six_months_ago
#         ).annotate(
#             month=TruncMonth('date')
#         ).values('month').annotate(
#             outputs=Coalesce(Sum('amount'), Decimal('0.00'))
#         ).order_by('month')
        
#         monthly_expenses = OrderOutput.objects.filter(
#             created_at__gte=six_months_ago
#         ).annotate(
#             month=TruncMonth('created_at')
#         ).values('month').annotate(
#             expenses=Coalesce(Sum('amount'), Decimal('0.00'))
#         ).order_by('month')
        
#         # Merge the data
#         inputs_dict = {item['month']: item['inputs'] for item in monthly_inputs}
#         outputs_dict = {item['month']: item['outputs'] for item in monthly_outputs}
#         expenses_dict = {item['month']: item['expenses'] for item in monthly_expenses}
        
#         monthly_trends = []
#         for item in monthly_orders:
#             month = item['month']
#             inputs = inputs_dict.get(month, Decimal('0.00'))
#             outputs = outputs_dict.get(month, Decimal('0.00'))
#             expenses = expenses_dict.get(month, Decimal('0.00'))
#             monthly_trends.append({
#                 'month': month.strftime('%Y-%m'),
#                 'revenue': item['revenue'],
#                 'inputs': inputs,
#                 'outputs': outputs,
#                 'expenses': expenses,
#                 'profit': inputs - outputs,  # True profit = inputs - outputs
#                 'orders_count': item['count'],
#             })
        
#         # Ensure we have last 6 months even if no data
#         if len(monthly_trends) < 6:
#             for i in range(6 - len(monthly_trends)):
#                 month_date = (timezone.now() - timedelta(days=(5-i)*30)).replace(day=1)
#                 if not any(t['month'] == month_date.strftime('%Y-%m') for t in monthly_trends):
#                     monthly_trends.insert(0, {
#                         'month': month_date.strftime('%Y-%m'),
#                         'revenue': Decimal('0.00'),
#                         'inputs': Decimal('0.00'),
#                         'outputs': Decimal('0.00'),
#                         'expenses': Decimal('0.00'),
#                         'profit': Decimal('0.00'),
#                         'orders_count': 0,
#                     })
        
#         monthly_trends = monthly_trends[-6:]  # Keep only last 6
        
#         # ============================================
#         # 🎯 9. KEY PERFORMANCE INDICATORS - OPTIMIZED
#         # ============================================
        
#         # Customer retention - optimized query
#         repeat_clients = Client.objects.filter(
#             is_active=True
#         ).annotate(
#             order_count=Count('orders')
#         ).filter(order_count__gt=1).count()
        
#         total_clients = clients_aggregate['total']
#         retention_rate = (Decimal(repeat_clients) / Decimal(total_clients) * Decimal('100')) if total_clients > 0 else Decimal('0')
        
#         kpis = {
#             'profit_margin': round(profit_margin, 2),
#             'collection_rate': round((total_collected / total_revenue * Decimal('100')), 2) if total_revenue > 0 else 0,
#             'average_order_value': round(orders_aggregate['avg_order'], 2),
#             'customer_retention_rate': round(retention_rate, 2),
#             'orders_completion_rate': round((Decimal(orders_aggregate['completed']) / Decimal(orders_aggregate['total_orders']) * Decimal('100')), 2) if orders_aggregate['total_orders'] > 0 else 0,
#             'cash_flow_health': 'Positive' if cash_in_hand > 0 else 'Negative',
#         }
        
#         # ============================================
#         # 🚨 10. ALERTS & WARNINGS - OPTIMIZED
#         # ============================================
        
#         alerts = []
        
#         if cash_in_hand < Decimal('10000'):
#             alerts.append({
#                 'type': 'warning',
#                 'category': 'cash_flow',
#                 'message': f'Low cash in hand: {cash_in_hand} DA',
#             })
        
#         if total_outstanding > total_revenue * Decimal('0.3'):
#             alerts.append({
#                 'type': 'warning',
#                 'category': 'payments',
#                 'message': f'High outstanding payments: {total_outstanding} DA ({round(total_outstanding/total_revenue*Decimal("100"), 2)}%)',
#             })
        
#         if products_aggregate['out_of_stock'] > 0:
#             alerts.append({
#                 'type': 'critical',
#                 'category': 'inventory',
#                 'message': f'{products_aggregate["out_of_stock"]} products are out of stock',
#             })
        
#         if len(low_stock) > 0:
#             alerts.append({
#                 'type': 'warning',
#                 'category': 'inventory',
#                 'message': f'{len(low_stock)} products have low stock',
#             })
        
#         if orders_aggregate['total_orders'] > 0 and orders_with_payments['unpaid'] > int(orders_aggregate['total_orders'] * 0.2):
#             alerts.append({
#                 'type': 'warning',
#                 'category': 'orders',
#                 'message': f'{orders_with_payments["unpaid"]} orders are completely unpaid',
#             })
        
#         # ============================================
#         # 📊 FINAL COMPREHENSIVE RESPONSE
#         # ============================================
        
#         dashboard_data = {
#             'generated_at': timezone.now(),
#             'period_days': days,
#             'financial_overview': financial_overview,
#             'orders_analytics': orders_analytics,
#             'client_analytics': client_analytics,
#             'cash_flow': cash_flow,
#             'inventory_analytics': inventory_analytics,
#             'supplier_analytics': supplier_analytics,
#             'user_analytics': user_analytics,
#             'monthly_trends': monthly_trends,
#             'kpis': kpis,
#             'alerts': alerts,
#         }
        
#         return Response(dashboard_data, status=status.HTTP_200_OK)
