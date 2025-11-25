import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/constants/api_constants.dart';
import '../models/order_model.dart';

class OrderService {
  final _dio = DioClient().dio;

  // Get all orders with pagination and search
  Future<Map<String, dynamic>> getOrders({
    int page = 1,
    int pageSize = 10,
    String search = '',
    String ordering = '-created_at',
    String? status,
    String? paymentStatus,
    int? clientId,
  }) async {
    try {
      
      print('🌐 API REQUEST: GET /orders/');
      print('📍 Full URL: ${ApiConstants.baseUrl}/orders/');
      print('📊 Pagination: page=$page, pageSize=$pageSize');
      if (search.isNotEmpty) print('🔍 Search: $search');
      print('📋 Ordering: $ordering');
      if (status != null) print('📌 Status Filter: $status');
      if (paymentStatus != null) print('💰 Payment Filter: $paymentStatus');
      if (clientId != null) print('👤 Client Filter: $clientId');
      print('=' * 60);

      final queryParams = {
        'page': page,
        'page_size': pageSize,
        if (search.isNotEmpty) 'search': search,
        if (ordering.isNotEmpty) 'ordering': ordering,
        if (status != null && status.isNotEmpty) 'status': status,
        if (paymentStatus != null && paymentStatus.isNotEmpty)
          'payment_status': paymentStatus,
        if (clientId != null) 'client': clientId,
      };

      final response = await _dio.get('/orders/', queryParameters: queryParams);

      
      print('✅ API RESPONSE: SUCCESS');
      print('📊 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final orders =
            (data['results'] as List?)
                ?.map(
                  (item) => OrderModel.fromJson(item as Map<String, dynamic>),
                )
                .toList() ??
            [];

        print('📦 Number of Orders: ${orders.length}');
        print('📈 Total Count: ${data['count']}');
        print('=' * 60 + '\n');

        for (var order in orders) {
          print(
            '   ✓ Order: ${order.orderNumber} - Client: ${order.clientName} - Status: ${order.statusDisplay} - Amount: ${order.totalAmount} DA',
          );
        }

        return {
          'count': data['count'] as int? ?? 0,
          'next': data['next'] as String?,
          'previous': data['previous'] as String?,
          'results': orders,
        };
      }
      throw Exception(
        'Failed to fetch orders - Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      
      print('❌ API ERROR: DioException');
      print('📍 Endpoint: /orders/');
      print('⚠️ Message: ${e.message}');
      print('📊 Status Code: ${e.response?.statusCode}');
      print('=' * 60 + '\n');
      throw Exception('Error fetching orders: ${e.message}');
    } catch (e) {
      
      print('❌ API ERROR: Generic Exception');
      print('⚠️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error fetching orders: $e');
    }
  }

  // Get order by ID
  Future<OrderModel> getOrder(int orderId) async {
    try {
      final endpoint = '/orders/$orderId/';
      
      print('🌐 API REQUEST: GET $endpoint');
      print('📍 Full URL: ${ApiConstants.baseUrl}$endpoint');
      print('=' * 60);

      final response = await _dio.get(endpoint);

      
      print('✅ API RESPONSE: SUCCESS');
      print('📊 Status Code: ${response.statusCode}');
      print('=' * 60 + '\n');

      if (response.statusCode == 200) {
        final order = OrderModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        print('   ✓ Order: ${order.orderNumber} (ID: ${order.id})');
        return order;
      }
      throw Exception('Failed to fetch order - Status: ${response.statusCode}');
    } on DioException catch (e) {
      
      print('❌ API ERROR: DioException');
      print('⚠️ Message: ${e.message}');
      print('📊 Status Code: ${e.response?.statusCode}');
      print('=' * 60 + '\n');
      throw Exception('Error fetching order: ${e.message}');
    } catch (e) {
      
      print('❌ API ERROR: Generic Exception');
      print('⚠️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error fetching order: $e');
    }
  }

  // Create new order
  Future<OrderModel> createOrder({
    required int client,
    required String totalAmount,
    required String description,
    required String deliveryDate,
  }) async {
    try {
      final data = {
        'client': client,
        'total_amount': totalAmount,
        'description': description,
        'delivery_date': deliveryDate,
      };

      
      print('🌐 API REQUEST: POST /orders/');
      print('📍 Full URL: ${ApiConstants.baseUrl}/orders/');
      print('📦 Request Data:');
      print('   - Client: $client');
      print('   - Total Amount: $totalAmount');
      print('   - Description: $description');
      print('   - Delivery Date: $deliveryDate');
      print('=' * 60);

      final response = await _dio.post('/orders/', data: data);

      
      print('✅ API RESPONSE: SUCCESS');
      print('📊 Status Code: ${response.statusCode}');
      print('=' * 60 + '\n');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final order = OrderModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        print('   ✓ Order Created: ${order.orderNumber} (ID: ${order.id})');
        return order;
      }
      throw Exception(
        'Failed to create order - Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      
      print('❌ API ERROR: DioException');
      print('⚠️ Message: ${e.message}');
      print('📊 Status Code: ${e.response?.statusCode}');
      print('📝 Response: ${e.response?.data}');
      print('=' * 60 + '\n');
      if (e.response?.statusCode == 400) {
        final errorDetail =
            e.response?.data['detail'] ??
            e.response?.data['error'] ??
            'Invalid order data';
        throw Exception(errorDetail);
      }
      throw Exception('Error creating order: ${e.message}');
    } catch (e) {
      
      print('❌ API ERROR: Generic Exception');
      print('⚠️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error creating order: $e');
    }
  }

  // Update order
  Future<OrderModel> updateOrder(
    int orderId, {
    required int client,
    required String totalAmount,
    required String description,
    required String deliveryDate,
    required String status,
  }) async {
    try {
      final endpoint = '/orders/$orderId/';
      final data = {
        'client': client,
        'total_amount': totalAmount,
        'description': description,
        'delivery_date': deliveryDate,
        'status': status,
      };

      
      print('🌐 API REQUEST: PUT $endpoint');
      print('📍 Full URL: ${ApiConstants.baseUrl}$endpoint');
      print('📦 Request Data:');
      print('   - Client: $client');
      print('   - Total Amount: $totalAmount');
      print('   - Description: $description');
      print('   - Delivery Date: $deliveryDate');
      print('   - Status: $status');
      print('=' * 60);

      final response = await _dio.put(endpoint, data: data);

      
      print('✅ API RESPONSE: SUCCESS');
      print('📊 Status Code: ${response.statusCode}');
      print('=' * 60 + '\n');

      if (response.statusCode == 200) {
        final order = OrderModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        print('   ✓ Order Updated: ${order.orderNumber} (ID: ${order.id})');
        return order;
      }
      throw Exception(
        'Failed to update order - Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      
      print('❌ API ERROR: DioException');
      print('⚠️ Message: ${e.message}');
      print('📊 Status Code: ${e.response?.statusCode}');
      print('=' * 60 + '\n');
      throw Exception('Error updating order: ${e.message}');
    } catch (e) {
      
      print('❌ API ERROR: Generic Exception');
      print('⚠️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error updating order: $e');
    }
  }

  // Cancel/Delete order
  Future<void> deleteOrder(int orderId) async {
    try {
      final endpoint = '/orders/$orderId/';
      
      print('🌐 API REQUEST: DELETE $endpoint');
      print('📍 Full URL: ${ApiConstants.baseUrl}$endpoint');
      print('=' * 60);

      final response = await _dio.delete(endpoint);

      
      print('✅ API RESPONSE: SUCCESS');
      print('📊 Status Code: ${response.statusCode}');
      print('   ✓ Order $orderId cancelled successfully');
      print('=' * 60 + '\n');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Failed to delete order - Status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      
      print('❌ API ERROR: DioException');
      print('⚠️ Message: ${e.message}');
      print('📊 Status Code: ${e.response?.statusCode}');
      print('=' * 60 + '\n');
      throw Exception('Error deleting order: ${e.message}');
    } catch (e) {
      
      print('❌ API ERROR: Generic Exception');
      print('⚠️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error deleting order: $e');
    }
  }

  // Get client orders
  Future<Map<String, dynamic>> getClientOrders({
    required int clientId,
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final endpoint = '/clients/$clientId/orders/';
      
      print('🌐 API REQUEST: GET $endpoint');
      print('📍 Full URL: ${ApiConstants.baseUrl}$endpoint');
      print('=' * 60);

      final response = await _dio.get(
        endpoint,
        queryParameters: {'page': page, 'page_size': pageSize},
      );

      
      print('✅ API RESPONSE: SUCCESS');
      print('📊 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final orders =
            (data['results'] as List?)
                ?.map(
                  (item) => OrderModel.fromJson(item as Map<String, dynamic>),
                )
                .toList() ??
            [];

        print('📦 Number of Orders: ${orders.length}');
        print('=' * 60 + '\n');

        return {
          'count': data['count'] as int? ?? 0,
          'next': data['next'] as String?,
          'previous': data['previous'] as String?,
          'results': orders,
        };
      }
      throw Exception(
        'Failed to fetch client orders - Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      
      print('❌ API ERROR: DioException');
      print('⚠️ Message: ${e.message}');
      print('=' * 60 + '\n');
      throw Exception('Error fetching client orders: ${e.message}');
    } catch (e) {
      
      print('❌ API ERROR: Generic Exception');
      print('⚠️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error fetching client orders: $e');
    }
  }
}
