import 'package:flutter/material.dart';
import 'package:eco2shop/feature/orders/models/order.dart';

IconData paymentMethodIcon(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.card:
      return Icons.credit_card_rounded;
    case PaymentMethod.fpx:
      return Icons.account_balance_rounded;
    case PaymentMethod.ewallet:
      return Icons.account_balance_wallet_rounded;
    case PaymentMethod.cod:
      return Icons.payments_outlined;
  }
}

class OrderStatusChip extends StatelessWidget {
  final OrderStatus status;

  const OrderStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final isPaid = status == OrderStatus.paid;
    final color = isPaid ? const Color(0xFF1B8A5A) : const Color(0xFFC47D12);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
