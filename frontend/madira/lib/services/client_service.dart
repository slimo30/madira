import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/constants/api_constants.dart';
import '../models/client_model.dart';

class ClientService {
  final _dio = DioClient().dio;

  // Get all clients with pagination and search (main method called by provider)
  Future<Map<String, dynamic>> getClients({
    int page = 1,
    int pageSize = 10,
    String search = '',
    String ordering = 'name',
  }) async {
    try {
      print('\n' + '=' * 60);
      print('🌐 API REQUEST: GET /clients/');
      print(
        '📍 Full URL: ${ApiConstants.baseUrl}${ApiConstants.clientsEndpoint}',
      );
      print('📊 Pagination: page=$page, pageSize=$pageSize');
      if (search.isNotEmpty) print('🔍 Search: $search');
      print('📋 Ordering: $ordering');
      print('=' * 60);

      final response = await _dio.get(
        ApiConstants.clientsEndpoint,
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (search.isNotEmpty) 'search': search,
          if (ordering.isNotEmpty) 'ordering': ordering,
        },
      );

      print('\n' + '=' * 60);
      print('✅ API RESPONSE: SUCCESS');
      print('📊 Status Code: ${response.statusCode}');
      print('📦 Response Data Type: ${response.data.runtimeType}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final clients =
            (data['results'] as List?)
                ?.map(
                  (item) => ClientModel.fromJson(item as Map<String, dynamic>),
                )
                .toList() ??
            [];

        print('👥 Number of Clients: ${clients.length}');
        print('📈 Total Count: ${data['count']}');
        print('=' * 60 + '\n');

        for (var client in clients) {
          print(
            '   ✓ Client: ${client.name} (ID: ${client.id}) - Type: ${client.clientTypeDisplay} - Credit: ${client.formattedCreditBalance}',
          );
        }

        return {
          'count': data['count'] as int? ?? 0,
          'next': data['next'] as String?,
          'previous': data['previous'] as String?,
          'results': clients,
        };
      }
      throw Exception(
        'Failed to fetch clients - Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      print('\n' + '=' * 60);
      print('❌ API ERROR: DioException');
      print('📍 Endpoint: ${ApiConstants.clientsEndpoint}');
      print('⚠️ Message: ${e.message}');
      print('📊 Status Code: ${e.response?.statusCode}');
      print('📝 Response: ${e.response?.data}');
      print('=' * 60 + '\n');
      throw Exception('Error fetching clients: ${e.message}');
    } catch (e) {
      print('\n' + '=' * 60);
      print('❌ API ERROR: Generic Exception');
      print('⚠️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error fetching clients: $e');
    }
  }

  // Alias for getAllClients (kept for backward compatibility)
  Future<Map<String, dynamic>> getAllClients({
    int page = 1,
    int pageSize = 10,
    String search = '',
    String ordering = 'name',
  }) => getClients(
    page: page,
    pageSize: pageSize,
    search: search,
    ordering: ordering,
  );

