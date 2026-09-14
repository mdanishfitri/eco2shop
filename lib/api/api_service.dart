import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:eco2shop/feature/products/models/product_model.dart';
import 'package:eco2shop/api/api_exception.dart';

class ApiService {
  static const String baseUrl = 'https://dummyjson.com';

  final http.Client _client;

  ApiService({http.Client? client}) : _client = client ?? http.Client();

  dynamic _processResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.body.isEmpty) return null;
      return jsonDecode(response.body);
    } else {
      String errorMessage = 'HTTP Error ${response.statusCode}';
      dynamic errorBody;

      try {
        if (response.body.isNotEmpty) {
          errorBody = jsonDecode(response.body);
          if (errorBody is Map<String, dynamic> &&
              errorBody.containsKey('message')) {
            errorMessage = errorBody['message'].toString();
          } else {
            errorMessage = response.body;
          }
        }
      } catch (_) {
        if (response.body.isNotEmpty) {
          errorMessage = response.body;
        }
      }

      throw ApiException(
        statusCode: response.statusCode,
        message: errorMessage,
        body: errorBody,
      );
    }
  }

  Future<ProductResponse> getProducts({int limit = 20, int skip = 0}) async {
    try {
      final uri = Uri.parse('$baseUrl/products?limit=$limit&skip=$skip');
      final response = await _client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final data = _processResponse(response) as Map<String, dynamic>;
      return ProductResponse.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Network error or invalid request: $e',
      );
    }
  }

  Future<ProductResponse> getProductsByCategory(
    String category, {
    int limit = 20,
    int skip = 0,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/products/category/${Uri.encodeComponent(category)}?limit=$limit&skip=$skip',
      );
      final response = await _client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final data = _processResponse(response) as Map<String, dynamic>;
      return ProductResponse.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Network error or invalid request: $e',
      );
    }
  }

  Future<Product> getProductById(int id) async {
    try {
      final uri = Uri.parse('$baseUrl/products/$id');
      final response = await _client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final data = _processResponse(response) as Map<String, dynamic>;
      return Product.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Network error or invalid request: $e',
      );
    }
  }

  Future<ProductResponse> searchProducts(
    String query, {
    int limit = 20,
    int skip = 0,
  }) async {
    try {
      final uri = Uri.parse(
        '$baseUrl/products/search?q=${Uri.encodeComponent(query)}&limit=$limit&skip=$skip',
      );
      final response = await _client.get(
        uri,
        headers: {'Content-Type': 'application/json'},
      );

      final data = _processResponse(response) as Map<String, dynamic>;
      return ProductResponse.fromJson(data);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException(
        statusCode: 0,
        message: 'Network error or invalid request: $e',
      );
    }
  }
}
