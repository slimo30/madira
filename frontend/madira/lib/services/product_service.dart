import 'package:dio/dio.dart';
import '../core/network/dio_client.dart';
import '../core/constants/api_constants.dart';
import '../models/product_model.dart';

class ProductService {
  final _dio = DioClient().dio;

  // Get all products with pagination and filters
  Future<Map<String, dynamic>> getProducts({
    int page = 1,
    int pageSize = 10,
    String? search,
    bool? isActive,
    String? unit,
    String? ordering,
  }) async {
    try {
      print(' API REQUEST: GET /products/');
      print(' Full URL: ${ApiConstants.baseUrl}${ApiConstants.products}');
      print(' Pagination: page=$page, pageSize=$pageSize');
      if (search != null && search.isNotEmpty) print(' Search: $search');
      print(' Active Only: true (filtering active products)');
      if (unit != null && unit != 'all') print(' Unit Filter: $unit');
      if (ordering != null) print(' Ordering: $ordering');
      print('=' * 60);

      final response = await _dio.get(
        ApiConstants.products,
        queryParameters: {
          'page': page,
          'page_size': pageSize,
          if (search != null && search.isNotEmpty) 'search': search,
          'is_active': true, // Always fetch only active products
          if (unit != null && unit != 'all') 'unit': unit,
          if (ordering != null) 'ordering': ordering,
        },
      );

      print(' API RESPONSE: SUCCESS');
      print(' Status Code: ${response.statusCode}');

      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final products =
            (data['results'] as List?)
                ?.map(
                  (item) => ProductModel.fromJson(item as Map<String, dynamic>),
                )
                .toList() ??
            [];

        print(' Number of Products: ${products.length}');
        print(' Total Count: ${data['count']}');
        print('=' * 60 + '\n');

        return {
          'count': data['count'] as int? ?? 0,
          'next': data['next'] as String?,
          'previous': data['previous'] as String?,
          'results': products,
        };
      }
      throw Exception(
        'Failed to fetch products - Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      print(' API ERROR: DioException');
      print('️ Message: ${e.message}');
      print(' Status Code: ${e.response?.statusCode}');
      print('=' * 60 + '\n');
      throw Exception('Error fetching products: ${e.message}');
    } catch (e) {
      print(' API ERROR: Generic Exception');
      print('️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error fetching products: $e');
    }
  }

