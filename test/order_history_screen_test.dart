import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eco2shop/feature/orders/models/order.dart';
import 'package:eco2shop/feature/orders/providers/order_provider.dart';
import 'package:eco2shop/feature/orders/screens/order_history_screen.dart';

void main() {
  const address = ShippingAddress(
    fullName: 'Muhammad Danish Fitri',
    phone: '0123456789',
    addressLine: '12, Jalan Eco 2',
    city: 'Shah Alam',
    postcode: '40150',
    state: 'Selangor',
  );

  testWidgets('shows an empty state when there are no orders', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: OrderHistoryScreen()),
      ),
    );

    expect(find.text('No orders yet'), findsOneWidget);
    expect(find.text('Order History'), findsOneWidget);
  });

  testWidgets('lists a placed order and opens its details', (tester) async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final order = container.read(orderProvider.notifier).placeOrder(
          items: const [
            OrderItem(
              productId: 1,
              title: 'Lash Princess',
              thumbnail: '',
              unitPrice: 12.5,
              quantity: 2,
            ),
          ],
          address: address,
          paymentMethod: PaymentMethod.fpx,
          paymentDetail: 'Maybank2u',
          paymentReference: 'PAY-123456',
          shippingFee: 4.90,
        );

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: OrderHistoryScreen()),
      ),
    );

    expect(find.text(order.id), findsOneWidget);
    expect(find.text('Maybank2u'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);

    await tester.tap(find.text(order.id));
    await tester.pumpAndSettle();

    expect(find.text('Order Details'), findsOneWidget);
    expect(find.text('Lash Princess'), findsOneWidget);
    expect(find.text('PAY-123456'), findsOneWidget);
    expect(find.text('Shah Alam'), findsNothing);
    expect(find.textContaining('Shah Alam'), findsOneWidget);
  });
}
