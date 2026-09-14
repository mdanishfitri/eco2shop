import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eco2shop/feature/orders/models/order.dart';
import 'package:eco2shop/feature/orders/order_format.dart';
import 'package:eco2shop/feature/orders/providers/order_provider.dart';
import 'package:eco2shop/feature/orders/widgets/order_status_chip.dart';

class OrderDetailScreen extends ConsumerWidget {
  final String orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final order = ref.watch(orderProvider).findById(orderId);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1E1E2D), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Order Details',
          style: TextStyle(
            color: Color(0xFF1E1E2D),
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        centerTitle: true,
      ),
      body: order == null
          ? const Center(child: Text('Order not found.'))
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _section(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              order.id,
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                                color: Color(0xFF1E1E2D),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              formatDateTime(order.createdAt),
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      OrderStatusChip(status: order.status),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _section(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionLabel('Items'),
                      const SizedBox(height: 12),
                      for (final item in order.items) ...[
                        _OrderItemRow(item: item),
                        if (item != order.items.last) const Divider(height: 20),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _section(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionLabel('Delivery'),
                      const SizedBox(height: 10),
                      Text(
                        order.address.fullName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF1E1E2D),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        order.address.phone,
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        order.address.singleLine,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Color(0xFF1E1E2D),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Estimated by ${formatDate(order.estimatedDelivery)}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _section(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _SectionLabel('Payment'),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(
                            paymentMethodIcon(order.paymentMethod),
                            color: const Color(0xFF5A52EA),
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              order.paymentMethod.label,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: Color(0xFF1E1E2D),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      _detailLine('Details', order.paymentDetail),
                      _detailLine('Reference', order.paymentReference),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _section(
                  child: Column(
                    children: [
                      _amountLine('Subtotal', formatRm(order.subtotal)),
                      const SizedBox(height: 8),
                      _amountLine(
                        'Shipping',
                        order.shippingFee == 0
                            ? 'FREE'
                            : formatRm(order.shippingFee),
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 10),
                        child: Divider(height: 1),
                      ),
                      _amountLine('Total', formatRm(order.total), emphasize: true),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
    );
  }
}

class _OrderItemRow extends StatelessWidget {
  final OrderItem item;

  const _OrderItemRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: const Color(0xFFF7F8FC),
            borderRadius: BorderRadius.circular(10),
          ),
          child: item.thumbnail.isEmpty
              ? const Icon(Icons.inventory_2_outlined, color: Colors.grey, size: 20)
              : ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image.network(
                    item.thumbnail,
                    fit: BoxFit.contain,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.image_not_supported_outlined,
                      size: 18,
                    ),
                  ),
                ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                  color: Color(0xFF1E1E2D),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${formatRm(item.unitPrice)} × ${item.quantity}',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        Text(
          formatRm(item.lineTotal),
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: Color(0xFF1E1E2D),
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w800,
        color: Color(0xFF1E1E2D),
      ),
    );
  }
}

Widget _section({required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    ),
    child: child,
  );
}

Widget _detailLine(String label, String value) {
  return Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.grey),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E1E2D),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _amountLine(String label, String value, {bool emphasize = false}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: emphasize ? 14 : 13,
          fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
          color: emphasize ? const Color(0xFF1E1E2D) : Colors.grey,
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: emphasize ? 18 : 13,
          fontWeight: FontWeight.w800,
          color: emphasize ? const Color(0xFF5A52EA) : const Color(0xFF1E1E2D),
        ),
      ),
    ],
  );
}
