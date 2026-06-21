import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/constants/api_constants.dart';
import '../models/user_model.dart';

class UserService {
  final _dio = DioClient().dio;

  // Get all users
  Future<List<UserModel>> getAllUsers() async {
    try {
      print(' API REQUEST: GET /users/');
      print(' Full URL: ${ApiConstants.baseUrl}${ApiConstants.usersEndpoint}');
      print('=' * 60);

      final response = await _dio.get(ApiConstants.usersEndpoint);

      print(' API RESPONSE: SUCCESS');
      print(' Status Code: ${response.statusCode}');
      print(' Response Data Type: ${response.data.runtimeType}');
      print(' Number of Users: ${(response.data as List).length}');
      print('=' * 60 + '\n');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data;
        final users = data.map((json) => UserModel.fromJson(json)).toList();

        for (var user in users) {
          print(
            '    User: ${user.username} (ID: ${user.id}) - Role: ${user.role} - Status: ${user.isActive ? 'Active' : 'Inactive'}',
          );
        }

        return users;
      }
      throw Exception('Failed to fetch users - Status: ${response.statusCode}');
    } on DioException catch (e) {
      print(' API ERROR: DioException');
      print(' Endpoint: ${ApiConstants.usersEndpoint}');
      print('️ Message: ${e.message}');
      print(' Status Code: ${e.response?.statusCode}');
      print(' Response: ${e.response?.data}');
      print('=' * 60 + '\n');
      throw Exception('Error fetching users: ${e.message}');
    } catch (e) {
      print(' API ERROR: Generic Exception');
      print('️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error fetching users: $e');
    }
  }

  // Get user by ID
  Future<UserModel> getUserById(int userId) async {
    try {
      final endpoint = '${ApiConstants.usersDetailEndpoint}/$userId/';

      print(' API REQUEST: GET /users/$userId/');
      print(' Full URL: ${ApiConstants.baseUrl}$endpoint');
      print('=' * 60);

      final response = await _dio.get(endpoint);

      if (response.statusCode == 200) {
        print(' API RESPONSE: SUCCESS (Status: ${response.statusCode})');
        return UserModel.fromJson(response.data);
      }
      throw Exception('Failed to fetch user - Status: ${response.statusCode}');
    } on DioException catch (e) {
      print(' API ERROR: ${e.message}');
      throw Exception('Error fetching user: ${e.message}');
    } catch (e) {
      print(' API ERROR: $e');
      throw Exception('Error fetching user: $e');
    }
  }

  // Create new user
  Future<UserModel> createUser({
    required String username,
    required String password,
    required String role,
    required String fullName,
  }) async {
    try {
      final data = {
        'username': username,
        'password': password,
        'role': role,
        'full_name': fullName,
      };

      print(' API REQUEST: POST /users/create/');
      print(
        ' Full URL: ${ApiConstants.baseUrl}${ApiConstants.usersCreateEndpoint}',
      );
      print(' Request Data:');
      print('   - Username: $username');
      print('   - Password: ${password.replaceAll(RegExp(r'.'), '*')}');
      print('   - Role: $role');
      print('   - Full Name: $fullName');
      print('=' * 60);

      final response = await _dio.post(
        ApiConstants.usersCreateEndpoint,
        data: data,
      );

      print('\n${'=' * 60}');
      print(' API RESPONSE: SUCCESS');
      print(' Status Code: ${response.statusCode}');
      print(' Raw Response Data: ${response.data}');
      print(' Response Type: ${response.data.runtimeType}');

      // Check if response is a map
      if (response.data is Map) {
        print(' Response Keys: ${(response.data as Map).keys.toList()}');
      }
      print('=' * 60 + '\n');

      if (response.statusCode == 201 || response.statusCode == 200) {
        // Validate response data
        if (response.data == null) {
          throw Exception('Server returned null response');
        }

        try {
          final userModel = UserModel.fromJson(response.data);
          print(
            ' Created User: ${userModel.username} (ID: ${userModel.id}) - Role: ${userModel.role}',
          );
          return userModel;
        } catch (parseError) {
          print(' Failed to parse user response: $parseError');
          print(' Response data was: ${response.data}');
          rethrow;
        }
      }
      throw Exception('Failed to create user - Status: ${response.statusCode}');
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
            'Invalid user data';
        throw Exception(errorDetail);
      }
      throw Exception('Error creating user: ${e.message}');
    } catch (e) {
      print('\n${'=' * 60}');
      print(' API ERROR: $e');
      print('=' * 60 + '\n');
      throw Exception('Error creating user: $e');
    }
  }

  // Deactivate user
  Future<void> deactivateUser(int userId) async {
    try {
      final endpoint =
          '${ApiConstants.usersDeactivateEndpoint}/$userId/deactivate/';
      print('\n${'=' * 60}');
      print(' API REQUEST: POST /users/$userId/deactivate/');
      print(' Full URL: ${ApiConstants.baseUrl}$endpoint');
      print('=' * 60);

      final response = await _dio.post(endpoint, data: {});

      print(' API RESPONSE: SUCCESS (Status: ${response.statusCode})');

      if (response.statusCode == 200) {
        print('    User $userId deactivated successfully');
        return;
      }
      throw Exception(
        'Failed to deactivate user - Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      print(' API ERROR: ${e.message}');
      throw Exception('Error deactivating user: ${e.message}');
    } catch (e) {
      print(' API ERROR: $e');
      throw Exception('Error deactivating user: $e');
    }
  }

  // Reactivate user
  Future<void> reactivateUser(int userId) async {
    try {
      final endpoint =
          '${ApiConstants.usersReactivateEndpoint}/$userId/reactivate/';

      print(' API REQUEST: POST /users/$userId/reactivate/');
      print(' Full URL: ${ApiConstants.baseUrl}$endpoint');
      print('=' * 60);

      final response = await _dio.post(endpoint, data: {});

      print(' API RESPONSE: SUCCESS (Status: ${response.statusCode})');

      if (response.statusCode == 200) {
        print('    User $userId reactivated successfully');
        return;
      }
      throw Exception(
        'Failed to reactivate user - Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      print(' API ERROR: ${e.message}');
      throw Exception('Error reactivating user: ${e.message}');
    } catch (e) {
      print(' API ERROR: $e');
      throw Exception('Error reactivating user: $e');
    }
  }
}
