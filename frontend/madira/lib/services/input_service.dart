import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/constants/api_constants.dart';
import '../models/input_model.dart';

class InputService {
  final _dio = DioClient().dio;

  // Get all inputs with pagination and filters
  Future<Map<String, dynamic>> getInputs({
    int page = 1,
    int pageSize = 10,
    String? type,
    int? orderId,
    String? search,
    String? ordering,
  }) async {
    try {
      print('\n' + '=' * 60);
      print('🌐 API REQUEST: GET /inputs/');
      print('📍 Full URL: ${ApiConstants.baseUrl}${ApiConstants.inputs}');
      print('📊 Pagination: page=$page, pageSize=$pageSize');
      if (type != null && type.isNotEmpty) print('🏷️ Type: $type');
      if (orderId != null) print('📦 Order ID: $orderId');
      if (search != null && search.isNotEmpty) print('🔍 Search: $search');
      if (ordering != null && ordering.isNotEmpty)
        print('🔃 Ordering: $ordering');
      print('=' * 60);

      final response = await _dio.get(
        ApiConstants.inputs,
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (type != null && type.isNotEmpty) 'type': type,
          if (orderId != null) 'order': orderId,
          if (search != null && search.isNotEmpty) 'search': search,
          if (ordering != null && ordering.isNotEmpty) 'ordering': ordering,
        },
      );

      print('\n' + '=' * 60);
      print('✅ API RESPONSE: SUCCESS');
      print('📊 Status Code: ${response.statusCode}');
      print('📦 Response Data Type: ${response.data.runtimeType}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final inputs =
            (data['results'] as List?)
                ?.map(
                  (item) => InputModel.fromJson(item as Map<String, dynamic>),
                )
                .toList() ??
            [];

        print('📥 Number of Inputs: ${inputs.length}');
        print('📈 Total Count: ${data['count']}');
        print('=' * 60 + '\n');

        for (var input in inputs) {
          print(
            '   ✓ Input: ${input.type} - Amount: ${input.amount} DA (ID: ${input.id}) - Order: ${input.order}',
          );
        }

        return {
          'count': data['count'] as int? ?? 0,
          'next': data['next'] as String?,
          'previous': data['previous'] as String?,
          'results': inputs,
        };
      }
      throw Exception(
        'Failed to fetch inputs - Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      print('\n' + '=' * 60);
      print('❌ API ERROR: DioException');
      print('📍 Endpoint: ${ApiConstants.inputs}');
      print('⚠️ Message: ${e.message}');
      print('📊 Status Code: ${e.response?.statusCode}');
      print('📝 Response: ${e.response?.data}');
      print('=' * 60 + '\n');
      throw Exception('Error fetching inputs: ${e.message}');
    } catch (e) {
      print('\n' + '=' * 60);
      print('❌ API ERROR: Generic Exception');
      print('⚠️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error fetching inputs: $e');
    }
  }

  // Get input by ID
  Future<InputModel> getInputById(int inputId) async {
    try {
      final endpoint = '${ApiConstants.inputsDetail}/$inputId/';
      print('\n' + '=' * 60);
      print('🌐 API REQUEST: GET /inputs/$inputId/');
      print('📍 Full URL: ${ApiConstants.baseUrl}$endpoint');
      print('=' * 60);

      final response = await _dio.get(endpoint);

      print('\n' + '=' * 60);
      print('✅ API RESPONSE: SUCCESS');
      print('📊 Status Code: ${response.statusCode}');
      print('=' * 60 + '\n');

      if (response.statusCode == 200) {
        final input = InputModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        print(
          '   ✓ Input: ${input.type} - ${input.amount} DA (ID: ${input.id})',
        );
        return input;
      }
      throw Exception('Failed to fetch input - Status: ${response.statusCode}');
    } on DioException catch (e) {
      print('\n' + '=' * 60);
      print('❌ API ERROR: DioException');
      print('⚠️ Message: ${e.message}');
      print('📊 Status Code: ${e.response?.statusCode}');
      print('=' * 60 + '\n');
      throw Exception('Error fetching input: ${e.message}');
    } catch (e) {
      print('\n' + '=' * 60);
      print('❌ API ERROR: Generic Exception');
      print('⚠️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error fetching input: $e');
    }
  }

