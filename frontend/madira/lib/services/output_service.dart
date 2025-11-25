// ✅ Output Service
import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/constants/api_constants.dart';
import '../models/output_model.dart';

class OutputService {
  final _dio = DioClient().dio;

  // Get all outputs with pagination and filters
  Future<Map<String, dynamic>> getOutputs({
    int page = 1,
    int pageSize = 10,
    String? type,
    int? orderId,
    int? inputId,
    String? search,
  }) async {
    try {
      
      print('🌐 API REQUEST: GET /outputs/');
      print('📍 Full URL: ${ApiConstants.baseUrl}${ApiConstants.outputs}');
      print('📊 Pagination: page=$page, pageSize=$pageSize');
      if (type != null && type.isNotEmpty) print('🏷️ Type: $type');
      if (orderId != null) print('📦 Order ID: $orderId');
      if (inputId != null) print('📥 Input ID: $inputId');
      if (search != null && search.isNotEmpty) print('🔍 Search: $search');
      print('=' * 60);

      final response = await _dio.get(
        ApiConstants.outputs,
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (type != null && type.isNotEmpty) 'type': type,
          if (orderId != null) 'order': orderId,
          if (inputId != null) 'input': inputId,
          if (search != null && search.isNotEmpty) 'search': search,
        },
      );

      
      print('✅ API RESPONSE: SUCCESS');
      print('📊 Status Code: ${response.statusCode}');
      print('📦 Response Data Type: ${response.data.runtimeType}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final outputs =
            (data['results'] as List?)
                ?.map(
                  (item) => OutputModel.fromJson(item as Map<String, dynamic>),
                )
                .toList() ??
            [];

        print('📥 Number of Outputs: ${outputs.length}');
        print('📈 Total Count: ${data['count']}');
        print('=' * 60 + '\n');

        for (var output in outputs) {
          print(
            '   ✓ Output: ${output.typeDisplay} - Amount: ${output.amount} DA (ID: ${output.id}) - Ref: ${output.reference}',
          );
        }

        return {
          'count': data['count'] as int? ?? 0,
          'next': data['next'] as String?,
          'previous': data['previous'] as String?,
          'results': outputs,
        };
      }
      throw Exception(
        'Failed to fetch outputs - Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      
      print('❌ API ERROR: DioException');
      print('📍 Endpoint: ${ApiConstants.outputs}');
      print('⚠️ Message: ${e.message}');
      print('📊 Status Code: ${e.response?.statusCode}');
      print('📝 Response: ${e.response?.data}');
      print('=' * 60 + '\n');
      throw Exception('Error fetching outputs: ${e.message}');
    } catch (e) {
      
      print('❌ API ERROR: Generic Exception');
      print('⚠️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error fetching outputs: $e');
    }
  }

