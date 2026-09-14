import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:eco2shop/api/api_service.dart';
import 'package:eco2shop/feature/products/providers/product_provider.dart';
import 'package:eco2shop/feature/products/screens/product_detail_screen.dart';

void main() {
  testWidgets('ProductDetailScreen fetches API product details and renders',
      (WidgetTester tester) async {
    final mockClient = MockClient((request) async {
      expect(
        request.url.toString(),
        equals('https://dummyjson.com/products/1'),
      );
      return http.Response(
        jsonEncode({
          "id": 1,
          "title": "Essence Mascara Lash Princess",
          "description": "Popular volumizing mascara.",
          "category": "beauty",
          "price": 9.99,
          "discountPercentage": 10.5,
          "rating": 4.5,
          "stock": 99,
          "tags": ["beauty"],
          "brand": "Essence",
          "sku": "BEA-ESS-001",
          "weight": 1.0,
          "dimensions": {"width": 1.0, "height": 1.0, "depth": 1.0},
          "warrantyInformation": "1 week warranty",
          "shippingInformation": "Ships in 3-5 days",
          "availabilityStatus": "In Stock",
          "reviews": [
            {
              "rating": 5,
              "comment": "Awesome!",
              "date": "2025-04-30T09:41:02.053Z",
              "reviewerName": "Eleanor",
              "reviewerEmail": "eleanor@test.com"
            }
          ],
          "returnPolicy": "No return policy",
          "minimumOrderQuantity": 1,
          "meta": {
            "createdAt": "2025-04-30T09:41:02.053Z",
            "updatedAt": "2025-04-30T09:41:02.053Z",
            "barcode": "12345",
            "qrCode": "url"
          },
          "images": [],
          "thumbnail": ""
        }),
        200,
      );
    });

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          apiServiceProvider.overrideWithValue(ApiService(client: mockClient)),
        ],
        child: const MaterialApp(
          home: ProductDetailScreen(productId: 1),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Product Details'), findsOneWidget);
    expect(find.text('Essence Mascara Lash Princess'), findsOneWidget);
    expect(find.text('RM 9.99'), findsOneWidget);
    expect(find.text('Add to Cart'), findsOneWidget);
  });
}
