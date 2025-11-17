import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../services/order_service.dart';

class OrderProvider with ChangeNotifier {
  final OrderService _orderService = OrderService();

  List<OrderModel> _orders = [];
  bool _isLoading = false;
  String? _error;
  bool _isFetching = false;

  // Pagination properties
  int _currentPage = 1;
  int _pageSize = 10;
  int _totalCount = 0;
  String? _nextPage;
  String? _previousPage;

  // Search and ordering
  String _searchQuery = '';
  String _ordering = '-created_at';

  // Filters
  String? _statusFilter;
  String? _paymentStatusFilter;
  int? _clientFilter;

  // Getters
  List<OrderModel> get orders => _orders;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get pageSize => _pageSize;
  int get totalCount => _totalCount;
  int get totalPages => (_totalCount / _pageSize).ceil();
  bool get hasNextPage => _nextPage != null;
  bool get hasPreviousPage => _previousPage != null;
  String get searchQuery => _searchQuery;
  String get ordering => _ordering;
  String? get statusFilter => _statusFilter;
  String? get paymentStatusFilter => _paymentStatusFilter;
  int? get clientFilter => _clientFilter;

  // Fetch orders with pagination, search, and filters
  Future<void> fetchOrders({
    int? page,
    String? search,
    String? ordering,
    String? status,
    String? paymentStatus,
    int? clientId,
  }) async {
    if (_isFetching) {
      print(
        '⚠️ OrderProvider: Fetch already in progress, skipping duplicate request',
      );
      return;
    }

    _isFetching = true;
    _isLoading = true;
    _error = null;

    // Update search and ordering if provided
    if (search != null) _searchQuery = search;
    if (ordering != null) _ordering = ordering;
    if (page != null) _currentPage = page;

    // Always update filters, even if null (to clear them when "all" is selected)
    _statusFilter = status;
    _paymentStatusFilter = paymentStatus;
    _clientFilter = clientId;

    notifyListeners();

    try {
      final response = await _orderService.getOrders(
        page: _currentPage,
        pageSize: _pageSize,
        search: _searchQuery,
        ordering: _ordering,
        status: _statusFilter,
        paymentStatus: _paymentStatusFilter,
        clientId: _clientFilter,
      );

      _orders = response['results'] as List<OrderModel>;
      _totalCount = response['count'] as int;
      _nextPage = response['next'] as String?;
      _previousPage = response['previous'] as String?;

      print('✅ OrderProvider: Fetched ${_orders.length} orders successfully');
      print('📊 Total count: $_totalCount, Page: $_currentPage/$totalPages');
    } catch (e) {
      _error = e.toString();
      print('❌ OrderProvider: Error fetching orders: $e');
    } finally {
      _isLoading = false;
      _isFetching = false;
      notifyListeners();
    }
  }

  // Navigate to next page
  Future<void> nextPage() async {
    if (hasNextPage && _currentPage < totalPages) {
      await fetchOrders(page: _currentPage + 1);
    }
  }

  // Navigate to previous page
  Future<void> previousPage() async {
    if (hasPreviousPage && _currentPage > 1) {
      await fetchOrders(page: _currentPage - 1);
    }
  }

  // Go to specific page
  Future<void> goToPage(int page) async {
    if (page > 0 && page <= totalPages) {
      await fetchOrders(page: page);
    }
  }

  // Search orders
  Future<void> searchOrders(String query) async {
    _searchQuery = query;
    _currentPage = 1; // Reset to first page on new search
    await fetchOrders();
  }

  // Update ordering
  Future<void> updateOrdering(String newOrdering) async {
    _ordering = newOrdering;
    _currentPage = 1; // Reset to first page
    await fetchOrders();
  }

  // Update filters
  Future<void> updateFilters({
    String? status,
    String? paymentStatus,
    int? clientId,
  }) async {
    _statusFilter = status;
    _paymentStatusFilter = paymentStatus;
    _clientFilter = clientId;
    _currentPage = 1; // Reset to first page
    await fetchOrders();
  }

  // Clear all filters
  Future<void> clearFilters() async {
    _statusFilter = null;
    _paymentStatusFilter = null;
    _clientFilter = null;
    _searchQuery = '';
    _currentPage = 1;
    await fetchOrders();
  }

  // Create new order
  Future<void> createOrder({
    required int client,
    required String totalAmount,
    required String description,
    required String deliveryDate,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print('📝 OrderProvider: Creating order for client: $client');
      await _orderService.createOrder(
        client: client,
        totalAmount: totalAmount,
        description: description,
        deliveryDate: deliveryDate,
      );

      // Refresh orders list
      print('🔄 OrderProvider: Refreshing orders list');
      await fetchOrders();
      print('✅ OrderProvider: Order created and list refreshed');
    } catch (e) {
      _error = e.toString();
      print('❌ OrderProvider: Error creating order: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update order
  Future<void> updateOrder(
    int orderId, {
    required int client,
    required String totalAmount,
    required String description,
    required String deliveryDate,
    required String status,
  }) async {
    try {
      print('🔄 OrderProvider: Updating order $orderId');
      final updatedOrder = await _orderService.updateOrder(
        orderId,
        client: client,
        totalAmount: totalAmount,
        description: description,
        deliveryDate: deliveryDate,
        status: status,
      );

      // Update in local list
      final index = _orders.indexWhere((o) => o.id == orderId);
      if (index != -1) {
        _orders[index] = updatedOrder;
        print('✅ OrderProvider: Order $orderId updated locally');
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print('❌ OrderProvider: Error updating order: $e');
      rethrow;
    }
  }

  // Cancel order
  Future<void> cancelOrder(int orderId) async {
    try {
      print('🔄 OrderProvider: Cancelling order $orderId');
      await _orderService.deleteOrder(orderId);

      // Refresh the orders data
      await fetchOrders();
      print('✅ OrderProvider: Order $orderId cancelled and list refreshed');
    } catch (e) {
      _error = e.toString();
      print('❌ OrderProvider: Error cancelling order: $e');
      rethrow;
    }
  }

  // Get client orders
  Future<List<OrderModel>> getClientOrders(int clientId) async {
    try {
      print('🔄 OrderProvider: Fetching orders for client $clientId');
      final response = await _orderService.getClientOrders(clientId: clientId);
      final orders = response['results'] as List<OrderModel>;
      print('✅ OrderProvider: Fetched ${orders.length} orders for client');
      return orders;
    } catch (e) {
      _error = e.toString();
      print('❌ OrderProvider: Error fetching client orders: $e');
      rethrow;
    }
  }

  // Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Reset pagination
  void resetPagination() {
    _currentPage = 1;
    _searchQuery = '';
    _ordering = '-created_at';
    _statusFilter = null;
    _paymentStatusFilter = null;
    _clientFilter = null;
    notifyListeners();
  }
}
