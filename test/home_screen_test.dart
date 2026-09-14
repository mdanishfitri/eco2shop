import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:eco2shop/api/api_service.dart';
import 'package:eco2shop/feature/products/providers/product_provider.dart';
import 'package:eco2shop/feature/home/screens/home_screen.dart';

void main() {
  testWidgets('HomeScreen renders Header, Chips, and BottomNav', (
    WidgetTester tester,
  ) async {
    final mockClient = MockClient((request) async {
      return http.Response(
        jsonEncode({
          "products": [
            {
              "id": 1,
              "title": "Test Product",
              "category": "beauty",
              "price": 9.99,
              "discountPercentage": 10.0,
              "rating": 4.5,
              "stock": 10,
              "tags": ["beauty"],
              "sku": "BEA-001",
              "weight": 1,
              "dimensions": {"width": 1, "height": 1, "depth": 1},
              "warrantyInformation": "None",
              "shippingInformation": "Fast",
              "availabilityStatus": "In Stock",
              "reviews": [],
              "returnPolicy": "None",
              "minimumOrderQuantity": 1,
              "meta": {
                "createdAt": "2025-01-01T00:00:00.000Z",
                "updatedAt": "2025-01-01T00:00:00.000Z",
                "barcode": "123",
                "qrCode": "url",
              },
              "images": [],
              "thumbnail": "",
            },
          ],
          "total": 1,
          "skip": 0,
          "limit": 20,
        }),
        200,
      );
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiServiceProvider.overrideWithValue(ApiService(client: mockClient)),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Hello, User'), findsOneWidget);

    expect(find.text('All'), findsOneWidget);
    expect(find.text('Beauty'), findsNWidgets(2));

    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Catalog'), findsOneWidget);
    expect(find.text('Cart'), findsOneWidget);
    expect(find.text('Account'), findsOneWidget);
  });
}
