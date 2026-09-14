import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eco2shop/feature/orders/models/order.dart';

class PaymentException implements Exception {
  final String message;

  const PaymentException(this.message);

  @override
  String toString() => message;
}

class MockPayment {
  final Duration delay;

  MockPayment({this.delay = const Duration(milliseconds: 1200)});

  Future<String> charge({
    required PaymentMethod method,
    required double amount,
    String? cardNumber,
  }) async {
    await Future<void>.delayed(delay);

    final digits = cardNumber?.replaceAll(RegExp(r'\D'), '') ?? '';
    if (method == PaymentMethod.card && digits.endsWith('0002')) {
      throw const PaymentException(
        'Payment declined. Please try another card.',
      );
    }

    final suffix = DateTime.now().millisecondsSinceEpoch % 1000000;
    return 'PAY-${suffix.toString().padLeft(6, '0')}';
  }
}

final mockPaymentProvider = Provider<MockPayment>((ref) => MockPayment());