  // Get inputs by order ID
  Future<Map<String, dynamic>> getInputsByOrder(
    int orderId, {
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      final endpoint = '${ApiConstants.orders}$orderId/inputs/';
      print('\n' + '=' * 60);
      print('🌐 API REQUEST: GET /orders/$orderId/inputs/');
      print('📍 Full URL: ${ApiConstants.baseUrl}$endpoint');
      print('📊 Pagination: page=$page, pageSize=$pageSize');
      print('=' * 60);

      final response = await _dio.get(
        endpoint,
        queryParameters: {'page': page, 'page_size': pageSize},
      );

      print('\n' + '=' * 60);
      print('✅ API RESPONSE: SUCCESS');
      print('📊 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final inputs =
            (data['results'] as List?)
                ?.map(
                  (item) => InputModel.fromJson(item as Map<String, dynamic>),
                )
                .toList() ??
            [];

        print('📥 Inputs for Order $orderId: ${inputs.length}');
        print('=' * 60 + '\n');

        for (var input in inputs) {
          print(
            '   ✓ Input: ${input.type} - Amount: ${input.amount} DA (ID: ${input.id})',
          );
        }

        return {
          'count': data['count'] as int? ?? 0,
          'next': data['next'] as String?,
          'previous': data['previous'] as String?,
          'results': inputs,
        };
      }
      throw Exception(
        'Failed to fetch order inputs - Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      print('\n' + '=' * 60);
      print('❌ API ERROR: DioException');
      print('⚠️ Message: ${e.message}');
      print('📊 Status Code: ${e.response?.statusCode}');
      print('📝 Response: ${e.response?.data}');
      print('=' * 60 + '\n');
      throw Exception('Error fetching order inputs: ${e.message}');
    } catch (e) {
      print('\n' + '=' * 60);
      print('❌ API ERROR: Generic Exception');
      print('⚠️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error fetching order inputs: $e');
    }
  }

  // Create input
  Future<InputModel> createInput({
    required String type,
    required double amount,
    int? order,
    required String description,
  }) async {
    try {
      final data = {
        'type': type,
        'amount': amount,
        if (order != null) 'order': order,
        'description': description,
      };

      print('\n' + '=' * 60);
      print('🌐 API REQUEST: POST /inputs/');
      print('📍 Full URL: ${ApiConstants.baseUrl}${ApiConstants.inputs}');
      print('📦 Request Data:');
      print('   - Type: $type');
      print('   - Amount: $amount DA');
      print('   - Order: ${order ?? "null"}');
      print('   - Description: $description');
      print('=' * 60);

      final response = await _dio.post(ApiConstants.inputs, data: data);

      print('\n' + '=' * 60);
      print('✅ API RESPONSE: SUCCESS');
      print('📊 Status Code: ${response.statusCode}');
      print('=' * 60 + '\n');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final input = InputModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        print(
          '   ✓ Input Created: ${input.type} - ${input.amount} DA (ID: ${input.id})',
        );
        return input;
      }
      throw Exception(
        'Failed to create input - Status: ${response.statusCode}',
      );
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
            'Invalid input data';
        throw Exception(errorDetail);
      }
      throw Exception('Error creating input: ${e.message}');
    } catch (e) {
      print('\n' + '=' * 60);
      print('❌ API ERROR: Generic Exception');
      print('⚠️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error creating input: $e');
    }
  }

  // Update input
  Future<InputModel> updateInput(
    int inputId, {
    required String type,
    required double amount,
    int? order,
    required String description,
  }) async {
    try {
      final endpoint = '${ApiConstants.inputsDetail}/$inputId/';
      final data = {
        'type': type,
        'amount': amount,
        if (order != null) 'order': order,
        'description': description,
      };

      print('\n' + '=' * 60);
      print('🌐 API REQUEST: PUT /inputs/$inputId/');
      print('📍 Full URL: ${ApiConstants.baseUrl}$endpoint');
      print('📦 Request Data:');
      print('   - Type: $type');
      print('   - Amount: $amount DA');
      print('   - Order: ${order ?? "null"}');
      print('   - Description: $description');
      print('=' * 60);

      final response = await _dio.put(endpoint, data: data);

      print('\n' + '=' * 60);
      print('✅ API RESPONSE: SUCCESS');
      print('📊 Status Code: ${response.statusCode}');
      print('=' * 60 + '\n');

      if (response.statusCode == 200) {
        final input = InputModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        print(
          '   ✓ Input Updated: ${input.type} - ${input.amount} DA (ID: ${input.id})',
        );
        return input;
      }
      throw Exception(
        'Failed to update input - Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      print('\n' + '=' * 60);
      print('❌ API ERROR: DioException');
      print('⚠️ Message: ${e.message}');
      print('📊 Status Code: ${e.response?.statusCode}');
      print('=' * 60 + '\n');
      throw Exception('Error updating input: ${e.message}');
    } catch (e) {
      print('\n' + '=' * 60);
      print('❌ API ERROR: Generic Exception');
      print('⚠️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error updating input: $e');
    }
  }

  // Delete input
  Future<void> deleteInput(int inputId) async {
    try {
      final endpoint = '${ApiConstants.inputsDetail}/$inputId/';
      print('\n' + '=' * 60);
      print('🌐 API REQUEST: DELETE /inputs/$inputId/');
      print('📍 Full URL: ${ApiConstants.baseUrl}$endpoint');
      print('=' * 60);

      final response = await _dio.delete(endpoint);

      print('\n' + '=' * 60);
      print('✅ API RESPONSE: SUCCESS');
      print('📊 Status Code: ${response.statusCode}');
      print('   ✓ Input $inputId deleted successfully');
      print('=' * 60 + '\n');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Failed to delete input - Status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('\n' + '=' * 60);
      print('❌ API ERROR: DioException');
      print('⚠️ Message: ${e.message}');
      print('📊 Status Code: ${e.response?.statusCode}');
      print('=' * 60 + '\n');
      throw Exception('Error deleting input: ${e.message}');
    } catch (e) {
      print('\n' + '=' * 60);
      print('❌ API ERROR: Generic Exception');
      print('⚠️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error deleting input: $e');
    }
  }
}
