import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/constants/api_constants.dart';
import '../models/supplier_model.dart';

class SupplierService {
  final _dio = DioClient().dio;

  // Get all suppliers with pagination and search
  Future<Map<String, dynamic>> getSuppliers({
    int page = 1,
    int pageSize = 10,
    String search = '',
    String ordering = '-created_at',
  }) async {
    try {
      print(' API REQUEST: GET /suppliers/');
      print(' Full URL: ${ApiConstants.baseUrl}suppliers/');
      print(' Pagination: page=$page, pageSize=$pageSize');
      if (search.isNotEmpty) print(' Search: $search');
      print(' Ordering: $ordering');
      print('=' * 60);

      final response = await _dio.get(
        '/suppliers/',
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (search.isNotEmpty) 'search': search,
          if (ordering.isNotEmpty) 'ordering': ordering,
        },
      );

      print(' API RESPONSE: SUCCESS');
      print(' Status Code: ${response.statusCode}');
      print(' Response Data Type: ${response.data.runtimeType}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final suppliers =
            (data['results'] as List?)
                ?.map(
                  (item) =>
                      SupplierModel.fromJson(item as Map<String, dynamic>),
                )
                .toList() ??
            [];

        print(' Number of Suppliers: ${suppliers.length}');
        print(' Total Count: ${data['count']}');
        print('=' * 60 + '\n');

        for (var supplier in suppliers) {
          print(
            '    Supplier: ${supplier.name} (ID: ${supplier.id}) - Status: ${supplier.status}',
          );
        }

        return {
          'count': data['count'] as int? ?? 0,
          'next': data['next'] as String?,
          'previous': data['previous'] as String?,
          'results': suppliers,
        };
      }
      throw Exception(
        'Failed to fetch suppliers - Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      print(' API ERROR: DioException');
      print(' Endpoint: /suppliers/');
      print('️ Message: ${e.message}');
      print(' Status Code: ${e.response?.statusCode}');
      print(' Response: ${e.response?.data}');
      print('=' * 60 + '\n');
      throw Exception('Error fetching suppliers: ${e.message}');
    } catch (e) {
      print(' API ERROR: Generic Exception');
      print('️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error fetching suppliers: $e');
    }
  }

