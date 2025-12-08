import 'package:flutter/material.dart';
import '../services/dashboard_service.dart';

class DashboardProvider with ChangeNotifier {
  final DashboardService _dashboardService = DashboardService();

  bool _isLoading = false;
  String? _error;
  Map<String, dynamic>? _dashboardData;
  String _selectedPeriod = 'all_time'; // Changed to String for API periods

  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic>? get dashboardData => _dashboardData;
  String get selectedPeriod => _selectedPeriod;
  String get periodLabel => _dashboardData?['period_label'] ?? 'All Time';

  // Financial Overview Getters
  Map<String, dynamic>? get financialOverview =>
      _dashboardData?['financial_overview'];

  double get totalRevenue =>
      (financialOverview?['total_revenue'] ?? 0.0).toDouble();
  double get totalCollected =>
      (financialOverview?['total_collected'] ?? 0.0).toDouble();
  double get totalOutstanding =>
      (financialOverview?['total_outstanding'] ?? 0.0).toDouble();
  double get collectionRate =>
      (financialOverview?['collection_rate'] ?? 0.0).toDouble();
  double get totalExpenses =>
      (financialOverview?['total_expenses'] ?? 0.0).toDouble();
  double get actualProfit =>
      (financialOverview?['actual_profit'] ?? 0.0).toDouble();
  double get expectedProfit =>
      (financialOverview?['expected_profit'] ?? 0.0).toDouble();
  double get actualProfitMargin =>
      (financialOverview?['actual_profit_margin'] ?? 0.0).toDouble();
  double get expectedProfitMargin =>
      (financialOverview?['expected_profit_margin'] ?? 0.0).toDouble();
  double get cashInHand =>
      (financialOverview?['cash_in_hand'] ?? 0.0).toDouble();

  Map<String, dynamic>? get expenseBreakdown =>
      financialOverview?['expense_breakdown'];

  // Orders Analytics Getters
  Map<String, dynamic>? get ordersAnalytics =>
      _dashboardData?['orders_analytics'];

  int get totalOrders => ordersAnalytics?['total_orders'] ?? 0;
  int get completedOrders => ordersAnalytics?['completed'] ?? 0;
  int get inProgressOrders => ordersAnalytics?['in_progress'] ?? 0;
  int get pendingOrders => ordersAnalytics?['pending'] ?? 0;
  int get fullyPaidOrders => ordersAnalytics?['fully_paid'] ?? 0;
  int get partiallyPaidOrders => ordersAnalytics?['partially_paid'] ?? 0;
  int get unpaidOrders => ordersAnalytics?['unpaid'] ?? 0;
  double get averageOrderValue =>
      (ordersAnalytics?['average_order_value'] ?? 0.0).toDouble();

  // Client Analytics Getters
  Map<String, dynamic>? get clientAnalytics =>
      _dashboardData?['client_analytics'];

  int get totalClients => clientAnalytics?['total_clients'] ?? 0;
  List<dynamic> get topClients => clientAnalytics?['top_clients'] ?? [];
  List<dynamic> get topDebtors => clientAnalytics?['top_debtors'] ?? [];

  // Inventory Analytics Getters
  Map<String, dynamic>? get inventoryAnalytics =>
      _dashboardData?['inventory_analytics'];

  int get totalProducts => inventoryAnalytics?['total_products'] ?? 0;
  int get outOfStockCount => inventoryAnalytics?['out_of_stock'] ?? 0;
  int get lowStockCount => inventoryAnalytics?['low_stock'] ?? 0;
  List<dynamic> get lowStockItems =>
      inventoryAnalytics?['low_stock_items'] ?? [];
  double get totalStockValue =>
      (inventoryAnalytics?['total_stock_value'] ?? 0.0).toDouble();

  // Trends Getters
  List<dynamic> get trends => _dashboardData?['trends'] ?? [];

  // Alerts Getters
  List<dynamic> get alerts => _dashboardData?['alerts'] ?? [];
  List<dynamic> get criticalAlerts =>
      alerts.where((a) => a['type'] == 'critical').toList();
  List<dynamic> get warningAlerts =>
      alerts.where((a) => a['type'] == 'warning').toList();

  Future<void> fetchDashboardData({String? period}) async {
    print(' DashboardProvider: Starting to fetch dashboard data...');

    if (period != null) {
      _selectedPeriod = period;
    }

    _isLoading = true;
    _error = null;
    notifyListeners();
    print(' DashboardProvider: Set loading to true, notified listeners');

    try {
      print(
        ' DashboardProvider: Calling DashboardService.getDashboardData(period: $_selectedPeriod)',
      );
      _dashboardData = await _dashboardService.getDashboardData(
        period: _selectedPeriod,
      );
      print(' DashboardProvider: Dashboard data received successfully');
      print(' Generated at: ${_dashboardData?['generated_at']}');
      print(' Period: ${_dashboardData?['period_label']}');
    } catch (e) {
      print(' DashboardProvider: Failed to fetch dashboard data: $e');
      _error = _extractErrorMessage(e);
      _dashboardData = null;
    } finally {
      _isLoading = false;
      print(' DashboardProvider: Set loading to false');
      notifyListeners();
      print(' DashboardProvider: Final notification sent to listeners');
    }
  }

  void changePeriod(String period) {
    if (_selectedPeriod != period) {
      _selectedPeriod = period;
      fetchDashboardData(period: period);
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _extractErrorMessage(dynamic error) {
    String errorString = error.toString();

    if (errorString.startsWith('Exception: ') &&
        !errorString.toLowerCase().contains('dioexception')) {
      return errorString.replaceFirst('Exception: ', '');
    }

    return 'Failed to load dashboard data. Please try again.';
  }
}