  // Get client by ID
  Future<ClientModel> getClient(int clientId) async {
    try {
      final endpoint = '${ApiConstants.clientsDetailEndpoint}/$clientId/';
      print('\n' + '=' * 60);
      print('🌐 API REQUEST: GET /clients/$clientId/');
      print('📍 Full URL: ${ApiConstants.baseUrl}$endpoint');
      print('=' * 60);

      final response = await _dio.get(endpoint);

      print('\n' + '=' * 60);
      print('✅ API RESPONSE: SUCCESS');
      print('📊 Status Code: ${response.statusCode}');
      print('=' * 60 + '\n');

      if (response.statusCode == 200) {
        final client = ClientModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        print('   ✓ Client: ${client.name} (ID: ${client.id})');
        return client;
      }
      throw Exception(
        'Failed to fetch client - Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      print('\n' + '=' * 60);
      print('❌ API ERROR: DioException');
      print('⚠️ Message: ${e.message}');
      print('📊 Status Code: ${e.response?.statusCode}');
      print('=' * 60 + '\n');
      throw Exception('Error fetching client: ${e.message}');
    } catch (e) {
      print('\n' + '=' * 60);
      print('❌ API ERROR: Generic Exception');
      print('⚠️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error fetching client: $e');
    }
  }

  // Alias for getClient (kept for backward compatibility)
  Future<ClientModel> getClientById(int clientId) => getClient(clientId);

  // Get client complete profile with financial summary
  // Get client complete profile with financial summary and orders
  Future<Map<String, dynamic>> getClientComplete(int clientId) async {
    try {
      final endpoint =
          '${ApiConstants.clientsDetailEndpoint}/$clientId/complete/';
      print('\n' + '=' * 80);
      print('🌐 API REQUEST: GET /clients/$clientId/complete/');
      print('📍 Full URL: ${ApiConstants.baseUrl}$endpoint');
      print('=' * 80);

      final response = await _dio.get(endpoint);

      print('\n' + '=' * 80);
      print('✅ API RESPONSE: SUCCESS');
      print('📊 Status Code: ${response.statusCode}');
      print('=' * 80 + '\n');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;

        final client = data['client'];
        final financial = data['financial_summary'];
        final orders = data['orders'] as List;

        // 🧩 Print client info
        print('👤 CLIENT INFO');
        print('─' * 80);
        print('ID: ${client['id']}');
        print('Name: ${client['name']}');
        print('Type: ${client['client_type']}');
        print('Credit Balance: ${client['credit_balance']}');
        print('Status: ${client['is_active'] ? "Active" : "Inactive"}');
        print('Created At: ${client['created_at']}');
        print('');

        // 💰 Print financial summary
        print('💰 FINANCIAL SUMMARY');
        print('─' * 80);
        print('Total Orders: ${financial['total_orders_count']}');
        print('Total Amount: ${financial['total_orders_amount']} DA');
        print('Total Paid: ${financial['total_paid']} DA');
        print('Total Unpaid: ${financial['total_unpaid']} DA');
        print('Total Expenses: ${financial['total_expenses']} DA');
        print('Total Benefit: ${financial['total_benefit']} DA');
        print('Initial Credit: ${financial['initial_credit_balance']} DA');
        print('Final Balance: ${financial['final_balance']} DA');
        print('Avg Order Value: ${financial['average_order_value']} DA');
        print(
          'Avg Benefit/Order: ${financial['average_benefit_per_order']} DA',
        );
        print('');

        // 🧾 Print orders
        print('📦 ORDERS (${orders.length})');
        print('─' * 80);
        for (var order in orders) {
          print('🔹 Order #${order['order_number']}');
          print('   - Status: ${order['status']}');
          print('   - Date: ${order['order_date']}');
          print('   - Total Amount: ${order['total_amount']} DA');
          print('   - Paid Amount: ${order['paid_amount']} DA');
          print('   - Remaining: ${order['remaining_amount']} DA');
          print('   - Benefit: ${order['benefit']} DA');
          print('   - Paid %: ${order['payment_status']['paid_percentage']}%');
          print('   - Inputs: ${(order['inputs'] as List).length}');
          print('   - Outputs: ${(order['outputs'] as List).length}');
          print('');
        }

        print(
          '=' * 80 +
              '\n✅ Client complete data fetched successfully.\n' +
              '=' * 80,
        );

        return data;
      }

      throw Exception(
        'Failed to fetch complete client - Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      print('\n' + '=' * 80);
      print('❌ API ERROR: DioException');
      print('⚠️ Message: ${e.message}');
      print('📊 Status Code: ${e.response?.statusCode}');
      print('📝 Response: ${e.response?.data}');
      print('=' * 80 + '\n');
      throw Exception('Error fetching complete client: ${e.message}');
    } catch (e) {
      print('\n' + '=' * 80);
      print('❌ API ERROR: Generic Exception');
      print('⚠️ Error: $e');
      print('=' * 80 + '\n');
      throw Exception('Error fetching complete client: $e');
    }
  }

  // Create new client
  Future<ClientModel> createClient({
    required String name,
    required String phone,
    required String address,
    required String creditBalance,
    required String clientType,
    required String notes,
  }) async {
    try {
      final data = {
        'name': name,
        'phone': phone,
        'address': address,
        'credit_balance': creditBalance,
        'client_type': clientType,
        'notes': notes,
      };

      print('\n' + '=' * 60);
      print('🌐 API REQUEST: POST /clients/');
      print(
        '📍 Full URL: ${ApiConstants.baseUrl}${ApiConstants.clientsEndpoint}',
      );
      print('📦 Request Data:');
      print('   - Name: $name');
      print('   - Phone: $phone');
      print('   - Address: $address');
      print('   - Credit Balance: $creditBalance');
      print('   - Client Type: $clientType');
      print('   - Notes: $notes');
      print('=' * 60);

      final response = await _dio.post(
        ApiConstants.clientsEndpoint,
        data: data,
      );

      print('\n' + '=' * 60);
      print('✅ API RESPONSE: SUCCESS');
      print('📊 Status Code: ${response.statusCode}');
      print('=' * 60 + '\n');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final client = ClientModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        print('   ✓ Client Created: ${client.name} (ID: ${client.id})');
        return client;
      }
      throw Exception(
        'Failed to create client - Status: ${response.statusCode}',
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
            'Invalid client data';
        throw Exception(errorDetail);
      }
      throw Exception('Error creating client: ${e.message}');
    } catch (e) {
      print('\n' + '=' * 60);
      print('❌ API ERROR: Generic Exception');
      print('⚠️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error creating client: $e');
    }
  }

