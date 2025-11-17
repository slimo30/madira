import 'package:flutter/material.dart';
import '../models/stock_movement_model.dart';
import '../services/stock_movement_service.dart';

class StockMovementProvider with ChangeNotifier {
  final StockMovementService _stockMovementService = StockMovementService();

  // State variables
  ProductStockSummary? _productSummary;
  List<StockMovementModel> _movements = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  ProductStockSummary? get productSummary => _productSummary;
  List<StockMovementModel> get movements => _movements;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Fetch movements by product
  Future<void> fetchMovementsByProduct(int productId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _stockMovementService.getMovementsByProduct(
        productId,
      );

      _productSummary = response.product;
      _movements = response.movements;

      print('✅ StockMovementProvider: Loaded ${_movements.length} movements');
      print('📊 Product: ${_productSummary?.name}');
      print('📊 Current Stock: ${_productSummary?.formattedCurrentQuantity}');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      print('❌ StockMovementProvider Error: $e');
      notifyListeners();
    }
  }

  // Create stock movement (OUT movement)
  Future<bool> createMovement({
    required int productId,
    required int orderId,
    required double quantity,
  }) async {
    try {
      await _stockMovementService.createMovement(
        productId: productId,
        orderId: orderId,
        quantity: quantity,
      );

      print('✅ StockMovementProvider: Movement created successfully');

      // Refresh the movements list
      await fetchMovementsByProduct(productId);

      return true;
    } catch (e) {
      _error = e.toString();
      print('❌ StockMovementProvider Error: $e');
      notifyListeners();
      return false;
    }
  }

  // Update stock movement
  Future<bool> updateMovement(
    int movementId, {
    required int productId,
    required int orderId,
    required double quantity,
  }) async {
    try {
      await _stockMovementService.updateMovement(
        movementId,
        productId: productId,
        orderId: orderId,
        quantity: quantity,
      );

      print('✅ StockMovementProvider: Movement $movementId updated');

      // Refresh the movements list
      await fetchMovementsByProduct(productId);

      return true;
    } catch (e) {
      _error = e.toString();
      print('❌ StockMovementProvider Error: $e');
      notifyListeners();
      return false;
    }
  }

  // Delete stock movement
  Future<bool> deleteMovement(int movementId, int productId) async {
    try {
      await _stockMovementService.deleteMovement(movementId);

      print('✅ StockMovementProvider: Movement $movementId deleted');

      // Refresh the movements list
      await fetchMovementsByProduct(productId);

      return true;
    } catch (e) {
      _error = e.toString();
      print('❌ StockMovementProvider Error: $e');
      notifyListeners();
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  // Clear data
  void clear() {
    _productSummary = null;
    _movements = [];
    _error = null;
    notifyListeners();
  }
}
