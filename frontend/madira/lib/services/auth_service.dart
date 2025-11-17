import 'package:madira/core/constants/api_constants.dart';
import '../core/network/dio_client.dart';
import '../core/storage/storage_service.dart';
import '../models/login_model.dart';

class AuthService {
  final _dio = DioClient().dio;
  final _storage = StorageService();

  Future<LoginModel> login(String username, String password) async {
    print('🌐 AuthService: Starting API login request...');
    print('🌐 Endpoint: ${ApiConstants.loginEndpoint}');
    print('🌐 Username: $username');

    try {
      print('🌐 AuthService: Sending POST request to API...');
      final response = await _dio.post(
        ApiConstants.loginEndpoint,
        data: {'username': username, 'password': password},
      );

      print('🌐 AuthService: API Response received!');
      print('🌐 Status Code: ${response.statusCode}');
      print('🌐 Response Data: ${response.data}');

      final data = response.data;

      print('🌐 AuthService: Saving all user data...');
      await _storage.saveUserData(
        token: data['access'],
        userId: data['user_id'],
        username: data['username'],
        role: data['role'],
      );
      print('🌐 AuthService: All user data saved successfully');

      print('🌐 AuthService: Creating LoginModel from response...');
      final loginModel = LoginModel.fromJson(data);
      print('🌐 AuthService: LoginModel created: $loginModel');

      return loginModel;
    } catch (e) {
      print('❌ AuthService: Login failed with error: $e');

      // Convert technical errors to user-friendly messages
      String userMessage = _getLoginErrorMessage(e);
      throw Exception(userMessage);
    }
  }

  Future<void> logout() async {
    print('🚪 AuthService: Starting logout...');
    try {
      await _dio.post(ApiConstants.logoutEndpoint);
      await _storage.deleteAllUserData();
      print('🚪 AuthService: Logout successful - all user data cleared');
    } catch (e) {
      print('❌ AuthService: Logout error: $e');
      // Even if logout API fails, we should clear local data
      await _storage.deleteAllUserData();
      print('🚪 AuthService: Local user data cleared despite API error');

      // Don't throw error for logout - just clear local data
      // throw Exception("Unable to logout. Please try again.");
    }
  }

  // Convert technical errors to user-friendly messages
  String _getLoginErrorMessage(dynamic error) {
    String errorString = error.toString().toLowerCase();

    // Handle specific HTTP status codes
    if (errorString.contains('400') || errorString.contains('bad request')) {
      return 'Invalid username or password. Please check your credentials.';
    }

    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return 'Invalid username or password. Please try again.';
    }

    if (errorString.contains('403') || errorString.contains('forbidden')) {
      return 'Access denied. Please contact your administrator.';
    }

    if (errorString.contains('404') || errorString.contains('not found')) {
      return 'Service temporarily unavailable. Please try again later.';
    }

    if (errorString.contains('500') ||
        errorString.contains('internal server error')) {
      return 'Server error. Please try again later.';
    }

    if (errorString.contains('timeout') || errorString.contains('network')) {
      return 'Connection timeout. Please check your internet connection.';
    }

    if (errorString.contains('connection')) {
      return 'Unable to connect. Please check your internet connection.';
    }

    // Default message for any other errors
    return 'Login failed. Please try again.';
  }
}
