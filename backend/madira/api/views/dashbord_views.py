from rest_framework import permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from django.db.models import (
    Sum, Count, Avg, Q, F, OuterRef, Subquery, Case, When, 
    DecimalField, Value
)
from django.db.models.functions import Coalesce, TruncMonth, TruncYear, TruncDay
from decimal import Decimal
from datetime import timedelta
from django.utils import timezone
from ..models import (
    Client, Order, Input, Output, OrderOutput, 
    Product, StockMovement, Supplier, User
)


class ComprehensiveDashboardView(APIView):
    """
     ESSENTIAL DASHBOARD ANALYTICS API
    
    Core Metrics Only:
    - Financial Overview (Revenue, Expenses, Profit, Cash)
    - Orders Summary (Status & Payment)
    - Top Clients & Debtors
    - Inventory Status
    - Time Trends
    - Critical Alerts
    
    ═══════════════════════════════════════════════════════════════════
     METRICS CALCULATION GUIDE
    ═══════════════════════════════════════════════════════════════════
    
    1️⃣ FINANCIAL OVERVIEW:
    ─────────────────────────────────────────────────────────────────
    • total_revenue: Sum of all Order.total_amount in period
      SQL: SELECT SUM(total_amount) FROM orders WHERE order_date >= start_date
      
    • total_collected: Sum of Input.amount where type = 'CLIENT_PAYMENT'
      SQL: SELECT SUM(amount) FROM inputs WHERE type = 'CLIENT_PAYMENT' AND date >= start_date
      Business Logic: Only client payments count as collected revenue
      
    • total_outstanding: total_revenue - total_collected
      Formula: Outstanding Debt = Total Billed - Total Received
      
    • collection_rate: (total_collected / total_revenue) * 100
      Formula: What % of billed revenue has been collected
      
    • total_expenses: Sum of all Output.amount in period
      SQL: SELECT SUM(amount) FROM outputs WHERE date >= start_date
      
    • actual_profit (REAL CASH PROFIT): total_collected - total_expenses
      Formula: Cash received minus cash spent = ACTUAL profit realized
      Note: This is the REAL profit - only counts money actually in hand
      Business Logic: Uses collected (not revenue) because uncollected revenue isn't cash yet
      
    • expected_profit (PROJECTED PROFIT): total_revenue - total_expenses
      Formula: Total billed minus expenses = EXPECTED profit when all invoices are paid
      Note: This is PROJECTED profit - assumes all outstanding debts will be collected
      Business Logic: Shows what profit WOULD BE if all clients pay their invoices
      
    • actual_profit_margin: (actual_profit / total_collected) * 100
      Formula: Real profit as % of money actually collected
      
    • expected_profit_margin: (expected_profit / total_revenue) * 100
      Formula: Projected profit as % of total billed revenue
      
    • cash_in_hand: total_inputs - total_expenses
      Formula: All money IN (payments + deposits) - All money OUT
      SQL: (SELECT SUM(amount) FROM inputs) - (SELECT SUM(amount) FROM outputs)
      
    • expense_breakdown: Categories of Output by type
      - withdrawals: Output.type = 'WITHDRAWAL'
      - supplier_payments: Output.type = 'SUPPLIER_PAYMENT'
      - consumables: Output.type = 'CONSUMABLE'
      - stock_purchases: Output.type = 'GLOBAL_STOCK_PURCHASE'
      - client_stock_usage: Output.type = 'CLIENT_STOCK_USAGE'
      - other_expenses: Output.type = 'OTHER_EXPENSE'
    
    2️⃣ ORDERS ANALYTICS:
    ─────────────────────────────────────────────────────────────────
    • total_orders: Count of all orders
      SQL: SELECT COUNT(*) FROM orders WHERE order_date >= start_date
      
    • completed/in_progress/pending/cancelled: Count by Order.status
      SQL: SELECT COUNT(*) FROM orders WHERE status = 'COMPLETED' AND order_date >= start_date
      
    • fully_paid: Orders where total_paid >= total_amount
      Logic: For each order, sum related inputs (payments), compare to order total
      SQL: SELECT COUNT(*) FROM orders o 
           WHERE (SELECT SUM(amount) FROM inputs WHERE order_id = o.id) >= o.total_amount
      
    • partially_paid: Orders where 0 < total_paid < total_amount
      Logic: Some payment made, but not full amount
      
    • unpaid: Orders where total_paid = 0
      Logic: No payments recorded yet
      
    • average_order_value: AVG(Order.total_amount)
      SQL: SELECT AVG(total_amount) FROM orders WHERE order_date >= start_date
    
    3️⃣ CLIENT ANALYTICS:
    ─────────────────────────────────────────────────────────────────
    • total_clients: Count of active clients
      SQL: SELECT COUNT(*) FROM clients WHERE is_active = TRUE
      
    • top_clients: Top 5 by revenue
      Logic: For each client, sum all their order totals, rank by highest
      SQL: SELECT client.name, SUM(orders.total_amount) as revenue
           FROM clients 
           JOIN orders ON orders.client_id = clients.id
           WHERE clients.is_active = TRUE
           GROUP BY client.id
           ORDER BY revenue DESC
           LIMIT 5
      
    • top_debtors: Top 10 by outstanding balance
      Logic: For each client: (total billed - total paid)
      SQL: SELECT client.name, 
                  SUM(orders.total_amount) - COALESCE(SUM(inputs.amount), 0) as outstanding
           FROM clients
           LEFT JOIN orders ON orders.client_id = clients.id
           LEFT JOIN inputs ON inputs.order_id = orders.id AND inputs.type = 'CLIENT_PAYMENT'
           WHERE clients.is_active = TRUE
           GROUP BY client.id
           HAVING outstanding > 0
           ORDER BY outstanding DESC
           LIMIT 10
    
    4️⃣ INVENTORY ANALYTICS:
    ─────────────────────────────────────────────────────────────────
    • total_products: Count of active products
      SQL: SELECT COUNT(*) FROM products WHERE is_active = TRUE
      
    • out_of_stock: Products with current_quantity = 0
      SQL: SELECT COUNT(*) FROM products WHERE is_active = TRUE AND current_quantity = 0
      
    • low_stock: Products with 0 < current_quantity < 10
      SQL: SELECT COUNT(*) FROM products WHERE is_active = TRUE 
           AND current_quantity < 10 AND current_quantity > 0
      
    • low_stock_items: List of low stock products with details
      Returns: name, current_quantity, unit
      
    • total_stock_value: Sum of (current_quantity × average_cost) for all products
      Logic: 
        1. For each product, calculate average cost from stock movements:
           avg_cost = SUM(quantity × price) / SUM(quantity) [for IN movements only]
        2. value = current_quantity × avg_cost
        3. total = SUM(all product values)
      SQL: SELECT SUM(current_quantity * avg_cost) as total_value
           FROM (
             SELECT p.current_quantity,
                    SUM(sm.quantity * sm.price) / SUM(sm.quantity) as avg_cost
             FROM products p
             JOIN stock_movements sm ON sm.product_id = p.id
             WHERE sm.movement_type = 'IN' AND p.is_active = TRUE
             GROUP BY p.id
           )
    
    5️⃣ TIME-BASED TRENDS:
    ─────────────────────────────────────────────────────────────────
    Depends on period parameter:
    
    • period='month': Daily breakdown (each day of current month)
      - Groups by TruncDay(order_date/date)
      - Returns revenue, collected, expenses, profit per day
      
    • period='year': Monthly breakdown (each month of current year)
      - Groups by TruncMonth(order_date/date)
      - Returns revenue, collected, expenses, profit per month
      
    • period='all_time': Yearly breakdown (all years)
      - Groups by TruncYear(order_date/date)
      - Returns revenue, collected, expenses, profit per year
      
    For each time period:
    • revenue: SUM(orders.total_amount) for that period
    • collected: SUM(inputs.amount) where type='CLIENT_PAYMENT' for that period
    • expenses: SUM(outputs.amount) for that period
    • profit: collected - expenses
    • orders: COUNT(orders) for that period
    
    6️⃣ ALERTS & WARNINGS:
    ─────────────────────────────────────────────────────────────────
    • Low cash: Triggered if cash_in_hand < 10,000 DA
    • High outstanding: Triggered if outstanding > 30% of total revenue
    • Out of stock: Triggered if any products have quantity = 0
    • Low stock: Triggered if any products have 0 < quantity < 10
    • Unpaid orders: Triggered if unpaid orders > 20% of total orders
    • Operating at loss: Triggered if net_profit < 0
    
    ═══════════════════════════════════════════════════════════════════
    """
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        # ============================================
        #  PERIOD SETUP & VALIDATION
        # ============================================
        # Determines the time range for all metrics
        # Valid options: 'today', 'month', 'year', 'all_time'
        
        period = request.query_params.get('period', 'all_time').lower()
        
        valid_periods = ['today', 'month', 'year', 'all_time']
        if period not in valid_periods:
            return Response(
                {'error': f'Invalid period. Must be one of: {", ".join(valid_periods)}'},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        now = timezone.now()
        
        if period == 'today':
            # From 00:00:00 today to now
            start_date = now.replace(hour=0, minute=0, second=0, microsecond=0)
            period_label = 'Today'
        elif period == 'month':
            # From 1st day of current month to now
            start_date = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
            period_label = 'This Month'
        elif period == 'year':
            # From Jan 1st of current year to now
            start_date = now.replace(month=1, day=1, hour=0, minute=0, second=0, microsecond=0)
            period_label = 'This Year'
        else:  # all_time
            # No date filter - include all historical data
            start_date = None
            period_label = 'All Time'
        
        # Build Q filter objects for efficient querying
        if start_date:
            orders_filter = Q(order_date__gte=start_date)
            inputs_filter = Q(date__gte=start_date)
            outputs_filter = Q(date__gte=start_date)
            stock_movements_filter = Q(date__gte=start_date)
        else:
            orders_filter = Q()
            inputs_filter = Q()
            outputs_filter = Q()
            stock_movements_filter = Q()
        
        # ============================================
        #  1. ORDERS AGGREGATION
        # ============================================
        # Calculates: revenue, order counts, status breakdown
        # Formula: SUM(total_amount), COUNT(*), COUNT(*) per status
        
        orders_aggregate = Order.objects.filter(orders_filter).aggregate(
            # Total revenue = sum of all order amounts (billed, not necessarily collected)
            total_revenue=Coalesce(Sum('total_amount', filter=~Q(status=Order.Status.CANCELLED)), Decimal('0.00')),
            
            # Total number of orders
            total_orders=Count('id'),
            
            # Average order value = total revenue / number of orders
            avg_order=Coalesce(Avg('total_amount', filter=~Q(status=Order.Status.CANCELLED)), Decimal('0.00')),
            
            # Order status breakdown - counts per status
            completed=Count('id', filter=Q(status=Order.Status.COMPLETED)),
            in_progress=Count('id', filter=Q(status=Order.Status.IN_PROGRESS)),
            pending=Count('id', filter=Q(status=Order.Status.PENDING)),
            cancelled=Count('id', filter=Q(status=Order.Status.CANCELLED)),
        )
        
        # ============================================
        #  2. INPUTS AGGREGATION
        # ============================================
        # Calculates: total money IN, by category
        # Inputs represent money coming INTO the business
        
        inputs_aggregate = Input.objects.filter(inputs_filter).aggregate(
            # Total money received from all sources
            total_inputs=Coalesce(Sum('amount'), Decimal('0.00')),
            
            # Money collected from clients for orders (actual revenue collection)
            client_payments=Coalesce(Sum('amount', filter=Q(type=Input.Type.CLIENT_PAYMENT)), Decimal('0.00')),
            
            # Money deposited to shop (cash injections, loans, etc.)
            shop_deposits=Coalesce(Sum('amount', filter=Q(type=Input.Type.SHOP_DEPOSIT)), Decimal('0.00')),
        )
        
        # ============================================
        #  3. OUTPUTS AGGREGATION
        # ============================================
        # Calculates: total money OUT, by category
        # Outputs represent money going OUT of the business
        
        outputs_aggregate = Output.objects.filter(outputs_filter).aggregate(
            # Total expenses - all money spent
            total_outputs=Coalesce(Sum('amount'), Decimal('0.00')),
            
            # Money withdrawn by owner/management
            withdrawals=Coalesce(Sum('amount', filter=Q(type=Output.Type.WITHDRAWAL)), Decimal('0.00')),
            withdrawals_count=Count('id', filter=Q(type=Output.Type.WITHDRAWAL)),
            
            # Payments made to suppliers for goods/services
            supplier_payments=Coalesce(Sum('amount', filter=Q(type=Output.Type.SUPPLIER_PAYMENT)), Decimal('0.00')),
            supplier_payments_count=Count('id', filter=Q(type=Output.Type.SUPPLIER_PAYMENT)),
            
            # Consumable supplies (paper, ink, etc.)
            consumables=Coalesce(Sum('amount', filter=Q(type=Output.Type.CONSUMABLE)), Decimal('0.00')),
            consumables_count=Count('id', filter=Q(type=Output.Type.CONSUMABLE)),
            
            # Global stock purchases (inventory bought for general use)
            stock_purchases=Coalesce(Sum('amount', filter=Q(type=Output.Type.GLOBAL_STOCK_PURCHASE)), Decimal('0.00')),
            stock_purchases_count=Count('id', filter=Q(type=Output.Type.GLOBAL_STOCK_PURCHASE)),
            
            # Stock used for specific client orders
            client_stock_usage=Coalesce(Sum('amount', filter=Q(type=Output.Type.CLIENT_STOCK_USAGE)), Decimal('0.00')),
            client_stock_usage_count=Count('id', filter=Q(type=Output.Type.CLIENT_STOCK_USAGE)),
            
            # Other miscellaneous expenses
            other_expenses=Coalesce(Sum('amount', filter=Q(type=Output.Type.OTHER_EXPENSE)), Decimal('0.00')),
            other_expenses_count=Count('id', filter=Q(type=Output.Type.OTHER_EXPENSE)),
        )
        
        # ============================================
        #  4. FINANCIAL CALCULATIONS
        # ============================================
        # Derives key financial metrics from raw data
        
        # Total revenue billed (may not be collected yet)
        total_revenue = orders_aggregate['total_revenue']
        
        # Total revenue actually collected in cash
        total_collected = inputs_aggregate['client_payments']
        
        # Outstanding debt = billed but not collected
        # Formula: Outstanding = Revenue - Collected
        total_outstanding = total_revenue - total_collected
        
        # Total business expenses
        total_expenses = outputs_aggregate['total_outputs']
        
        # Actual profit = money in minus money out
        # Formula: Actual Profit = Collected - Expenses
        # Note: Uses 'collected' not 'revenue' because uncollected revenue isn't cash yet
        actual_profit = total_collected - total_expenses
        
        # Expected profit = total revenue minus expenses
        # Formula: Expected Profit = Revenue - Expenses
        # Note: Uses 'revenue' because it includes all billed amounts, even if not collected yet
        expected_profit = total_revenue - total_expenses
        
        # Actual profit margin = actual profit as % of collected revenue
        # Formula: (Actual Profit / Collected) × 100
        actual_profit_margin = (actual_profit / total_collected * Decimal('100')) if total_collected > 0 else Decimal('0.00')
        
        # Expected profit margin = expected profit as % of total revenue
        # Formula: (Expected Profit / Revenue) × 100
        expected_profit_margin = (expected_profit / total_revenue * Decimal('100')) if total_revenue > 0 else Decimal('0.00')
        
        # Cash in hand = all money in minus all money out
        # Formula: Cash = Total Inputs - Total Outputs
        # Includes both client payments AND shop deposits
        cash_in_hand = inputs_aggregate['total_inputs'] - total_expenses
        
        # ============================================
        #  5. FINANCIAL OVERVIEW (ESSENTIAL ONLY)
        # ============================================
        
        financial_overview = {
            'period': period_label,
            
            # Core Revenue Metrics
            'total_revenue': total_revenue,  # Total billed
            'total_collected': total_collected,  # Total cash received from clients
            'total_outstanding': total_outstanding,  # Unpaid invoices
            'collection_rate': round((total_collected / total_revenue * Decimal('100')), 2) if total_revenue > 0 else 0,  # % collected
            
            # Core Expense & Profit
            'total_expenses': total_expenses,  # All money spent
            'actual_profit': actual_profit,  # Real cash profit
            'expected_profit': expected_profit,  # Projected profit
            'actual_profit_margin': round(actual_profit_margin, 2),  # Real profit as % of collected
            'expected_profit_margin': round(expected_profit_margin, 2),  # Projected profit as % of billed
            
            # Cash Position
            'cash_in_hand': cash_in_hand,  # Available liquidity
            
            # Expense Breakdown - where money is going (amount + count)
            'expense_breakdown': {
                'withdrawals': {
                    'amount': outputs_aggregate['withdrawals'],
                    'count': outputs_aggregate['withdrawals_count']
                },
                'supplier_payments': {
                    'amount': outputs_aggregate['supplier_payments'],
                    'count': outputs_aggregate['supplier_payments_count']
                },
                'consumables': {
                    'amount': outputs_aggregate['consumables'],
                    'count': outputs_aggregate['consumables_count']
                },
                'stock_purchases': {
                    'amount': outputs_aggregate['stock_purchases'],
                    'count': outputs_aggregate['stock_purchases_count']
                },
                'client_stock_usage': {
                    'amount': outputs_aggregate['client_stock_usage'],
                    'count': outputs_aggregate['client_stock_usage_count']
                },
                'other_expenses': {
                    'amount': outputs_aggregate['other_expenses'],
                    'count': outputs_aggregate['other_expenses_count']
                },
            }
        }

        # ============================================
        #  6. ORDERS ANALYTICS (SIMPLIFIED)
        # ============================================
        # Analyzes order payment status
        # For each order, calculates total paid and compares to order total
        
        orders_with_payments = Order.objects.filter(orders_filter).annotate(
            # For each order, sum all client payments linked to it
            total_paid=Coalesce(
                Sum('payments__amount', filter=Q(payments__type=Input.Type.CLIENT_PAYMENT)),
                Decimal('0.00')
            )
        ).aggregate(
            # Fully paid: total_paid >= order.total_amount
            fully_paid=Count('id', filter=Q(total_paid__gte=F('total_amount'))),
            
            # Partially paid: 0 < total_paid < order.total_amount
            partially_paid=Count('id', filter=Q(total_paid__gt=0, total_paid__lt=F('total_amount'))),
            
            # Unpaid: total_paid = 0
            unpaid=Count('id', filter=Q(total_paid=0)),
        )
        
        orders_analytics = {
            'total_orders': orders_aggregate['total_orders'],
            'completed': orders_aggregate['completed'],
            'in_progress': orders_aggregate['in_progress'],
            'pending': orders_aggregate['pending'],
            'fully_paid': orders_with_payments['fully_paid'],
            'partially_paid': orders_with_payments['partially_paid'],
            'unpaid': orders_with_payments['unpaid'],
            'average_order_value': round(orders_aggregate['avg_order'], 2),
        }
        
        # ============================================
        #  7. CLIENT ANALYTICS (TOP 5 & DEBTORS)
        # ============================================
        
        clients_aggregate = Client.objects.filter(is_active=True).aggregate(
            total=Count('id'),
        )
        
        # Top 5 clients by revenue
        # Ranks clients by how much total revenue they generated
        if start_date:
            client_revenue_filter = Q(orders__order_date__gte=start_date)
        else:
            client_revenue_filter = Q()
        
        top_clients_qs = Client.objects.filter(
            is_active=True
        ).annotate(
            # Sum all order totals for this client
            revenue=Coalesce(Sum('orders__total_amount', filter=client_revenue_filter), Decimal('0.00')),
            # Count orders for this client
            orders_count=Count('orders', filter=client_revenue_filter)
        ).filter(revenue__gt=0).order_by('-revenue')[:5]  # Top 5 by revenue
        
        top_clients = [{
            'id': client.id,
            'name': client.name,
            'revenue': client.revenue,
            'orders_count': client.orders_count,
        } for client in top_clients_qs]
        
        # Top 10 debtors (clients who owe the most money)
        # Calculation: (Total Billed to Client) - (Total Paid by Client)
        clients_with_debt_qs = Client.objects.filter(
            is_active=True
        ).annotate(
            # Total amount billed to this client (all their orders)
            total_owed=Coalesce(Sum('orders__total_amount'), Decimal('0.00')),
            
            # Total amount paid by this client (all their payments)
            total_paid=Coalesce(
                Sum('orders__payments__amount', 
                    filter=Q(orders__payments__type=Input.Type.CLIENT_PAYMENT)), 
                Decimal('0.00')
            ),
            
            # Outstanding balance = owed - paid
            outstanding=F('total_owed') - F('total_paid')
        ).filter(outstanding__gt=0).order_by('-outstanding')[:10]  # Top 10 debtors
        
        clients_with_debt = [{
            'name': client.name,
            'outstanding': client.outstanding,
        } for client in clients_with_debt_qs]
        
        client_analytics = {
            'total_clients': clients_aggregate['total'],
            'top_clients': top_clients,
            'top_debtors': clients_with_debt,
        }
        
        # ============================================
        #  8. INVENTORY ANALYTICS (CRITICAL ONLY)
        # ============================================
        
        products_aggregate = Product.objects.filter(is_active=True).aggregate(
            total=Count('id'),  # Total active products
            out_of_stock=Count('id', filter=Q(current_quantity=0)),  # No stock left
            low_stock=Count('id', filter=Q(current_quantity__lt=10, current_quantity__gt=0)),  # Low stock warning
        )
        
        # Get list of products with low stock
        low_stock_items = list(Product.objects.filter(
            is_active=True, 
            current_quantity__lt=10,
            current_quantity__gt=0
        ).values('name', 'current_quantity', 'unit')[:10])
        
        # Stock valuation - calculate total value of inventory
        # Method: For each product, calculate average cost and multiply by current quantity
        stock_value_qs = Product.objects.filter(
            is_active=True
        ).annotate(
            # Total cost of all stock purchases (IN movements only)
            # Formula: SUM(quantity × price) for each stock IN
            total_cost=Coalesce(
                Sum(
                    F('stock_movements__quantity') * F('stock_movements__price'),
                    filter=Q(stock_movements__movement_type=StockMovement.MovementType.IN)
                ),
                Decimal('0.00')
            ),
            
            # Total quantity purchased (IN movements only)
            total_in_quantity=Coalesce(
                Sum('stock_movements__quantity',
                    filter=Q(stock_movements__movement_type=StockMovement.MovementType.IN)),
                Decimal('0.00')
            ),
            
            # Average cost per unit = total cost / total quantity
            # This is the weighted average cost
            avg_cost=Case(
                When(total_in_quantity__gt=0, 
                     then=F('total_cost') / F('total_in_quantity')),
                default=Decimal('0.00'),
                output_field=DecimalField(max_digits=12, decimal_places=2)
            ),
            
            # Current stock value = current quantity × average cost
            value=F('current_quantity') * F('avg_cost')
        ).aggregate(
            # Total value of all inventory
            total=Coalesce(Sum('value'), Decimal('0.00'))
        )
        
        inventory_analytics = {
            'total_products': products_aggregate['total'],
            'out_of_stock': products_aggregate['out_of_stock'],
            'low_stock': products_aggregate['low_stock'],
            'low_stock_items': low_stock_items,
            'total_stock_value': round(stock_value_qs['total'], 2),
        }
        
        # ============================================
        #  9. TIME-BASED TRENDS
        # ============================================
        # Shows how metrics change over time
        # Granularity depends on selected period
        
        trends = []
        
        if period == 'month':
            # Daily trends for current month
            # Groups data by each day, shows daily performance
            
            daily_orders = list(Order.objects.filter(orders_filter).annotate(
                day=TruncDay('order_date')  # Truncate to day level
            ).values('day').annotate(
                revenue=Coalesce(Sum('total_amount'), Decimal('0.00')),
                count=Count('id')
            ).order_by('day'))
            
            daily_inputs = list(Input.objects.filter(inputs_filter).annotate(
                day=TruncDay('date')
            ).values('day').annotate(
                collected=Coalesce(Sum('amount', filter=Q(type=Input.Type.CLIENT_PAYMENT)), Decimal('0.00')),
                total_in=Coalesce(Sum('amount'), Decimal('0.00'))
            ).order_by('day'))
            
            daily_outputs = list(Output.objects.filter(outputs_filter).annotate(
                day=TruncDay('date')
            ).values('day').annotate(
                total_out=Coalesce(Sum('amount'), Decimal('0.00'))
            ).order_by('day'))
            
            # Combine all dates from orders, inputs, and outputs
            all_dates = set()
            for item in daily_orders:
                all_dates.add(item['day'])
            for item in daily_inputs:
                all_dates.add(item['day'])
            for item in daily_outputs:
                all_dates.add(item['day'])
            
            # Create lookup dictionaries for fast access
            orders_dict = {item['day']: item for item in daily_orders}
            inputs_dict = {item['day']: item for item in daily_inputs}
            outputs_dict = {item['day']: item['total_out'] for item in daily_outputs}
            
            # Build trend data for each day
            for day in sorted(all_dates):
                order_data = orders_dict.get(day, {'revenue': Decimal('0.00'), 'count': 0})
                input_data = inputs_dict.get(day, {'collected': Decimal('0.00'), 'total_in': Decimal('0.00')})
                outputs = outputs_dict.get(day, Decimal('0.00'))
                
                trends.append({
                    'period': day.strftime('%Y-%m-%d'),
                    'revenue': order_data['revenue'],  # Billed
                    'collected': input_data['collected'],  # Cash received
                    'expenses': outputs,  # Cash spent
                    'profit': input_data['collected'] - outputs,  # Daily profit
                    'orders': order_data['count'],  # Number of orders
                })
        
        elif period == 'year':
            # Monthly trends for current year
            # Groups data by each month, shows monthly performance
            
            monthly_orders = list(Order.objects.filter(orders_filter).annotate(
                month=TruncMonth('order_date')  # Truncate to month level
            ).values('month').annotate(
                revenue=Coalesce(Sum('total_amount'), Decimal('0.00')),
                count=Count('id')
            ).order_by('month'))
            
            monthly_inputs = list(Input.objects.filter(inputs_filter).annotate(
                month=TruncMonth('date')
            ).values('month').annotate(
                collected=Coalesce(Sum('amount', filter=Q(type=Input.Type.CLIENT_PAYMENT)), Decimal('0.00')),
                total_in=Coalesce(Sum('amount'), Decimal('0.00'))
            ).order_by('month'))
            
            monthly_outputs = list(Output.objects.filter(outputs_filter).annotate(
                month=TruncMonth('date')
            ).values('month').annotate(
                total_out=Coalesce(Sum('amount'), Decimal('0.00'))
            ).order_by('month'))
            
            # Combine all months
            all_months = set()
            for item in monthly_orders:
                all_months.add(item['month'])
            for item in monthly_inputs:
                all_months.add(item['month'])
            for item in monthly_outputs:
                all_months.add(item['month'])
            
            orders_dict = {item['month']: item for item in monthly_orders}
            inputs_dict = {item['month']: item for item in monthly_inputs}
            outputs_dict = {item['month']: item['total_out'] for item in monthly_outputs}
            
            for month in sorted(all_months):
                order_data = orders_dict.get(month, {'revenue': Decimal('0.00'), 'count': 0})
                input_data = inputs_dict.get(month, {'collected': Decimal('0.00'), 'total_in': Decimal('0.00')})
                outputs = outputs_dict.get(month, Decimal('0.00'))
                
                trends.append({
                    'period': month.strftime('%B %Y'),
                    'revenue': order_data['revenue'],
                    'collected': input_data['collected'],
                    'expenses': outputs,
                    'profit': input_data['collected'] - outputs,
                    'orders': order_data['count'],
                })
        
        elif period == 'all_time':
            # Yearly trends for entire history
            # Groups data by each year, shows yearly performance
            
            yearly_orders = list(Order.objects.annotate(
                year=TruncYear('order_date')  # Truncate to year level
            ).values('year').annotate(
                revenue=Coalesce(Sum('total_amount'), Decimal('0.00')),
                count=Count('id')
            ).order_by('year'))
            
            yearly_inputs = list(Input.objects.annotate(
                year=TruncYear('date')
            ).values('year').annotate(
                collected=Coalesce(Sum('amount', filter=Q(type=Input.Type.CLIENT_PAYMENT)), Decimal('0.00')),
                total_in=Coalesce(Sum('amount'), Decimal('0.00'))
            ).order_by('year'))
            
            yearly_outputs = list(Output.objects.annotate(
                year=TruncYear('date')
            ).values('year').annotate(
                total_out=Coalesce(Sum('amount'), Decimal('0.00'))
            ).order_by('year'))
            
            # Combine all years
            all_years = set()
            for item in yearly_orders:
                all_years.add(item['year'])
            for item in yearly_inputs:
                all_years.add(item['year'])
            for item in yearly_outputs:
                all_years.add(item['year'])
            
            orders_dict = {item['year']: item for item in yearly_orders}
            inputs_dict = {item['year']: item for item in yearly_inputs}
            outputs_dict = {item['year']: item['total_out'] for item in yearly_outputs}
            
            for year in sorted(all_years):
                order_data = orders_dict.get(year, {'revenue': Decimal('0.00'), 'count': 0})
                input_data = inputs_dict.get(year, {'collected': Decimal('0.00'), 'total_in': Decimal('0.00')})
                outputs = outputs_dict.get(year, Decimal('0.00'))
                
                trends.append({
                    'period': year.strftime('%Y'),
                    'revenue': order_data['revenue'],
                    'collected': input_data['collected'],
                    'expenses': outputs,
                    'profit': input_data['collected'] - outputs,
                    'orders': order_data['count'],
                })
        
        # ============================================
        #  10. ALERTS & WARNINGS
        # ============================================
        # Business health indicators - flags potential issues
        
        alerts = []
        
        # Alert 1: Low cash warning
        # Trigger: Cash in hand < 10,000 DA
        if cash_in_hand < Decimal('10000'):
            alerts.append({
                'type': 'warning',
                'category': 'cash_flow',
                'message': f'Low cash in hand: {cash_in_hand} DA',
            })
        
        # Alert 2: High outstanding debt
        # Trigger: Unpaid invoices > 30% of total revenue
        if total_revenue > 0 and total_outstanding > total_revenue * Decimal('0.3'):
            alerts.append({
                'type': 'warning',
                'category': 'payments',
                'message': f'High outstanding payments: {total_outstanding} DA ({round(total_outstanding/total_revenue*Decimal("100"), 2)}%)',
            })
        
        # Alert 3: Out of stock products
        # Trigger: Any products have 0 quantity
        if products_aggregate['out_of_stock'] > 0:
            alerts.append({
                'type': 'critical',
                'category': 'inventory',
                'message': f'{products_aggregate["out_of_stock"]} products are out of stock',
            })
        
        # Alert 4: Low stock products
        # Trigger: Any products have quantity < 10
        if products_aggregate['low_stock'] > 0:
            alerts.append({
                'type': 'warning',
                'category': 'inventory',
                'message': f'{products_aggregate["low_stock"]} products have low stock',
            })
        
        # Alert 5: Too many unpaid orders
        # Trigger: Unpaid orders > 20% of all orders
        if orders_aggregate['total_orders'] > 0 and orders_with_payments['unpaid'] > int(orders_aggregate['total_orders'] * 0.2):
            alerts.append({
                'type': 'warning',
                'category': 'orders',
                'message': f'{orders_with_payments["unpaid"]} orders are completely unpaid',
            })
        
        # Alert 6: Operating at a loss
        # Trigger: Net profit is negative
        if actual_profit < 0:
            alerts.append({
                'type': 'critical',
                'category': 'financial',
                'message': f'Business is operating at a loss: {actual_profit} DA',
            })
        
        # ============================================
        #  FINAL RESPONSE
        # ============================================
        
        dashboard_data = {
            'generated_at': timezone.now(),
            'period': period,
            'period_label': period_label,
            'financial_overview': financial_overview,
            'orders_analytics': orders_analytics,
            'client_analytics': client_analytics,
            'inventory_analytics': inventory_analytics,
            'trends': trends,
            'alerts': alerts,
        }
        
        return Response(dashboard_data, status=status.HTTP_200_OK)