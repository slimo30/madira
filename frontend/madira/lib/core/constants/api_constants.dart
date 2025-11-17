// lib/core/constants/api_endpoints.dart
class ApiConstants {
  // Base URL for the API
  static const String baseUrl = "http://127.0.0.1:8000/api";

  // Timeout configurations
  static const Duration connectTimeout = Duration(seconds: 10);
  static const Duration receiveTimeout = Duration(seconds: 10);

  // Headers
  static const Map<String, String> defaultHeaders = {
    'Content-Type': 'application/json',
  };

  // Auth Endpoints
  static const String loginEndpoint = "/login/";
  static const String logoutEndpoint = "/logout/";

  // User Management Endpoints
  static const String usersEndpoint = "/users/";
  static const String usersCreateEndpoint = "/users/create/";
  static const String usersDetailEndpoint = "/users"; // /users/{id}/
  static const String usersDeactivateEndpoint =
      "/users"; // /users/{id}/deactivate/
  static const String usersReactivateEndpoint =
      "/users"; // /users/{id}/reactivate/

  // Client Management Endpoints
  static const String clientsEndpoint = "/clients/";
  static const String clientsDetailEndpoint = "/clients"; // /clients/{id}/
  static const String clientsCompleteEndpoint =
      "/clients"; // /clients/{id}/complete/
  static const String clientsDeactivateEndpoint =
      "/clients"; // /clients/{id}/ (DELETE request)

  // Input Management Endpoints
  static const String inputs = "/inputs/";
  static const String inputsDetail = "/inputs"; // /inputs/{id}/

  // Order Management Endpoints
  static const String orders = "/orders/";

  static const String dashboardEndpoint = "/dashboard/";

  static const String products = "/products/";

  // Stock Movements Endpoints
  static const String stockMovements = "/stock-movements/";
  static const String stockMovementsByProduct = "/stock-movements/by_product/";

  // Output Management Endpoints
  static const String outputs = "/outputs/";
  static const String outputsDetail = "/outputs"; // /outputs/{id}/
  static const String outputsByType = "/outputs/by_type/";
  static const String outputsByOrder = "/outputs/by_order/";
  static const String outputsByInput = "/outputs/by_input/";
  static const String outputsStatistics = "/outputs/statistics/";
  static const String outputsRelatedData =
      "/outputs"; // /outputs/{id}/related_data/
}
