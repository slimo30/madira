// ✅ Output Provider
import 'package:flutter/material.dart';
import '../models/output_model.dart';
import '../services/output_service.dart';

class OutputProvider with ChangeNotifier {
  final OutputService _outputService = OutputService();

  // State variables
  List<OutputModel> _outputs = [];
  bool _isLoading = false;
  String? _errorMessage;
  int _currentPage = 1;
  int _totalCount = 0;
  final int _pageSize = 10;
  String? _nextPage;
  String? _previousPage;

  // Order-specific pagination
  List<OutputModel> _orderOutputs = [];
  int _orderCurrentPage = 1;
  int _orderTotalCount = 0;
  final int _orderPageSize = 10;
  String? _orderNextPage;
  String? _orderPreviousPage;

  // Input-specific pagination
  List<OutputModel> _inputOutputs = [];
  int _inputCurrentPage = 1;
  int _inputTotalCount = 0;
  final int _inputPageSize = 10;
  String? _inputNextPage;
  String? _inputPreviousPage;

  // Filters
  String? _selectedType;
  int? _selectedOrderId;
  int? _selectedInputId;
  String _searchQuery = '';

  // Statistics
  OutputStatistics? _statistics;

  // Getters
  List<OutputModel> get outputs => _outputs;
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
  int? get selectedInputId => _selectedInputId;
  String get searchQuery => _searchQuery;
  OutputStatistics? get statistics => _statistics;

  // Order-specific getters
  List<OutputModel> get orderOutputs => _orderOutputs;
  int get orderCurrentPage => _orderCurrentPage;
  int get orderTotalCount => _orderTotalCount;
  int get orderPageSize => _orderPageSize;
  int get orderTotalPages => (_orderTotalCount / _orderPageSize).ceil();
  bool get orderHasNextPage => _orderNextPage != null;
  bool get orderHasPreviousPage => _orderPreviousPage != null;

  // Input-specific getters
  List<OutputModel> get inputOutputs => _inputOutputs;
  int get inputCurrentPage => _inputCurrentPage;
  int get inputTotalCount => _inputTotalCount;
  int get inputPageSize => _inputPageSize;
  int get inputTotalPages => (_inputTotalCount / _inputPageSize).ceil();
  bool get inputHasNextPage => _inputNextPage != null;
  bool get inputHasPreviousPage => _inputPreviousPage != null;

  // Fetch outputs with filters and pagination
  Future<void> fetchOutputs({
    int page = 1,
    String? type,
    int? orderId,
    int? inputId,
    String? search,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _outputService.getOutputs(
        page: page,
        pageSize: _pageSize,
        type: type,
        orderId: orderId,
        inputId: inputId,
        search: search,
      );

      _outputs = result['results'] as List<OutputModel>;
      _totalCount = result['count'] as int;
      _nextPage = result['next'] as String?;
      _previousPage = result['previous'] as String?;
      _currentPage = page;

      print('✅ OutputProvider: Loaded ${_outputs.length} outputs');
      print('📊 Total count: $_totalCount, Page: $_currentPage/$totalPages');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      print('❌ OutputProvider Error: $e');
      notifyListeners();
    }
  }

  // Fetch outputs by order ID
  Future<void> fetchOutputsByOrder(int orderId, {int page = 1}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _outputService.getOutputsByOrder(
        orderId,
        page: page,
        pageSize: _orderPageSize,
      );

      _orderOutputs = result['results'] as List<OutputModel>;
      _orderTotalCount = result['count'] as int;
      _orderNextPage = result['next'] as String?;
      _orderPreviousPage = result['previous'] as String?;
      _orderCurrentPage = page;
      _selectedOrderId = orderId;

      print(
        '✅ OutputProvider: Loaded ${_orderOutputs.length} outputs for order $orderId',
      );
      print(
        '📊 Total count: $_orderTotalCount, Page: $_orderCurrentPage/$orderTotalPages',
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      print('❌ OutputProvider Error: $e');
      notifyListeners();
    }
  }

