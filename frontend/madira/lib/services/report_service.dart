import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../core/network/dio_client.dart';

class ReportService {
  final dio = DioClient().dio;

  // GET /api/reports/estimate
  Future<Map<String, dynamic>> getEstimate({
    required String type, // daily, weekly, monthly, all
    String? startDate,
    String? endDate,
    String? clientId,
    String? orderId,
    String? supplierId,
    String? productId,
    String? status,
    bool includeRelations = true,
  }) async {
    try {
      final response = await dio.get(
        ApiConstants.reportEstimateEndpoint,
        queryParameters: {
          'type': type,
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
          if (clientId != null) 'client_id': clientId,
          if (orderId != null) 'order_id': orderId,
          if (supplierId != null) 'supplier_id': supplierId,
          if (productId != null) 'product_id': productId,
          if (status != null) 'status': status,
          'include_relations': includeRelations.toString(),
        },
      );
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception(_getReportErrorMessage(e));
    }
  }

  Future<Response<dynamic>> downloadReport({
    required String type,
    String? startDate,
    String? endDate,
    String? clientId,
    String? orderId,
    String? supplierId,
    String? productId,
    String? status,
    bool includeRelations = true,
    ProgressCallback? onReceiveProgress,
  }) async {
    try {
      final response = await dio.get(
        ApiConstants.reportDownloadEndpoint,
        queryParameters: {
          'type': type,
          if (startDate != null) 'start_date': startDate,
          if (endDate != null) 'end_date': endDate,
          if (clientId != null) 'client_id': clientId,
          if (orderId != null) 'order_id': orderId,
          if (supplierId != null) 'supplier_id': supplierId,
          if (productId != null) 'product_id': productId,
          if (status != null) 'status': status,
          'include_relations': includeRelations.toString(),
        },
        options: Options(responseType: ResponseType.bytes),
        onReceiveProgress: onReceiveProgress,
      );
      return response;
    } catch (e) {
      throw Exception(_getReportErrorMessage(e));
    }
  }

  String _getReportErrorMessage(dynamic error) {
    final errorString = error.toString().toLowerCase();

    if (errorString.contains('401') || errorString.contains('unauthorized')) {
      return 'Session expired. Please login again.';
    }
    if (errorString.contains('403') || errorString.contains('forbidden')) {
      return 'Access denied. You do not have permission to generate reports.';
    }
    if (errorString.contains('404') || errorString.contains('not found')) {
      return 'Report service not available. Please contact support.';
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

    return 'Failed to generate report. Please try again.';
  }
}