  // Get product by ID
  Future<ProductModel> getProductById(int productId) async {
    try {
      final endpoint = '${ApiConstants.products}$productId/';

      print(' API REQUEST: GET /products/$productId/');
      print(' Full URL: ${ApiConstants.baseUrl}$endpoint');
      print('=' * 60);

      final response = await _dio.get(endpoint);

      print(' API RESPONSE: SUCCESS');
      print(' Status Code: ${response.statusCode}');
      print('=' * 60 + '\n');

      if (response.statusCode == 200) {
        final product = ProductModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        print('    Product: ${product.name} (ID: ${product.id})');
        return product;
      }
      throw Exception(
        'Failed to fetch product - Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      print(' API ERROR: DioException');
      print('️ Message: ${e.message}');
      print('=' * 60 + '\n');
      throw Exception('Error fetching product: ${e.message}');
    } catch (e) {
      print(' API ERROR: Generic Exception');
      print('️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error fetching product: $e');
    }
  }

  // Create product
  Future<ProductModel> createProduct({
    required String name,
    required String unit,
    required double currentQuantity,
    required String description,
    double? initialPrice,
  }) async {
    try {
      final data = {
        'name': name,
        'unit': unit,
        'current_quantity': currentQuantity,
        'description': description,
        if (initialPrice != null) 'initial_price': initialPrice,
      };

      print(' API REQUEST: POST /products/');
      print(' Full URL: ${ApiConstants.baseUrl}${ApiConstants.products}');
      print(' Request Data:');
      print('   - Name: $name');
      print('   - Unit: $unit');
      print('   - Quantity: $currentQuantity');
      if (initialPrice != null) {
        print('   - Initial Price: $initialPrice');
      }
      print('=' * 60);

      final response = await _dio.post(ApiConstants.products, data: data);

      print(' API RESPONSE: SUCCESS');
      print(' Status Code: ${response.statusCode}');
      print('=' * 60 + '\n');

      if (response.statusCode == 201 || response.statusCode == 200) {
        final product = ProductModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        print('    Product Created: ${product.name} (ID: ${product.id})');
        return product;
      }
      throw Exception(
        'Failed to create product - Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      print(' API ERROR: DioException');
      print('️ Message: ${e.message}');
      print(' Status Code: ${e.response?.statusCode}');
      print(' Response: ${e.response?.data}');
      print('=' * 60 + '\n');
      if (e.response?.statusCode == 400) {
        final errorData = e.response?.data;
        if (errorData is Map) {
          // Extract error message from response
          final errorValues = errorData.values.toList();
          if (errorValues.isNotEmpty) {
            final firstError = errorValues.first;
            if (firstError is List && firstError.isNotEmpty) {
              throw Exception(firstError.first.toString());
            }
          }
        }
        final errorDetail =
            e.response?.data['detail'] ??
            e.response?.data['error'] ??
            'Invalid product data';
        throw Exception(errorDetail);
      }
      throw Exception('Error creating product: ${e.message}');
    } catch (e) {
      print(' API ERROR: Generic Exception');
      print('️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error creating product: $e');
    }
  }

  // Update product
  Future<ProductModel> updateProduct(
    int productId, {
    required String name,
    required String unit,
    required double currentQuantity,
    required String description,
    required bool isActive,
  }) async {
    try {
      final endpoint = '${ApiConstants.products}$productId/';
      final data = {
        'name': name,
        'unit': unit,
        'current_quantity': currentQuantity,
        'description': description,
        'is_active': isActive,
      };

      print(' API REQUEST: PUT /products/$productId/');
      print(' Full URL: ${ApiConstants.baseUrl}$endpoint');
      print(' Request Data:');
      print('   - Name: $name');
      print('   - Unit: $unit');
      print('   - Quantity: $currentQuantity');
      print('   - Active: $isActive');
      print('=' * 60);

      final response = await _dio.put(endpoint, data: data);

      print(' API RESPONSE: SUCCESS');
      print(' Status Code: ${response.statusCode}');
      print('=' * 60 + '\n');

      if (response.statusCode == 200) {
        final product = ProductModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        print('    Product Updated: ${product.name} (ID: ${product.id})');
        return product;
      }
      throw Exception(
        'Failed to update product - Status: ${response.statusCode}',
      );
    } on DioException catch (e) {
      print(' API ERROR: DioException');
      print('️ Message: ${e.message}');
      print('=' * 60 + '\n');
      throw Exception('Error updating product: ${e.message}');
    } catch (e) {
      print(' API ERROR: Generic Exception');
      print('️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error updating product: $e');
    }
  }

  // Delete product
  Future<void> deleteProduct(int productId) async {
    try {
      final endpoint = '${ApiConstants.products}$productId/';

      print(' API REQUEST: DELETE /products/$productId/');
      print(' Full URL: ${ApiConstants.baseUrl}$endpoint');
      print('=' * 60);

      final response = await _dio.delete(endpoint);

      print(' API RESPONSE: SUCCESS');
      print(' Status Code: ${response.statusCode}');
      print('    Product $productId deleted successfully');
      print('=' * 60 + '\n');

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception(
          'Failed to delete product - Status: ${response.statusCode}',
        );
      }
    } on DioException catch (e) {
      print(' API ERROR: DioException');
      print('️ Message: ${e.message}');
      print('=' * 60 + '\n');
      throw Exception('Error deleting product: ${e.message}');
    } catch (e) {
      print(' API ERROR: Generic Exception');
      print('️ Error: $e');
      print('=' * 60 + '\n');
      throw Exception('Error deleting product: $e');
    }
  }

  // Deactivate product
  Future<ProductModel> deactivateProduct(int productId) async {
    try {
      final endpoint = '${ApiConstants.products}$productId/';

      // First get the product to retain its data
      final currentProduct = await getProductById(productId);

      final data = {
        'name': currentProduct.name,
        'unit': currentProduct.unit,
        'current_quantity': double.parse(currentProduct.currentQuantity),
        'description': currentProduct.description,
        'is_active': false,
      };

      print(' API REQUEST: PUT /products/$productId/ (Deactivate)');
      print('=' * 60);

      final response = await _dio.put(endpoint, data: data);

      if (response.statusCode == 200) {
        final product = ProductModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        print('    Product Deactivated: ${product.name}');
        return product;
      }
      throw Exception('Failed to deactivate product');
    } catch (e) {
      throw Exception('Error deactivating product: $e');
    }
  }

  // Reactivate product
  Future<ProductModel> reactivateProduct(int productId) async {
    try {
      final endpoint = '${ApiConstants.products}$productId/';

      // First get the product to retain its data
      final currentProduct = await getProductById(productId);

      final data = {
        'name': currentProduct.name,
        'unit': currentProduct.unit,
        'current_quantity': double.parse(currentProduct.currentQuantity),
        'description': currentProduct.description,
        'is_active': true,
      };

      print(' API REQUEST: PUT /products/$productId/ (Reactivate)');
      print('=' * 60);

      final response = await _dio.put(endpoint, data: data);

      if (response.statusCode == 200) {
        final product = ProductModel.fromJson(
          response.data as Map<String, dynamic>,
        );
        print('    Product Reactivated: ${product.name}');
        return product;
      }
      throw Exception('Failed to reactivate product');
    } catch (e) {
      throw Exception('Error reactivating product: $e');
    }
  }
}
