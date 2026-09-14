import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eco2shop/feature/orders/models/order.dart';
import 'package:eco2shop/feature/orders/providers/order_provider.dart';

void main() {
  const address = ShippingAddress(
    fullName: 'Muhammad Danish Fitri',
    phone: '0123456789',
    addressLine: '12, Jalan Eco 2',
    city: 'Shah Alam',
    postcode: '40150',
    state: 'Selangor',
  );

  OrderItem item({int id = 1, double price = 10, int quantity = 1}) {
    return OrderItem(
      productId: id,
      title: 'Product $id',
      thumbnail: '',
      unitPrice: price,
      quantity: quantity,
    );
  }

  group('OrderProvider', () {
    test('saves orders newest first', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final notifier = container.read(orderProvider.notifier);

      final first = notifier.placeOrder(
        items: [item(price: 20, quantity: 2)],
        address: address,
        paymentMethod: PaymentMethod.card,
        paymentDetail: 'Visa •••• 4242',
        paymentReference: 'PAY-000001',
        shippingFee: 4.90,
      );
      final second = notifier.placeOrder(
        items: [item(id: 2, price: 120)],
        address: address,
        paymentMethod: PaymentMethod.cod,
        paymentDetail: 'Pay on delivery',
        paymentReference: 'PAY-000002',
        shippingFee: 0,
      );

      final orders = container.read(orderProvider).orders;
      expect(orders.map((order) => order.id), [second.id, first.id]);
      expect(first.status, OrderStatus.paid);
      expect(second.status, OrderStatus.confirmed);
      expect(first.subtotal, 40);
      expect(first.shippingFee, 4.90);
      expect(first.total, closeTo(44.90, 0.001));
      expect(second.shippingFee, 0);
      expect(second.total, 120);
      expect(container.read(orderProvider).findById(first.id)?.paymentDetail,
          'Visa •••• 4242');
    });
  });
}
