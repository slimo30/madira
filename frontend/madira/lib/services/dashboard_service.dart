import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';

class DashboardService {
  final _dio = DioClient().dio;

  Future<Map<String, dynamic>> getDashboardData({
    String period = 'all_time',
  }) async {
    print(' DashboardService: Fetching dashboard data...');
    print(' Period: $period');

    try {
      print(' DashboardService: Sending GET request to API...');
      final response = await _dio.get(
        ApiConstants.dashboardEndpoint,
        queryParameters: {'period': period},
      );

      print(' DashboardService: API Response received!');
      print(' Status Code: ${response.statusCode}');
      print(' Response Data: ${response.data}');

      return response.data as Map<String, dynamic>;
    } catch (e) {
      print(' DashboardService: Failed to fetch dashboard data: $e');
      throw Exception(_getDashboardErrorMessage(e));
    }
  }

  String _getDashboardErrorMessage(dynamic error) {
    String errorString = error.toString().toLowerCase();

    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return 'Session expired. Please login again.';
    }

    if (errorString.contains('403') || errorString.contains('forbidden')) {
      return 'Access denied. You do not have permission to view dashboard.';
    }

    if (errorString.contains('404') || errorString.contains('not found')) {
      return 'Dashboard service not available. Please contact support.';
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

    return 'Failed to load dashboard. Please try again.';
  }
}
