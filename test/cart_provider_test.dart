import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eco2shop/feature/products/models/product_model.dart';
import 'package:eco2shop/feature/cart/providers/cart_provider.dart';

void main() {
  group('CartProvider Tests', () {
    final sampleProduct = Product(
      id: 1,
      title: 'Mascara',
      description: 'Lash Princess',
      category: 'beauty',
      price: 10.0,
      discountPercentage: 0.0,
      rating: 4.5,
      stock: 5,
      tags: ['beauty'],
      sku: 'BEA-001',
      weight: 1.0,
      dimensions: Dimensions(width: 1, height: 1, depth: 1),
      warrantyInformation: 'None',
      shippingInformation: 'Fast',
      availabilityStatus: 'In Stock',
      reviews: [],
      returnPolicy: 'None',
      minimumOrderQuantity: 1,
      meta: ProductMeta(
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        barcode: '',
        qrCode: '',
      ),
      images: [],
      thumbnail: '',
    );

    test('addToCart adds product and updates total price and count', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(cartProvider.notifier);

      expect(container.read(cartProvider).isEmpty, isTrue);

      notifier.addToCart(sampleProduct, quantity: 2);

      final state = container.read(cartProvider);
      expect(state.isEmpty, isFalse);
      expect(state.totalItemCount, equals(2));
      expect(state.totalPrice, equals(20.0));
    });

    test('updateQuantity adjusts count and removes item when quantity reaches 0',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(cartProvider.notifier);

      notifier.addToCart(sampleProduct, quantity: 1);
      expect(container.read(cartProvider).totalItemCount, equals(1));

      notifier.updateQuantity(1, 1);
      expect(container.read(cartProvider).totalItemCount, equals(2));

      notifier.updateQuantity(1, -2);
      expect(container.read(cartProvider).isEmpty, isTrue);
    });
  });
}