  // Get output by ID
  Future<OutputModel> getOutputById(int outputId) async {
    try {
      final endpoint = '${ApiConstants.outputsDetail}/$outputId/';
      
      print('🌐 API REQUEST: GET /outputs/$outputId/');
      print('📍 Full URL: ${ApiConstants.baseUrl}$endpoint');
      print('=' * 60);

      final response = await _dio.get(endpoint);

      
      print('✅ API RESPONSE: SUCCESS');
      print('📊 Status Code: ${response.statusCode}');
      print('=' * 60 + '\n');

      if (response.statusCode == 200) {
        final output = OutputModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        print(
          '   ✓ Output: ${output.typeDisplay} - ${output.amount} DA (ID: ${output.id})',
        );
        return output;
      }
      throw Exception(
        'Failed to fetch output - Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      
      print('❌ API ERROR: DioException');
      print('⚠️ Message: ${e.message}');
      print('📊 Status Code: ${e.response?.statusCode}');
      print('=' * 60 + '\n');
      throw Exception('Error fetching output: ${e.message}');
    } catch (e) {
      
      print('❌ API ERROR: Generic Exception');
      print('⚠️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error fetching output: $e');
    }
  }

  // Get outputs by type
  Future<Map<String, dynamic>> getOutputsByType(
    String type, {
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      
      print('🌐 API REQUEST: GET /outputs/by_type/');
      print(
        '📍 Full URL: ${ApiConstants.baseUrl}${ApiConstants.outputsByType}',
      );
      print('🏷️ Type: $type');
      print('📊 Pagination: page=$page, pageSize=$pageSize');
      print('=' * 60);

      final response = await _dio.get(
        ApiConstants.outputsByType,
        queryParameters: {'type': type, 'page': page, 'page_size': pageSize},
      );

      
      print('✅ API RESPONSE: SUCCESS');
      print('📊 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final outputs =
            (data['results'] as List?)
                ?.map(
                  (item) => OutputModel.fromJson(item as Map<String, dynamic>),
                )
                .toList() ??
            [];

        print('📥 Outputs with type "$type": ${outputs.length}');
        print('=' * 60 + '\n');

        return {
          'count': data['count'] as int? ?? 0,
          'next': data['next'] as String?,
          'previous': data['previous'] as String?,
          'results': outputs,
        };
      }
      throw Exception(
        'Failed to fetch outputs by type - Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      
      print('❌ API ERROR: DioException');
      print('⚠️ Message: ${e.message}');
      print('📊 Status Code: ${e.response?.statusCode}');
      print('=' * 60 + '\n');
      throw Exception('Error fetching outputs by type: ${e.message}');
    } catch (e) {
      
      print('❌ API ERROR: Generic Exception');
      print('⚠️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error fetching outputs by type: $e');
    }
  }

  // Get outputs by order
  Future<Map<String, dynamic>> getOutputsByOrder(
    int orderId, {
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      
      print('🌐 API REQUEST: GET /outputs/by_order/');
      print(
        '📍 Full URL: ${ApiConstants.baseUrl}${ApiConstants.outputsByOrder}',
      );
      print('📦 Order ID: $orderId');
      print('📊 Pagination: page=$page, pageSize=$pageSize');
      print('=' * 60);

      final response = await _dio.get(
        ApiConstants.outputsByOrder,
        queryParameters: {
          'order_id': orderId,
          'page': page,
          'page_size': pageSize,
        },
      );

      
      print('✅ API RESPONSE: SUCCESS');
      print('📊 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final outputs =
            (data['results'] as List?)
                ?.map(
                  (item) => OutputModel.fromJson(item as Map<String, dynamic>),
                )
                .toList() ??
            [];

        print('📥 Outputs for Order $orderId: ${outputs.length}');
        print('=' * 60 + '\n');

        return {
          'count': data['count'] as int? ?? 0,
          'next': data['next'] as String?,
          'previous': data['previous'] as String?,
          'results': outputs,
        };
      }
      throw Exception(
        'Failed to fetch order outputs - Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      
      print('❌ API ERROR: DioException');
      print('⚠️ Message: ${e.message}');
      print('📊 Status Code: ${e.response?.statusCode}');
      print('=' * 60 + '\n');
      throw Exception('Error fetching order outputs: ${e.message}');
    } catch (e) {
      
      print('❌ API ERROR: Generic Exception');
      print('⚠️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error fetching order outputs: $e');
    }
  }

  // Get outputs by input
  Future<Map<String, dynamic>> getOutputsByInput(
    int inputId, {
    int page = 1,
    int pageSize = 10,
  }) async {
    try {
      
      print('🌐 API REQUEST: GET /outputs/by_input/');
      print(
        '📍 Full URL: ${ApiConstants.baseUrl}${ApiConstants.outputsByInput}',
      );
      print('📥 Input ID: $inputId');
      print('📊 Pagination: page=$page, pageSize=$pageSize');
      print('=' * 60);

      final response = await _dio.get(
        ApiConstants.outputsByInput,
        queryParameters: {
          'input_id': inputId,
          'page': page,
          'page_size': pageSize,
        },
      );

      
      print('✅ API RESPONSE: SUCCESS');
      print('📊 Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final outputs =
            (data['results'] as List?)
                ?.map(
                  (item) => OutputModel.fromJson(item as Map<String, dynamic>),
                )
                .toList() ??
            [];

        print('📥 Outputs for Input $inputId: ${outputs.length}');
        print('=' * 60 + '\n');

        return {
          'count': data['count'] as int? ?? 0,
          'next': data['next'] as String?,
          'previous': data['previous'] as String?,
          'results': outputs,
        };
      }
      throw Exception(
        'Failed to fetch input outputs - Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      
      print('❌ API ERROR: DioException');
      print('⚠️ Message: ${e.message}');
      print('📊 Status Code: ${e.response?.statusCode}');
      print('=' * 60 + '\n');
      throw Exception('Error fetching input outputs: ${e.message}');
    } catch (e) {
      
      print('❌ API ERROR: Generic Exception');
      print('⚠️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error fetching input outputs: $e');
    }
  }

  // Get output statistics
  Future<OutputStatistics> getStatistics() async {
    try {
      
      print('🌐 API REQUEST: GET /outputs/statistics/');
      print(
        '📍 Full URL: ${ApiConstants.baseUrl}${ApiConstants.outputsStatistics}',
      );
      print('=' * 60);

      final response = await _dio.get(ApiConstants.outputsStatistics);

      
      print('✅ API RESPONSE: SUCCESS');
      print('📊 Status Code: ${response.statusCode}');
      print('📦 Response Type: ${response.data.runtimeType}');
      print('📦 Raw Response: ${response.data}');
      print('=' * 60 + '\n');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        // Parse the API response structure
        final overall = data['overall'] as Map<String, dynamic>? ?? {};
        final byTypeList = data['by_type'] as List<dynamic>? ?? [];

        // Extract values from overall
        final totalAmount =
            (overall['total_amount'] as num?)?.toDouble() ?? 0.0;
        final totalCount = overall['total_outputs'] as int? ?? 0;

        print(
          '📊 Parsing overall: total_amount=$totalAmount, total_outputs=$totalCount',
        );

        // Convert by_type list to map
        final Map<String, dynamic> byTypeMap = {};
        for (var item in byTypeList) {
          if (item is Map<String, dynamic>) {
            final type = item['type'] as String? ?? 'unknown';
            final count = item['count'] as int? ?? 0;
            final total = (item['total'] as num?)?.toDouble() ?? 0.0;

            print('   📌 Type: $type, Count: $count, Total: $total');

            byTypeMap[type] = {'count': count, 'total_amount': total};
          }
        }

        // Create the statistics object with the correct structure
        final statisticsData = {
          'total_amount': totalAmount,
          'total_count': totalCount,
          'by_type': byTypeMap,
          'recent_outputs': [],
        };

        print('📦 Final statistics data: $statisticsData');

        final statistics = OutputStatistics.fromJson(statisticsData);
        print('📊 Total Outputs: ${statistics.totalCount}');
        print('💰 Total Amount: ${statistics.formattedTotalAmount} DA');
        print('=' * 60 + '\n');

        return statistics;
      }
      throw Exception(
        'Failed to fetch statistics - Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      
      print('❌ API ERROR: DioException');
      print('⚠️ Message: ${e.message}');
      print('📊 Status Code: ${e.response?.statusCode}');
      print('=' * 60 + '\n');
      throw Exception('Error fetching statistics: ${e.message}');
    } catch (e) {
      
      print('❌ API ERROR: Generic Exception');
      print('⚠️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error fetching statistics: $e');
    }
  }

  // Get related data for output
  Future<Map<String, dynamic>> getRelatedData(int outputId) async {
    try {
      final endpoint =
          '${ApiConstants.outputsRelatedData}/$outputId/related_data/';
      
      print('🌐 API REQUEST: GET /outputs/$outputId/related_data/');
      print('📍 Full URL: ${ApiConstants.baseUrl}$endpoint');
      print('=' * 60);

      final response = await _dio.get(endpoint);

      
      print('✅ API RESPONSE: SUCCESS');
      print('📊 Status Code: ${response.statusCode}');
      print('=' * 60 + '\n');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception(
        'Failed to fetch related data - Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      print('\n${'=' * 60}');
      print('❌ API ERROR: DioException');
      print('⚠️ Message: ${e.message}');
      print('📊 Status Code: ${e.response?.statusCode}');
      print('=' * 60 + '\n');
      throw Exception('Error fetching related data: ${e.message}');
    } catch (e) {
      print('\n${'=' * 60}');
      print('❌ API ERROR: Generic Exception');
      print('⚠️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error fetching related data: $e');
    }
  }

  // Create output
  Future<OutputModel> createOutput(Map<String, dynamic> data) async {
    try {
      
      print('🌐 API REQUEST: POST /outputs/');
      print('📍 Full URL: ${ApiConstants.baseUrl}${ApiConstants.outputs}');
      print('📦 Request Data:');
      print('   - Type: ${data['type']}');
      print('   - Amount: ${data['amount']} DA');
      if (data['product'] != null) print('   - Product: ${data['product']}');
      if (data['order'] != null) print('   - Order: ${data['order']}');
      if (data['supplier'] != null) print('   - Supplier: ${data['supplier']}');
      print('=' * 60);

      final response = await _dio.post(ApiConstants.outputs, data: data);

      
      print('✅ API RESPONSE: SUCCESS');
      print('📊 Status Code: ${response.statusCode}');
      print('=' * 60 + '\n');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final output = OutputModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        print(
          '   ✓ Output Created: ${output.typeDisplay} - ${output.amount} DA (ID: ${output.id})',
        );
        return output;
      }
      throw Exception(
        'Failed to create output - Status: ${response.statusCode}',
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
            'Invalid output data';
        throw Exception(errorDetail);
      }
      throw Exception('Error creating output: ${e.message}');
    } catch (e) {
      
      print('❌ API ERROR: Generic Exception');
      print('⚠️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error creating output: $e');
    }
  }

  // Update output
  Future<OutputModel> updateOutput(
    int outputId,
    Map<String, dynamic> data,
  ) async {
    try {
      final endpoint = '${ApiConstants.outputsDetail}/$outputId/';
      
      print('🌐 API REQUEST: PUT /outputs/$outputId/');
      print('📍 Full URL: ${ApiConstants.baseUrl}$endpoint');
      print('📦 Request Data:');
      print('   - Type: ${data['type']}');
      print('   - Amount: ${data['amount']} DA');
      print('=' * 60);

      final response = await _dio.put(endpoint, data: data);

      
      print('✅ API RESPONSE: SUCCESS');
      print('📊 Status Code: ${response.statusCode}');
      print('=' * 60 + '\n');

      if (response.statusCode == 200) {
        final output = OutputModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        print(
          '   ✓ Output Updated: ${output.typeDisplay} - ${output.amount} DA (ID: ${output.id})',
        );
        return output;
      }
      throw Exception(
        'Failed to update output - Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      
      print('❌ API ERROR: DioException');
      print('⚠️ Message: ${e.message}');
      print('📊 Status Code: ${e.response?.statusCode}');
      print('=' * 60 + '\n');
      throw Exception('Error updating output: ${e.message}');
    } catch (e) {
      
      print('❌ API ERROR: Generic Exception');
      print('⚠️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error updating output: $e');
    }
  }

  // Partial update output
  Future<OutputModel> partialUpdateOutput(
    int outputId,
    Map<String, dynamic> data,
  ) async {
    try {
      final endpoint = '${ApiConstants.outputsDetail}/$outputId/';
      
      print('🌐 API REQUEST: PATCH /outputs/$outputId/');
      print('📍 Full URL: ${ApiConstants.baseUrl}$endpoint');
      print('📦 Request Data: $data');
      print('=' * 60);

      final response = await _dio.patch(endpoint, data: data);

      
      print('✅ API RESPONSE: SUCCESS');
      print('📊 Status Code: ${response.statusCode}');
      print('=' * 60 + '\n');

      if (response.statusCode == 200) {
        final output = OutputModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        print('   ✓ Output Partially Updated (ID: ${output.id})');
        return output;
      }
      throw Exception(
        'Failed to partially update output - Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      
      print('❌ API ERROR: DioException');
      print('⚠️ Message: ${e.message}');
      print('📊 Status Code: ${e.response?.statusCode}');
      print('=' * 60 + '\n');
      throw Exception('Error partially updating output: ${e.message}');
    } catch (e) {
      
      print('❌ API ERROR: Generic Exception');
      print('⚠️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error partially updating output: $e');
    }
  }

  // Delete output
  Future<void> deleteOutput(int outputId) async {
    try {
      final endpoint = '${ApiConstants.outputsDetail}/$outputId/';
      
      print('🌐 API REQUEST: DELETE /outputs/$outputId/');
      print('📍 Full URL: ${ApiConstants.baseUrl}$endpoint');
      print('=' * 60);

      final response = await _dio.delete(endpoint);

      
      print('✅ API RESPONSE: SUCCESS');
      print('📊 Status Code: ${response.statusCode}');
      print('   ✓ Output $outputId deleted successfully');
      print('=' * 60 + '\n');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Failed to delete output - Status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      
      print('❌ API ERROR: DioException');
      print('⚠️ Message: ${e.message}');
      print('📊 Status Code: ${e.response?.statusCode}');
      print('=' * 60 + '\n');
      throw Exception('Error deleting output: ${e.message}');
    } catch (e) {
      
      print('❌ API ERROR: Generic Exception');
      print('⚠️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error deleting output: $e');
    }
  }
}
