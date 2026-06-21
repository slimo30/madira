import 'package:flutter/material.dart';
import '../models/supplier_model.dart';
import '../services/supplier_service.dart';

class SupplierProvider with ChangeNotifier {
  final SupplierService _supplierService = SupplierService();

  List<SupplierModel> _suppliers = [];
  bool _isLoading = false;
  String? _error;
  bool _isFetching = false;

  // Pagination properties
  int _currentPage = 1;
  final int _pageSize = 10;
  int _totalCount = 0;
  String? _nextPage;
  String? _previousPage;

  // Search and ordering
  String _searchQuery = '';
  String _ordering = '-created_at';

  // Getters
  List<SupplierModel> get suppliers => _suppliers;
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

  // Fetch suppliers with pagination and search
  Future<void> fetchSuppliers({
    int? page,
    String? search,
    String? ordering,
  }) async {
    if (_isFetching) {
      print(
        '️ SupplierProvider: Fetch already in progress, skipping duplicate request',
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

    notifyListeners();

    try {
      final response = await _supplierService.getSuppliers(
        page: _currentPage,
        pageSize: _pageSize,
        search: _searchQuery,
        ordering: _ordering,
      );

      _suppliers = response['results'] as List<SupplierModel>;
      _totalCount = response['count'] as int;
      _nextPage = response['next'] as String?;
      _previousPage = response['previous'] as String?;

      print(
        ' SupplierProvider: Fetched ${_suppliers.length} suppliers successfully',
      );
      print(' Total count: $_totalCount, Page: $_currentPage/$totalPages');
    } catch (e) {
      _error = e.toString();
      print(' SupplierProvider: Error fetching suppliers: $e');
    } finally {
      _isLoading = false;
      _isFetching = false;
      notifyListeners();
    }
  }

  // Navigate to next page
  Future<void> nextPage() async {
    if (hasNextPage && _currentPage < totalPages) {
      await fetchSuppliers(page: _currentPage + 1);
    }
  }

  // Navigate to previous page
  Future<void> previousPage() async {
    if (hasPreviousPage && _currentPage > 1) {
      await fetchSuppliers(page: _currentPage - 1);
    }
  }

  // Go to specific page
  Future<void> goToPage(int page) async {
    if (page > 0 && page <= totalPages) {
      await fetchSuppliers(page: page);
    }
  }

  // Search suppliers
  Future<void> searchSuppliers(String query) async {
    _searchQuery = query;
    _currentPage = 1; // Reset to first page on new search
    await fetchSuppliers();
  }

  // Update ordering
  Future<void> updateOrdering(String newOrdering) async {
    _ordering = newOrdering;
    _currentPage = 1; // Reset to first page
    await fetchSuppliers();
  }

  // Create new supplier
  Future<void> createSupplier({
    required String name,
    required String phone,
    required String address,
    required String notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      print(' SupplierProvider: Creating supplier: $name');
      await _supplierService.createSupplier(
        name: name,
        phone: phone,
        address: address,
        notes: notes,
      );

      // Refresh suppliers list
      print(' SupplierProvider: Refreshing suppliers list');
      _currentPage = 1; // Reset to first page
      _ordering = '-created_at'; // Force sort by newest
      await fetchSuppliers();
      print(' SupplierProvider: Supplier created and list refreshed');
    } catch (e) {
      _error = e.toString();
      print(' SupplierProvider: Error creating supplier: $e');
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Update supplier
  Future<void> updateSupplier(
    int supplierId, {
    required String name,
    required String phone,
    required String address,
    required String notes,
    required bool isActive,
  }) async {
    try {
      print(' SupplierProvider: Updating supplier $supplierId');
      final updatedSupplier = await _supplierService.updateSupplier(
        supplierId,
        name: name,
        phone: phone,
        address: address,
        notes: notes,
        isActive: isActive,
      );

      // Update in local list
      final index = _suppliers.indexWhere((s) => s.id == supplierId);
      if (index != -1) {
        _suppliers[index] = updatedSupplier;
        print(' SupplierProvider: Supplier $supplierId updated locally');
      }
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      print(' SupplierProvider: Error updating supplier: $e');
      rethrow;
    }
  }

  // Deactivate supplier
  Future<void> deactivateSupplier(int supplierId) async {
    try {
      print(' SupplierProvider: Deactivating supplier $supplierId');
      await _supplierService.deleteSupplier(supplierId);

      // Refresh the supplier data
      await fetchSuppliers();
      print(
        ' SupplierProvider: Supplier $supplierId deactivated and list refreshed',
      );
    } catch (e) {
      _error = e.toString();
      print(' SupplierProvider: Error deactivating supplier: $e');
      rethrow;
    }
  }

  // Get supplier summary
  Future<Map<String, dynamic>> getSupplierSummary(int supplierId) async {
    try {
      print(' SupplierProvider: Fetching summary for supplier $supplierId');
      final summary = await _supplierService.getSupplierSummary(supplierId);
      print(' SupplierProvider: Summary fetched successfully');
      return summary;
    } catch (e) {
      print(' SupplierProvider: Error fetching supplier summary: $e');
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
    notifyListeners();
  }
}
