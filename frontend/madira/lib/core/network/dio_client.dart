import 'package:dio/dio.dart';
import '../storage/storage_service.dart';
import '../constants/api_constants.dart';

class DioClient {
  static final DioClient _instance = DioClient._internal();
  factory DioClient() => _instance;
  late Dio dio;

  DioClient._internal() {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConstants.baseUrl,
        connectTimeout: ApiConstants.connectTimeout,
        receiveTimeout: ApiConstants.receiveTimeout,
        headers: ApiConstants.defaultHeaders,
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await StorageService().readToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          return handler.next(options);
        },
        onError: (error, handler) {
          print("❌ API Error: ${error.response?.statusCode} ${error.message}");
          return handler.next(error);
        },
      ),
    );
  }

  /// Update the base URL dynamically (used when master IP changes)
  void updateBaseUrl(String newBaseUrl) {
    print('🔄 Updating Dio base URL to: $newBaseUrl');
    dio.options.baseUrl = '$newBaseUrl/api';
  }
}
