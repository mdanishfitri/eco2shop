import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:eco2shop/api/api_service.dart';
import 'package:eco2shop/feature/products/providers/product_provider.dart';

void main() {
  group('Riverpod ProductNotifier Tests', () {
    test('fetchProducts updates state on success', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            "products": [
              {"id": 1, "title": "Product 1"},
              {"id": 2, "title": "Product 2"},
            ],
            "total": 50,
            "skip": 0,
            "limit": 20,
          }),
          200,
        );
      });

      final container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(ApiService(client: mockClient)),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(productNotifierProvider.notifier);

      expect(container.read(productNotifierProvider).isLoading, isFalse);
      expect(container.read(productNotifierProvider).products, isEmpty);

      await notifier.fetchProducts();

      final state = container.read(productNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.products.length, equals(2));
      expect(state.total, equals(50));
      expect(state.skip, equals(2));
      expect(state.hasMore, isTrue);
      expect(state.hasError, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('loadMoreProducts appends items and updates skip offset', () async {
      int requestCount = 0;
      final mockClient = MockClient((request) async {
        requestCount++;
        if (requestCount == 1) {
          expect(request.url.toString(), contains('skip=0'));
          return http.Response(
            jsonEncode({
              "products": [
                {"id": 1, "title": "Product 1"},
                {"id": 2, "title": "Product 2"},
              ],
              "total": 4,
              "skip": 0,
              "limit": 2,
            }),
            200,
          );
        } else {
          expect(request.url.toString(), contains('skip=2'));
          return http.Response(
            jsonEncode({
              "products": [
                {"id": 3, "title": "Product 3"},
                {"id": 4, "title": "Product 4"},
              ],
              "total": 4,
              "skip": 2,
              "limit": 2,
            }),
            200,
          );
        }
      });

      final container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(ApiService(client: mockClient)),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(productNotifierProvider.notifier);

      await notifier.fetchProducts();
      expect(
        container.read(productNotifierProvider).products.length,
        equals(2),
      );
      expect(container.read(productNotifierProvider).skip, equals(2));
      expect(container.read(productNotifierProvider).hasMore, isTrue);

      await notifier.loadMoreProducts();
      expect(
        container.read(productNotifierProvider).products.length,
        equals(4),
      );
      expect(container.read(productNotifierProvider).skip, equals(4));
      expect(container.read(productNotifierProvider).hasMore, isFalse);
    });

    test('fetchProducts sets errorMessage on failure', () async {
      final mockClient = MockClient((request) async {
        return http.Response(jsonEncode({"message": "Internal error"}), 500);
      });

      final container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(ApiService(client: mockClient)),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(productNotifierProvider.notifier);

      await notifier.fetchProducts();

      final state = container.read(productNotifierProvider);
      expect(state.isLoading, isFalse);
      expect(state.hasError, isTrue);
      expect(state.errorMessage, equals("Internal error"));
    });

    test('searchProducts resets products and sets searchQuery', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.toString(), contains('q=mascara'));
        return http.Response(
          jsonEncode({
            "products": [
              {"id": 1, "title": "Essence Mascara"},
            ],
            "total": 1,
            "skip": 0,
            "limit": 20,
          }),
          200,
        );
      });

      final container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(ApiService(client: mockClient)),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(productNotifierProvider.notifier);

      await notifier.searchProducts('mascara');

      final state = container.read(productNotifierProvider);
      expect(state.searchQuery, equals('mascara'));
      expect(state.products.length, equals(1));
      expect(state.products.first.title, equals('Essence Mascara'));
    });

    test('productDetailProvider fetches single product details', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({"id": 5, "title": "Red Nail Polish"}),
          200,
        );
      });

      final container = ProviderContainer(
        overrides: [
          apiServiceProvider.overrideWithValue(ApiService(client: mockClient)),
        ],
      );
      addTearDown(container.dispose);

      final product = await container.read(productDetailProvider(5).future);

      expect(product.id, equals(5));
      expect(product.title, equals('Red Nail Polish'));
    });
  });
}
