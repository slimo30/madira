import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/product_service.dart';

class ProductProvider with ChangeNotifier {
  final ProductService _productService = ProductService();

  // State variables
  List<ProductModel> _products = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalCount = 0;
  final int _pageSize = 10;
  String? _nextPage;
  String? _previousPage;

  // Filters
  String _searchQuery = '';
  String? _unitFilter;
  String? _ordering = '-created_at'; // Default to newest first

  // Getters
  List<ProductModel> get products => _products;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalCount => _totalCount;
  int get pageSize => _pageSize;
  int get totalPages => (_totalCount / _pageSize).ceil();
  bool get hasNextPage => _nextPage != null;
  bool get hasPreviousPage => _previousPage != null;
  String get searchQuery => _searchQuery;
  String? get unitFilter => _unitFilter;
  String? get ordering => _ordering;

  // Fetch products with filters and pagination
  Future<void> fetchProducts({
    int? page,
    String? search,
    String? unit,
    String? ordering,
  }) async {
    _isLoading = true;
    _error = null;

    // Update filter state - always update to support clearing filters
    if (page != null) _currentPage = page;
    if (search != null) _searchQuery = search;
    _unitFilter = unit; // Always update, even if null
    _ordering = ordering; // Always update, even if null

    notifyListeners();

    try {
      final result = await _productService.getProducts(
        page: _currentPage,
        pageSize: _pageSize,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        isActive: true, // Always fetch only active products
        unit: _unitFilter,
        ordering: _ordering,
      );

      _products = result['results'] as List<ProductModel>;
      _totalCount = result['count'] as int;
      _nextPage = result['next'] as String?;
      _previousPage = result['previous'] as String?;

      print(' ProductProvider: Loaded ${_products.length} products');
      print(' Total count: $_totalCount, Page: $_currentPage/$totalPages');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      print(' ProductProvider Error: $e');
      notifyListeners();
    }
  }

  // Create product
  Future<bool> createProduct({
    required String name,
    required String unit,
    required double currentQuantity,
    required String description,
    double? initialPrice,
  }) async {
    try {
      await _productService.createProduct(
        name: name,
        unit: unit,
        currentQuantity: currentQuantity,
        description: description,
        initialPrice: initialPrice,
      );

      print(' ProductProvider: Product created successfully');

      // Refresh the list - go to page 1 to see the new product (newest first)
      await fetchProducts(
        page: 1,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        unit: _unitFilter,
        ordering: _ordering,
      );

      return true;
    } catch (e) {
      _error = e.toString();
      print(' ProductProvider Error: $e');
      notifyListeners();
      return false;
    }
  }

  // Update product
  Future<bool> updateProduct(
    int productId, {
    required String name,
    required String unit,
    required double currentQuantity,
    required String description,
    required bool isActive,
  }) async {
    try {
      await _productService.updateProduct(
        productId,
        name: name,
        unit: unit,
        currentQuantity: currentQuantity,
        description: description,
        isActive: isActive,
      );

      print(' ProductProvider: Product $productId updated successfully');

      // Refresh the list
      await fetchProducts(
        page: _currentPage,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        unit: _unitFilter,
        ordering: _ordering,
      );

      return true;
    } catch (e) {
      _error = e.toString();
      print(' ProductProvider Error: $e');
      notifyListeners();
      return false;
    }
  }

  // Delete product
  Future<bool> deleteProduct(int productId) async {
    try {
      await _productService.deleteProduct(productId);

      print(' ProductProvider: Product $productId deleted successfully');

      // Refresh the list
      await fetchProducts(
        page: _currentPage,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        unit: _unitFilter,
        ordering: _ordering,
      );

      return true;
    } catch (e) {
      _error = e.toString();
      print(' ProductProvider Error: $e');
      notifyListeners();
      return false;
    }
  }

  // Deactivate product
  Future<bool> deactivateProduct(int productId) async {
    try {
      await _productService.deactivateProduct(productId);

      print(' ProductProvider: Product $productId deactivated successfully');

      // Refresh the list
      await fetchProducts(
        page: _currentPage,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        unit: _unitFilter,
        ordering: _ordering,
      );

      return true;
    } catch (e) {
      _error = e.toString();
      print(' ProductProvider Error: $e');
      notifyListeners();
      return false;
    }
  }

  // Reactivate product
  Future<bool> reactivateProduct(int productId) async {
    try {
      await _productService.reactivateProduct(productId);

      print(' ProductProvider: Product $productId reactivated successfully');

      // Refresh the list
      await fetchProducts(
        page: _currentPage,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        unit: _unitFilter,
        ordering: _ordering,
      );

      return true;
    } catch (e) {
      _error = e.toString();
      print(' ProductProvider Error: $e');
      notifyListeners();
      return false;
    }
  }

  // Apply filters
  void applyFilters({String? search, String? unit, String? ordering}) {
    _searchQuery = search ?? '';
    _unitFilter = unit;
    _ordering = ordering ?? '-created_at';
    _currentPage = 1;

    fetchProducts(
      page: 1,
      search: _searchQuery.isEmpty ? null : _searchQuery,
      unit: _unitFilter,
      ordering: _ordering,
    );
  }

  // Search products
  void searchProducts(String query) {
    _searchQuery = query;
    _currentPage = 1;

    fetchProducts(
      page: 1,
      search: query.isEmpty ? null : query,
      unit: _unitFilter,
      ordering: _ordering,
    );
  }

  // Clear filters
  void clearFilters() {
    _searchQuery = '';
    _unitFilter = null;
    _ordering = '-created_at';
    _currentPage = 1;

    fetchProducts(page: 1, ordering: _ordering);
  }

  // Pagination methods
  void nextPage() {
    if (hasNextPage && _currentPage < totalPages) {
      fetchProducts(
        page: _currentPage + 1,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        unit: _unitFilter,
        ordering: _ordering,
      );
    }
  }

  void previousPage() {
    if (hasPreviousPage && _currentPage > 1) {
      fetchProducts(
        page: _currentPage - 1,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        unit: _unitFilter,
        ordering: _ordering,
      );
    }
  }

  void goToPage(int page) {
    if (page >= 1 && page <= totalPages) {
      fetchProducts(
        page: page,
        search: _searchQuery.isEmpty ? null : _searchQuery,
        unit: _unitFilter,
        ordering: _ordering,
      );
    }
  }

  // Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