  // Fetch outputs by input ID
  Future<void> fetchOutputsByInput(
    int inputId, {
    int page = 1,
    int? pageSize,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final effectivePageSize = pageSize ?? _inputPageSize;

      final result = await _outputService.getOutputsByInput(
        inputId,
        page: page,
        pageSize: effectivePageSize,
      );

      _inputOutputs = result['results'] as List<OutputModel>;
      _inputTotalCount = result['count'] as int;
      _inputNextPage = result['next'] as String?;
      _inputPreviousPage = result['previous'] as String?;
      _inputCurrentPage = page;
      _selectedInputId = inputId;

      print(
        '✅ OutputProvider: Loaded ${_inputOutputs.length} outputs for input $inputId',
      );
      print(
        '📊 Total count: $_inputTotalCount, Page: $_inputCurrentPage (Page size: $effectivePageSize)',
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      print('❌ OutputProvider Error: $e');
      notifyListeners();
    }
  }

  // Fetch outputs by type
  Future<void> fetchOutputsByType(String type, {int page = 1}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _outputService.getOutputsByType(
        type,
        page: page,
        pageSize: _pageSize,
      );

      _outputs = result['results'] as List<OutputModel>;
      _totalCount = result['count'] as int;
      _nextPage = result['next'] as String?;
      _previousPage = result['previous'] as String?;
      _currentPage = page;
      _selectedType = type;

      print(
        '✅ OutputProvider: Loaded ${_outputs.length} outputs with type "$type"',
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      print('❌ OutputProvider Error: $e');
      notifyListeners();
    }
  }

  // Fetch statistics
  Future<void> fetchStatistics() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _statistics = await _outputService.getStatistics();

      print('✅ OutputProvider: Statistics loaded');
      print('📊 Total outputs: ${_statistics?.totalCount}');
      print('💰 Total amount: ${_statistics?.formattedTotalAmount} DA');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      print('❌ OutputProvider Error: $e');
      notifyListeners();
    }
  }

  // Get output by ID
  Future<OutputModel?> getOutputById(int outputId) async {
    try {
      final output = await _outputService.getOutputById(outputId);
      print('✅ OutputProvider: Retrieved output $outputId');
      return output;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ OutputProvider Error: $e');
      notifyListeners();
      return null;
    }
  }

  // Get related data
  Future<Map<String, dynamic>?> getRelatedData(int outputId) async {
    try {
      final data = await _outputService.getRelatedData(outputId);
      print('✅ OutputProvider: Retrieved related data for output $outputId');
      return data;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ OutputProvider Error: $e');
      notifyListeners();
      return null;
    }
  }

  // Create output
  Future<bool> createOutput(Map<String, dynamic> data) async {
    try {
      final output = await _outputService.createOutput(data);

      print('✅ OutputProvider: Output created successfully (ID: ${output.id})');

      // Refresh the appropriate list
      if (data['order'] != null && _selectedOrderId == data['order']) {
        await fetchOutputsByOrder(data['order'], page: _orderCurrentPage);
      } else if (data['source_input'] != null &&
          _selectedInputId == data['source_input']) {
        await fetchOutputsByInput(
          data['source_input'],
          page: _inputCurrentPage,
        );
      } else {
        await fetchOutputs(
          page: _currentPage,
          type: _selectedType,
          orderId: _selectedOrderId,
          inputId: _selectedInputId,
          search: _searchQuery.isEmpty ? null : _searchQuery,
        );
      }

      // Refresh statistics if loaded
      if (_statistics != null) {
        await fetchStatistics();
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ OutputProvider Error: $e');
      notifyListeners();
      return false;
    }
  }

  // Update output
  Future<bool> updateOutput(int outputId, Map<String, dynamic> data) async {
    try {
      await _outputService.updateOutput(outputId, data);

      print('✅ OutputProvider: Output $outputId updated successfully');

      // Always refetch outputs after update
      await fetchOutputs(
        page: _currentPage,
        type: _selectedType,
        orderId: _selectedOrderId,
        inputId: _selectedInputId,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );

      // Refresh statistics if loaded
      if (_statistics != null) {
        await fetchStatistics();
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ OutputProvider Error: $e');
      notifyListeners();
      return false;
    }
  }

  // Partial update output
  Future<bool> partialUpdateOutput(
    int outputId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _outputService.partialUpdateOutput(outputId, data);

      print('✅ OutputProvider: Output $outputId partially updated');

      // Refetch current list
      await fetchOutputs(
        page: _currentPage,
        type: _selectedType,
        orderId: _selectedOrderId,
        inputId: _selectedInputId,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ OutputProvider Error: $e');
      notifyListeners();
      return false;
    }
  }

  // Delete output
  Future<bool> deleteOutput(int outputId) async {
    try {
      await _outputService.deleteOutput(outputId);

      print('✅ OutputProvider: Output $outputId deleted successfully');

      // Always refetch outputs after delete
      await fetchOutputs(
        page: _currentPage,
        type: _selectedType,
        orderId: _selectedOrderId,
        inputId: _selectedInputId,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );

      // Refresh statistics if loaded
      if (_statistics != null) {
        await fetchStatistics();
      }

      return true;
    } catch (e) {
      _errorMessage = e.toString();
      print('❌ OutputProvider Error: $e');
      notifyListeners();
      return false;
    }
  }

  // Apply filters
  void applyFilters({String? type, int? orderId, int? inputId}) {
    _selectedType = type;
    _selectedOrderId = orderId;
    _selectedInputId = inputId;
    _currentPage = 1;

    fetchOutputs(
      page: 1,
      type: type,
      orderId: orderId,
      inputId: inputId,
      search: _searchQuery.isEmpty ? null : _searchQuery,
    );
  }

  // Search outputs
  void searchOutputs(String query) {
    _searchQuery = query;
    _currentPage = 1;

    fetchOutputs(
      page: 1,
      type: _selectedType,
      orderId: _selectedOrderId,
      inputId: _selectedInputId,
      search: query.isEmpty ? null : query,
    );
  }

  // Clear filters
  void clearFilters() {
    _selectedType = null;
    _selectedOrderId = null;
    _selectedInputId = null;
    _searchQuery = '';
    _currentPage = 1;

    fetchOutputs(page: 1);
  }

  // Pagination methods
  void nextPage() {
    if (hasNextPage && _currentPage < totalPages) {
      fetchOutputs(
        page: _currentPage + 1,
        type: _selectedType,
        orderId: _selectedOrderId,
        inputId: _selectedInputId,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
    }
  }

  void previousPage() {
    if (hasPreviousPage && _currentPage > 1) {
      fetchOutputs(
        page: _currentPage - 1,
        type: _selectedType,
        orderId: _selectedOrderId,
        inputId: _selectedInputId,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
    }
  }

  void goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      fetchOutputs(
        page: page,
        type: _selectedType,
        orderId: _selectedOrderId,
        inputId: _selectedInputId,
        search: _searchQuery.isEmpty ? null : _searchQuery,
      );
    }
  }

  // Navigate to next order page
  Future<void> nextOrderPage(int orderId) async {
    if (orderHasNextPage && _orderCurrentPage < orderTotalPages) {
      await fetchOutputsByOrder(orderId, page: _orderCurrentPage + 1);
    }
  }

  // Navigate to previous order page
  Future<void> previousOrderPage(int orderId) async {
    if (orderHasPreviousPage && _orderCurrentPage > 1) {
      await fetchOutputsByOrder(orderId, page: _orderCurrentPage - 1);
    }
  }

  // Navigate to next input page
  Future<void> nextInputPage(int inputId) async {
    if (inputHasNextPage && _inputCurrentPage < inputTotalPages) {
      await fetchOutputsByInput(inputId, page: _inputCurrentPage + 1);
    }
  }

  // Navigate to previous input page
  Future<void> previousInputPage(int inputId) async {
    if (inputHasPreviousPage && _inputCurrentPage > 1) {
      await fetchOutputsByInput(inputId, page: _inputCurrentPage - 1);
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Get error message (useful for displaying in UI)
  String? get error => _errorMessage;
}