  // Get supplier by ID
  Future<SupplierModel> getSupplier(int supplierId) async {
    try {
      final endpoint = '/suppliers/$supplierId/';

      print(' API REQUEST: GET $endpoint');
      print(' Full URL: ${ApiConstants.baseUrl}$endpoint');
      print('=' * 60);

      final response = await _dio.get(endpoint);

      print(' API RESPONSE: SUCCESS');
      print(' Status Code: ${response.statusCode}');
      print('=' * 60 + '\n');

      if (response.statusCode == 200) {
        final supplier = SupplierModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        print('    Supplier: ${supplier.name} (ID: ${supplier.id})');
        return supplier;
      }
      throw Exception(
        'Failed to fetch supplier - Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      print(' API ERROR: DioException');
      print('️ Message: ${e.message}');
      print(' Status Code: ${e.response?.statusCode}');
      print('=' * 60 + '\n');
      throw Exception('Error fetching supplier: ${e.message}');
    } catch (e) {
      print(' API ERROR: Generic Exception');
      print('️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error fetching supplier: $e');
    }
  }

  // Create new supplier
  Future<SupplierModel> createSupplier({
    required String name,
    required String phone,
    required String address,
    required String notes,
  }) async {
    try {
      final data = {
        'name': name,
        'phone': phone,
        'address': address,
        'notes': notes,
      };

      print(' API REQUEST: POST /suppliers/');
      print(' Full URL: ${ApiConstants.baseUrl}/suppliers/');
      print(' Request Data:');
      print('   - Name: $name');
      print('   - Phone: $phone');
      print('   - Address: $address');
      print('   - Notes: $notes');
      print('=' * 60);

      final response = await _dio.post('/suppliers/', data: data);

      print(' API RESPONSE: SUCCESS');
      print(' Status Code: ${response.statusCode}');
      print('=' * 60 + '\n');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final supplier = SupplierModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        print('    Supplier Created: ${supplier.name} (ID: ${supplier.id})');
        return supplier;
      }
      throw Exception(
        'Failed to create supplier - Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      print(' API ERROR: DioException');
      print('️ Message: ${e.message}');
      print(' Status Code: ${e.response?.statusCode}');
      print(' Response: ${e.response?.data}');
      print('=' * 60 + '\n');
      if (e.response?.statusCode == 400) {
        final errorDetail =
            e.response?.data['detail'] ??
            e.response?.data['error'] ??
            'Invalid supplier data';
        throw Exception(errorDetail);
      }
      throw Exception('Error creating supplier: ${e.message}');
    } catch (e) {
      print(' API ERROR: Generic Exception');
      print('️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error creating supplier: $e');
    }
  }

  // Update supplier
  Future<SupplierModel> updateSupplier(
    int supplierId, {
    required String name,
    required String phone,
    required String address,
    required String notes,
    required bool isActive,
  }) async {
    try {
      final endpoint = '/suppliers/$supplierId/';
      final data = {
        'name': name,
        'phone': phone,
        'address': address,
        'notes': notes,
        'is_active': isActive,
      };

      print(' API REQUEST: PUT $endpoint');
      print(' Full URL: ${ApiConstants.baseUrl}$endpoint');
      print(' Request Data:');
      print('   - Name: $name');
      print('   - Phone: $phone');
      print('   - Address: $address');
      print('   - Notes: $notes');
      print('   - Is Active: $isActive');
      print('=' * 60);

      final response = await _dio.put(endpoint, data: data);

      print(' API RESPONSE: SUCCESS');
      print(' Status Code: ${response.statusCode}');
      print('=' * 60 + '\n');

      if (response.statusCode == 200) {
        final supplier = SupplierModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        print('    Supplier Updated: ${supplier.name} (ID: ${supplier.id})');
        return supplier;
      }
      throw Exception(
        'Failed to update supplier - Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      print(' API ERROR: DioException');
      print('️ Message: ${e.message}');
      print(' Status Code: ${e.response?.statusCode}');
      print('=' * 60 + '\n');
      throw Exception('Error updating supplier: ${e.message}');
    } catch (e) {
      print(' API ERROR: Generic Exception');
      print('️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error updating supplier: $e');
    }
  }

  // Delete/Deactivate supplier
  Future<void> deleteSupplier(int supplierId) async {
    try {
      final endpoint = '/suppliers/$supplierId/';

      print(' API REQUEST: DELETE $endpoint');
      print(' Full URL: ${ApiConstants.baseUrl}$endpoint');
      print('=' * 60);

      final response = await _dio.delete(endpoint);

      print(' API RESPONSE: SUCCESS');
      print(' Status Code: ${response.statusCode}');
      print('    Supplier $supplierId deactivated successfully');
      print('=' * 60 + '\n');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Failed to delete supplier - Status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print(' API ERROR: DioException');
      print('️ Message: ${e.message}');
      print(' Status Code: ${e.response?.statusCode}');
      print('=' * 60 + '\n');
      throw Exception('Error deleting supplier: ${e.message}');
    } catch (e) {
      print(' API ERROR: Generic Exception');
      print('️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error deleting supplier: $e');
    }
  }

  // Get supplier summary
  Future<Map<String, dynamic>> getSupplierSummary(int supplierId) async {
    try {
      final endpoint = '/suppliers/$supplierId/summary/';

      print(' API REQUEST: GET $endpoint');
      print(' Full URL: ${ApiConstants.baseUrl}$endpoint');
      print('=' * 60);

      final response = await _dio.get(endpoint);

      print(' API RESPONSE: SUCCESS');
      print(' Status Code: ${response.statusCode}');
      print('=' * 60 + '\n');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }
      throw Exception(
        'Failed to fetch supplier summary - Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      print(' API ERROR: DioException');
      print('️ Message: ${e.message}');
      print(' Status Code: ${e.response?.statusCode}');
      print('=' * 60 + '\n');
      throw Exception('Error fetching supplier summary: ${e.message}');
    } catch (e) {
      print(' API ERROR: Generic Exception');
      print('️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error fetching supplier summary: $e');
    }
  }
}
