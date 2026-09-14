import 'package:flutter_test/flutter_test.dart';
import 'package:eco2shop/feature/products/models/product_model.dart';

void main() {
  group('ProductModel Tests', () {
    final sampleJson = {
      "products": [
        {
          "id": 1,
          "title": "Essence Mascara Lash Princess",
          "description":
              "The Essence Mascara Lash Princess is a popular mascara...",
          "category": "beauty",
          "price": 9.99,
          "discountPercentage": 10.48,
          "rating": 2.56,
          "stock": 99,
          "tags": ["beauty", "mascara"],
          "brand": "Essence",
          "sku": "BEA-ESS-ESS-001",
          "weight": 4,
          "dimensions": {"width": 15.14, "height": 13.08, "depth": 22.99},
          "warrantyInformation": "1 week warranty",
          "shippingInformation": "Ships in 3-5 business days",
          "availabilityStatus": "In Stock",
          "reviews": [
            {
              "rating": 3,
              "comment": "Would not recommend!",
              "date": "2025-04-30T09:41:02.053Z",
              "reviewerName": "Eleanor Collins",
              "reviewerEmail": "eleanor.collins@x.dummyjson.com",
            },
          ],
          "returnPolicy": "No return policy",
          "minimumOrderQuantity": 48,
          "meta": {
            "createdAt": "2025-04-30T09:41:02.053Z",
            "updatedAt": "2025-04-30T09:41:02.053Z",
            "barcode": "5784719087687",
            "qrCode": "https://cdn.dummyjson.com/public/qr-code.png",
          },
          "images": [
            "https://cdn.dummyjson.com/product-images/beauty/essence-mascara-lash-princess/1.webp",
          ],
          "thumbnail":
              "https://cdn.dummyjson.com/product-images/beauty/essence-mascara-lash-princess/thumbnail.webp",
        },
        {
          "id": 16,
          "title": "Apple",
          "description": "Fresh and crisp apples...",
          "category": "groceries",
          "price": 1.99,
          "discountPercentage": 12.62,
          "rating": 4.19,
          "stock": 8,
          "tags": ["fruits"],
          "sku": "GRO-BRD-APP-016",
          "weight": 9,
          "dimensions": {"width": 13.66, "height": 11.01, "depth": 9.73},
          "warrantyInformation": "3 year warranty",
          "shippingInformation": "Ships in 2 weeks",
          "availabilityStatus": "In Stock",
          "reviews": [],
          "returnPolicy": "90 days return policy",
          "minimumOrderQuantity": 7,
          "meta": {
            "createdAt": "2025-04-30T09:41:02.053Z",
            "updatedAt": "2025-04-30T09:41:02.053Z",
            "barcode": "7962803553314",
            "qrCode": "https://cdn.dummyjson.com/public/qr-code.png",
          },
          "images": [
            "https://cdn.dummyjson.com/product-images/groceries/apple/1.webp",
          ],
          "thumbnail":
              "https://cdn.dummyjson.com/product-images/groceries/apple/thumbnail.webp",
        },
      ],
      "total": 194,
      "skip": 0,
      "limit": 20,
    };

    test('should parse ProductResponse correctly', () {
      final response = ProductResponse.fromJson(sampleJson);

      expect(response.total, equals(194));
      expect(response.products.length, equals(2));

      final product1 = response.products[0];
      expect(product1.id, equals(1));
      expect(product1.title, equals('Essence Mascara Lash Princess'));
      expect(product1.brand, equals('Essence'));
      expect(product1.reviews.length, equals(1));
      expect(product1.dimensions.width, equals(15.14));

      final product16 = response.products[1];
      expect(product16.id, equals(16));
      expect(product16.title, equals('Apple'));
      expect(product16.brand, isNull);
    });
  });
}
