import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:eco2shop/api/api_service.dart';
import 'package:eco2shop/api/api_exception.dart';

void main() {
  group('ApiService Tests', () {
    test('getProducts returns ProductResponse on 200 success', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(),
            equals('https://dummyjson.com/products?limit=20&skip=0'));
        return http.Response(
          jsonEncode({
            "products": [
              {"id": 1, "title": "Test Product"}
            ],
            "total": 100,
            "skip": 0,
            "limit": 20
          }),
          200,
        );
      });

      final apiService = ApiService(client: mockClient);
      final result = await apiService.getProducts();

      expect(result.total, equals(100));
      expect(result.products.length, equals(1));
      expect(result.products.first.title, equals('Test Product'));
    });

    test('getProductById returns Product on 200 success', () async {
      final mockClient = MockClient((request) async {
        expect(
            request.url.toString(), equals('https://dummyjson.com/products/1'));
        return http.Response(
          jsonEncode({"id": 1, "title": "Mascara"}),
          200,
        );
      });

      final apiService = ApiService(client: mockClient);
      final product = await apiService.getProductById(1);

      expect(product.id, equals(1));
      expect(product.title, equals('Mascara'));
    });

    test('searchProducts returns ProductResponse on 200 success', () async {
      final mockClient = MockClient((request) async {
        expect(
          request.url.toString(),
          equals('https://dummyjson.com/products/search?q=phone&limit=20&skip=0'),
        );
        return http.Response(
          jsonEncode({
            "products": [
              {"id": 2, "title": "iPhone 13"}
            ],
            "total": 1,
            "skip": 0,
            "limit": 20
          }),
          200,
        );
      });

      final apiService = ApiService(client: mockClient);
      final result = await apiService.searchProducts('phone');

      expect(result.products.length, equals(1));
      expect(result.products.first.title, equals('iPhone 13'));
    });

    test('getProductById throws ApiException with message on 404 Not Found',
        () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({"message": "Product with id '999' not found"}),
          404,
        );
      });

      final apiService = ApiService(client: mockClient);

      expect(
        () => apiService.getProductById(999),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', equals(404))
              .having((e) => e.message, 'message',
                  equals("Product with id '999' not found")),
        ),
      );
    });

    test('getProducts throws ApiException on 500 Internal Server Error',
        () async {
      final mockClient = MockClient((request) async {
        return http.Response('Internal Server Error', 500);
      });

      final apiService = ApiService(client: mockClient);

      expect(
        () => apiService.getProducts(),
        throwsA(
          isA<ApiException>()
              .having((e) => e.statusCode, 'statusCode', equals(500))
              .having((e) => e.message, 'message',
                  equals('Internal Server Error')),
        ),
      );
    });
  });
}
