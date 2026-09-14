import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eco2shop/feature/cart/providers/cart_provider.dart';
import 'package:eco2shop/feature/checkout/checkout_pricing.dart';
import 'package:eco2shop/feature/checkout/mock_payment.dart';
import 'package:eco2shop/feature/checkout/screens/checkout_screen.dart';
import 'package:eco2shop/feature/orders/models/order.dart';
import 'package:eco2shop/feature/orders/providers/order_provider.dart';
import 'package:eco2shop/feature/products/models/product_model.dart';

void main() {
  group('checkout pricing', () {
    test('charges shipping below RM100', () {
      expect(shippingFor(40), standardShippingFee);
      expect(checkoutTotal(40), closeTo(44.90, 0.001));
    });

    test('shipping is free from RM100', () {
      expect(shippingFor(100), 0);
      expect(checkoutTotal(120), 120);
    });
  });

  group('mock payment', () {
    final payment = MockPayment(delay: Duration.zero);

    test('returns a reference for a successful charge', () async {
      final reference = await payment.charge(
        method: PaymentMethod.cod,
        amount: 24.9,
      );
      expect(reference, startsWith('PAY-'));
    });

    test('declines a card ending in 0002', () {
      expect(
        () => payment.charge(
          method: PaymentMethod.card,
          amount: 10,
          cardNumber: '4000 0000 0000 0002',
        ),
        throwsA(isA<PaymentException>()),
      );
    });
  });

  group('CheckoutScreen', () {
    late Product product;

    setUp(() {
      product = Product(
        id: 1,
        title: 'Lash Princess',
        description: 'Mascara',
        category: 'beauty',
        price: 10,
        discountPercentage: 0,
        rating: 4.5,
        stock: 20,
        tags: const ['beauty'],
        sku: 'BEA-001',
        weight: 1,
        dimensions: const Dimensions(width: 1, height: 1, depth: 1),
        warrantyInformation: 'None',
        shippingInformation: 'Fast',
        availabilityStatus: 'In Stock',
        reviews: const [],
        returnPolicy: 'None',
        minimumOrderQuantity: 1,
        meta: ProductMeta(
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
          barcode: '',
          qrCode: '',
        ),
        images: const [],
        thumbnail: '',
      );
    });

    Future<ProviderContainer> pumpCheckout(WidgetTester tester) async {
      tester.view.physicalSize = const Size(900, 1800);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final container = ProviderContainer(
        overrides: [
          mockPaymentProvider.overrideWithValue(
            MockPayment(delay: Duration.zero),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(cartProvider.notifier).addToCart(product, quantity: 2);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(home: CheckoutScreen()),
        ),
      );
      return container;
    }

    testWidgets('asks for a payment method before charging', (tester) async {
      final container = await pumpCheckout(tester);

      await tester.tap(find.byKey(const Key('checkout_pay_button')));
      await tester.pump();

      expect(find.text('Select a payment method.'), findsOneWidget);
      expect(container.read(orderProvider).orders, isEmpty);
    });

    testWidgets('COD payment creates an order and clears the cart', (
      tester,
    ) async {
      final container = await pumpCheckout(tester);

      await tester.ensureVisible(find.byKey(const Key('payment_method_cod')));
      await tester.tap(find.byKey(const Key('payment_method_cod')));
      await tester.pump();

      await tester.tap(find.byKey(const Key('checkout_pay_button')));
      await _finishPayment(tester);

      expect(find.text('Payment successful'), findsOneWidget);
      expect(container.read(cartProvider).isEmpty, isTrue);

      final order = container.read(orderProvider).orders.single;
      expect(order.paymentMethod, PaymentMethod.cod);
      expect(order.status, OrderStatus.confirmed);
      expect(order.itemCount, 2);
      expect(order.total, closeTo(24.90, 0.001));
    });

    testWidgets('declined card does not create an order', (tester) async {
      final container = await pumpCheckout(tester);

      await tester.tap(find.byKey(const Key('payment_method_card')));
      await tester.pump();
      await tester.enterText(find.byKey(const Key('card_name')), 'Danish Fitri');
      await tester.enterText(
        find.byKey(const Key('card_number')),
        '4000000000000002',
      );
      await tester.enterText(find.byKey(const Key('card_expiry')), '12/28');
      await tester.enterText(find.byKey(const Key('card_cvv')), '123');

      await tester.tap(find.byKey(const Key('checkout_pay_button')));
      await _finishPayment(tester);

      expect(
        find.text('Payment declined. Please try another card.'),
        findsOneWidget,
      );
      expect(container.read(orderProvider).orders, isEmpty);
      expect(container.read(cartProvider).totalItemCount, 2);
    });
  });
}

Future<void> _finishPayment(WidgetTester tester) async {
  await tester.pump();
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 500));
  await tester.pump();
}
