// import 'package:dio/dio.dart';
// import '../storage/storage_service.dart';
// import '../constants/api_constants.dart';

// class DioClient {
//   static final DioClient _instance = DioClient._internal();
//   factory DioClient() => _instance;
//   late Dio dio;

//   DioClient._internal() {
//     dio = Dio(
//       BaseOptions(
//         baseUrl: ApiConstants.baseUrl,
//         connectTimeout: ApiConstants.connectTimeout,
//         receiveTimeout: ApiConstants.receiveTimeout,
//         headers: ApiConstants.defaultHeaders,
//       ),
//     );

//     dio.interceptors.add(
//       InterceptorsWrapper(
//         onRequest: (options, handler) async {
//           final token = await StorageService().readToken();
//           if (token != null) {
//             options.headers['Authorization'] = 'Bearer $token';
//           }
//           return handler.next(options);
//         },
//         onError: (error, handler) {
//           debugPrint(" API Error: ${error.response?.statusCode} ${error.message}");
//           return handler.next(error);
//         },
//       ),
//     );
//   }

//   /// Update the base URL dynamically (used when master IP changes)
//   void updateBaseUrl(String newBaseUrl) {
//     debugPrint(' Updating Dio base URL to: $newBaseUrl');
//     dio.options.baseUrl = '$newBaseUrl/api';
//   }
// }
// lib/core/network/dio_client.dart
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
        baseUrl: ApiConstants.baseUrl, // Default: http://127.0.0.1:8000/api
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
          print(" API Error: ${error.response?.statusCode} ${error.message}");
          return handler.next(error);
        },
      ),
    );
  }

  /// Update base URL for slave mode (connecting to master)
  void updateBaseUrl(String newBaseUrl) {
    // Ensure it ends with /api
    final url = newBaseUrl.endsWith('/api') ? newBaseUrl : '$newBaseUrl/api';

    dio.options.baseUrl = url;
    print(' Dio base URL updated to: $url');
  }

  /// Get current base URL
  String getBaseUrl() {
    return dio.options.baseUrl;
  }

  /// Reset to default localhost (for master mode)
  void resetToLocalhost() {
    dio.options.baseUrl = ApiConstants.baseUrl;
    print(' Dio base URL reset to: ${ApiConstants.baseUrl}');
  }
}