  // Update client
  Future<ClientModel> updateClient(
    int clientId, {
    required String name,
    required String phone,
    required String address,
    required String creditBalance,
    required String clientType,
    required String notes,
    required bool isActive,
  }) async {
    try {
      final endpoint = '${ApiConstants.clientsDetailEndpoint}/$clientId/';
      final data = {
        'name': name,
        'phone': phone,
        'address': address,
        'credit_balance': creditBalance,
        'client_type': clientType,
        'notes': notes,
        'is_active': isActive,
      };

      print('\n' + '=' * 60);
      print('🌐 API REQUEST: PUT /clients/$clientId/');
      print('📍 Full URL: ${ApiConstants.baseUrl}$endpoint');
      print('📦 Request Data:');
      print('   - Name: $name');
      print('   - Phone: $phone');
      print('   - Address: $address');
      print('   - Credit Balance: $creditBalance');
      print('   - Client Type: $clientType');
      print('   - Notes: $notes');
      print('   - Is Active: $isActive');
      print('=' * 60);

      final response = await _dio.put(endpoint, data: data);

      print('\n' + '=' * 60);
      print('✅ API RESPONSE: SUCCESS');
      print('📊 Status Code: ${response.statusCode}');
      print('=' * 60 + '\n');

      if (response.statusCode == 200) {
        final client = ClientModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        print('   ✓ Client Updated: ${client.name} (ID: ${client.id})');
        return client;
      }
      throw Exception(
        'Failed to update client - Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      print('\n' + '=' * 60);
      print('❌ API ERROR: DioException');
      print('⚠️ Message: ${e.message}');
      print('📊 Status Code: ${e.response?.statusCode}');
      print('=' * 60 + '\n');
      throw Exception('Error updating client: ${e.message}');
    } catch (e) {
      print('\n' + '=' * 60);
      print('❌ API ERROR: Generic Exception');
      print('⚠️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error updating client: $e');
    }
  }

  // Delete/Deactivate client
  Future<void> deleteClient(int clientId) async {
    try {
      final endpoint = '${ApiConstants.clientsDetailEndpoint}/$clientId/';
      print('\n' + '=' * 60);
      print('🌐 API REQUEST: DELETE /clients/$clientId/');
      print('📍 Full URL: ${ApiConstants.baseUrl}$endpoint');
      print('=' * 60);

      final response = await _dio.delete(endpoint);

      print('\n' + '=' * 60);
      print('✅ API RESPONSE: SUCCESS');
      print('📊 Status Code: ${response.statusCode}');
      print('   ✓ Client $clientId deactivated successfully');
      print('=' * 60 + '\n');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Failed to delete client - Status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print('\n' + '=' * 60);
      print('❌ API ERROR: DioException');
      print('⚠️ Message: ${e.message}');
      print('📊 Status Code: ${e.response?.statusCode}');
      print('=' * 60 + '\n');
      throw Exception('Error deleting client: ${e.message}');
    } catch (e) {
      print('\n' + '=' * 60);
      print('❌ API ERROR: Generic Exception');
      print('⚠️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error deleting client: $e');
    }
  }

  // 🔹 Get full client profile with financial summary, orders, and payments
}
