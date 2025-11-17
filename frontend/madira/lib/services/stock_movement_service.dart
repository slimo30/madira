import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/constants/api_constants.dart';
import '../models/stock_movement_model.dart';

class StockMovementService {
  final _dio = DioClient().dio;

  // Get stock movements by product
  Future<StockMovementsByProductResponse> getMovementsByProduct(
    int productId,
  ) async {
    try {
      print('\n' + '=' * 60);
      print('🌐 API REQUEST: GET /stock-movements/by_product/');
      print('📍 Product ID: $productId');
      print('=' * 60);

      final response = await _dio.get(
        ApiConstants.stockMovementsByProduct,
        queryParameters: {'product_id': productId},
      );

      print('\n' + '=' * 60);
      print('✅ API RESPONSE: SUCCESS');
      print('📊 Status Code: ${response.statusCode}');
      print('=' * 60 + '\n');

      if (response.statusCode == 200) {
        return StockMovementsByProductResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      throw Exception('Failed to fetch stock movements');
    } on DioException catch (e) {
      print('\n' + '=' * 60);
      print('❌ API ERROR: DioException');
      print('⚠️ Message: ${e.message}');
      print('📊 Status Code: ${e.response?.statusCode}');
      print('=' * 60 + '\n');
      throw Exception('Error fetching stock movements: ${e.message}');
    } catch (e) {
      print('\n' + '=' * 60);
      print('❌ API ERROR: Generic Exception');
      print('⚠️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error fetching stock movements: $e');
    }
  }

  // Create stock movement (OUT movement)
  Future<StockMovementModel> createMovement({
    required int productId,
    required int orderId,
    required double quantity,
  }) async {
    try {
      final data = {
        'product': productId,
        'order': orderId,
        'quantity': quantity,
      };

      print('\n' + '=' * 60);
      print('🌐 API REQUEST: POST /stock-movements/');
      print('📦 Request Data:');
      print('   - Product: $productId');
      print('   - Order: $orderId');
      print('   - Quantity: $quantity');
      print('=' * 60);

      final response = await _dio.post(ApiConstants.stockMovements, data: data);

      print('\n' + '=' * 60);
      print('✅ API RESPONSE: SUCCESS');
      print('📊 Status Code: ${response.statusCode}');
      print('=' * 60 + '\n');

      if (response.statusCode == 201 || response.statusCode == 200) {
        return StockMovementModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      throw Exception('Failed to create stock movement');
    } on DioException catch (e) {
      print('\n' + '=' * 60);
      print('❌ API ERROR: DioException');
      print('⚠️ Message: ${e.message}');
      print('📊 Status Code: ${e.response?.statusCode}');
      print('📝 Response: ${e.response?.data}');
      print('=' * 60 + '\n');
      if (e.response?.statusCode == 400) {
        final errorDetail =
            e.response?.data['detail'] ??
            e.response?.data['error'] ??
            'Invalid movement data';
        throw Exception(errorDetail);
      }
      throw Exception('Error creating stock movement: ${e.message}');
    } catch (e) {
      print('\n' + '=' * 60);
      print('❌ API ERROR: Generic Exception');
      print('⚠️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error creating stock movement: $e');
    }
  }

  // Update stock movement
  Future<StockMovementModel> updateMovement(
    int movementId, {
    required int productId,
    required int orderId,
    required double quantity,
  }) async {
    try {
      final endpoint = '${ApiConstants.stockMovements}$movementId/';
      final data = {
        'product': productId,
        'order': orderId,
        'quantity': quantity,
      };

      print('\n' + '=' * 60);
      print('🌐 API REQUEST: PUT /stock-movements/$movementId/');
      print('📦 Request Data:');
      print('   - Product: $productId');
      print('   - Order: $orderId');
      print('   - Quantity: $quantity');
      print('=' * 60);

      final response = await _dio.put(endpoint, data: data);

      print('\n' + '=' * 60);
      print('✅ API RESPONSE: SUCCESS');
      print('📊 Status Code: ${response.statusCode}');
      print('=' * 60 + '\n');

      if (response.statusCode == 200) {
        return StockMovementModel.fromJson(
          response.data as Map<String, dynamic>,
        );
      }
      throw Exception('Failed to update stock movement');
    } on DioException catch (e) {
      print('\n' + '=' * 60);
      print('❌ API ERROR: DioException');
      print('⚠️ Message: ${e.message}');
      print('=' * 60 + '\n');
      throw Exception('Error updating stock movement: ${e.message}');
    } catch (e) {
      print('\n' + '=' * 60);
      print('❌ API ERROR: Generic Exception');
      print('⚠️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error updating stock movement: $e');
    }
  }

  // Delete stock movement
  Future<void> deleteMovement(int movementId) async {
    try {
      final endpoint = '${ApiConstants.stockMovements}$movementId/';
      print('\n' + '=' * 60);
      print('🌐 API REQUEST: DELETE /stock-movements/$movementId/');
      print('=' * 60);

      final response = await _dio.delete(endpoint);

      print('\n' + '=' * 60);
      print('✅ API RESPONSE: SUCCESS');
      print('📊 Status Code: ${response.statusCode}');
      print('   ✓ Movement $movementId deleted successfully');
      print('=' * 60 + '\n');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete stock movement');
      }
    } on DioException catch (e) {
      print('\n' + '=' * 60);
      print('❌ API ERROR: DioException');
      print('⚠️ Message: ${e.message}');
      print('=' * 60 + '\n');
      throw Exception('Error deleting stock movement: ${e.message}');
    } catch (e) {
      print('\n' + '=' * 60);
      print('❌ API ERROR: Generic Exception');
      print('⚠️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error deleting stock movement: $e');
    }
  }
}
