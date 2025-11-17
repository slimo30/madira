import 'package:flutter/material.dart';
import '../models/input_model.dart';
import '../services/input_service.dart';

class InputProvider with ChangeNotifier {
  final InputService _inputService = InputService();

  // State variables
  List<InputModel> _inputs = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalCount = 0;
  final int _pageSize = 10;
  String? _nextPage;
  String? _previousPage;

  // Order-specific pagination
  List<InputModel> _orderInputs = [];
  int _orderCurrentPage = 1;
  int _orderTotalCount = 0;
  final int _orderPageSize = 10;
  String? _orderNextPage;
  String? _orderPreviousPage;

  // Filters
  String? _selectedType;
  int? _selectedOrderId;
  String _searchQuery = '';
  String? _ordering;

  // Getters
  List<InputModel> get inputs => _inputs;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get currentPage => _currentPage;
  int get totalCount => _totalCount;
  int get pageSize => _pageSize;
  int get totalPages => (_totalCount / _pageSize).ceil();
  bool get hasNextPage => _nextPage != null;
  bool get hasPreviousPage => _previousPage != null;
  String? get selectedType => _selectedType;
  int? get selectedOrderId => _selectedOrderId;
  String get searchQuery => _searchQuery;
  String? get ordering => _ordering;

  // Order-specific getters
  List<InputModel> get orderInputs => _orderInputs;
  int get orderCurrentPage => _orderCurrentPage;
  int get orderTotalCount => _orderTotalCount;
  int get orderPageSize => _orderPageSize;
  int get orderTotalPages => (_orderTotalCount / _orderPageSize).ceil();
  bool get orderHasNextPage => _orderNextPage != null;
  bool get orderHasPreviousPage => _orderPreviousPage != null;

  // Fetch inputs with filters and pagination
  Future<void> fetchInputs({
    int page = 1,
    String? type,
    int? orderId,
    String? search,
    String? ordering,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Update internal state to match the parameters
      // This ensures consistency when navigating pages
      _selectedType = type;
      _selectedOrderId = orderId;
      _searchQuery = search ?? '';
      _ordering = ordering;

      final result = await _inputService.getInputs(
        page: page,
        pageSize: _pageSize,
        type: _selectedType,
        orderId: _selectedOrderId,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        ordering: _ordering,
      );

      _inputs = result['results'] as List<InputModel>;
      _totalCount = result['count'] as int;
      _nextPage = result['next'] as String?;
      _previousPage = result['previous'] as String?;
      _currentPage = page;

      print('✅ InputProvider: Loaded ${_inputs.length} inputs');
      print('📊 Total count: $_totalCount, Page: $_currentPage/$totalPages');
      print(
        '🔍 Active filters - Type: $_selectedType, Order: $_selectedOrderId, Search: "$_searchQuery", Sort: $_ordering',
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      print('❌ InputProvider Error: $e');
      notifyListeners();
    }
  }

  // Fetch inputs by order ID
  Future<void> fetchInputsByOrder(int orderId, {int page = 1}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _inputService.getInputsByOrder(
        orderId,
        page: page,
        pageSize: _orderPageSize,
      );

      _orderInputs = result['results'] as List<InputModel>;
      _orderTotalCount = result['count'] as int;
      _orderNextPage = result['next'] as String?;
      _orderPreviousPage = result['previous'] as String?;
      _orderCurrentPage = page;
      _selectedOrderId = orderId;

      print(
        '✅ InputProvider: Loaded ${_orderInputs.length} inputs for order $orderId',
      );
      print(
        '📊 Total count: $_orderTotalCount, Page: $_orderCurrentPage/$orderTotalPages',
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      print('❌ InputProvider Error: $e');
      notifyListeners();
    }
  }

  // Navigate to next order page
  Future<void> nextOrderPage(int orderId) async {
    if (orderHasNextPage && _orderCurrentPage < orderTotalPages) {
      await fetchInputsByOrder(orderId, page: _orderCurrentPage + 1);
    }
  }

  // Navigate to previous order page
  Future<void> previousOrderPage(int orderId) async {
    if (orderHasPreviousPage && _orderCurrentPage > 1) {
      await fetchInputsByOrder(orderId, page: _orderCurrentPage - 1);
    }
  }

  // Create input
  Future<bool> createInput({
    required String type,
    required double amount,
    int? order,
    required String description,
  }) async {
    try {
      await _inputService.createInput(
        type: type,
        amount: amount,
        order: order,
        description: description,
      );

      print('✅ InputProvider: Input created successfully');

      // Refresh the order inputs list if we're viewing this order
      if (order != null && _selectedOrderId == order) {
        await fetchInputsByOrder(order, page: _orderCurrentPage);
      } else {
        // Refresh the general list
        await fetchInputs(
          page: _currentPage,
          type: _selectedType,
          orderId: _selectedOrderId,
          search: _searchQuery.isEmpty ? null : _searchQuery,
          ordering: _ordering,
        );
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ InputProvider Error: $e');
      notifyListeners();
      return false;
    }
  }

  // Update input
  Future<bool> updateInput(
    int inputId, {
    required String type,
    required double amount,
    int? order,
    required String description,
  }) async {
    try {
      await _inputService.updateInput(
        inputId,
        type: type,
        amount: amount,
        order: order,
        description: description,
      );

      print('✅ InputProvider: Input $inputId updated successfully');

      // Always refetch inputs after update
      await fetchInputs(
        page: _currentPage,
        type: _selectedType,
        orderId: _selectedOrderId,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        ordering: _ordering,
      );

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ InputProvider Error: $e');
      notifyListeners();
      return false;
    }
  }

  // Delete input
  Future<bool> deleteInput(int inputId, int? orderId) async {
    try {
      await _inputService.deleteInput(inputId);

      print('✅ InputProvider: Input $inputId deleted successfully');

      // Always refetch inputs after delete
      await fetchInputs(
        page: _currentPage,
        type: _selectedType,
        orderId: _selectedOrderId,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        ordering: _ordering,
      );

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ InputProvider Error: $e');
      notifyListeners();
      return false;
    }
  }

  // Apply filters
  void applyFilters({String? type, int? orderId, String? ordering}) {
    _selectedType = type;
    _selectedOrderId = orderId;
    _ordering = ordering;
    _currentPage = 1;

    fetchInputs(
      page: 1,
      type: type,
      orderId: orderId,
      search: _searchQuery.isEmpty ? null : _searchQuery,
      ordering: ordering,
    );
  }

  // Search inputs
  void searchInputs(String query) {
    _searchQuery = query;
    _currentPage = 1;

    fetchInputs(
      page: 1,
      type: _selectedType,
      orderId: _selectedOrderId,
      search: query.isEmpty ? null : query,
      ordering: _ordering,
    );
  }

  // Clear filters
  void clearFilters() {
    _selectedType = null;
    _selectedOrderId = null;
    _searchQuery = '';
    _ordering = null;
    _currentPage = 1;

    fetchInputs(page: 1);
  }

  // Pagination methods
  void nextPage() {
    if (hasNextPage && _currentPage < totalPages) {
      fetchInputs(
        page: _currentPage + 1,
        type: _selectedType,
        orderId: _selectedOrderId,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        ordering: _ordering,
      );
    }
  }

  void previousPage() {
    if (hasPreviousPage && _currentPage > 1) {
      fetchInputs(
        page: _currentPage - 1,
        type: _selectedType,
        orderId: _selectedOrderId,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        ordering: _ordering,
      );
    }
  }

  void goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      fetchInputs(
        page: page,
        type: _selectedType,
        orderId: _selectedOrderId,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        ordering: _ordering,
      );
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
