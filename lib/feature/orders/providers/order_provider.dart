import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eco2shop/feature/orders/models/order.dart';

class OrderState {
  final List<Order> orders;

  const OrderState({this.orders = const []});

  bool get isEmpty => orders.isEmpty;

  Order? findById(String id) {
    for (final order in orders) {
      if (order.id == id) return order;
    }
    return null;
  }

  OrderState copyWith({List<Order>? orders}) {
    return OrderState(orders: orders ?? this.orders);
  }
}

class OrderNotifier extends Notifier<OrderState> {
  int _sequence = 0;

  @override
  OrderState build() => const OrderState();

  Order placeOrder({
    required List<OrderItem> items,
    required ShippingAddress address,
    required PaymentMethod paymentMethod,
    required String paymentDetail,
    required String paymentReference,
    required double shippingFee,
  }) {
    final subtotal = items.fold<double>(0, (sum, item) => sum + item.lineTotal);
    final order = Order(
      id: _nextId(),
      createdAt: DateTime.now(),
      items: List<OrderItem>.unmodifiable(items),
      address: address,
      paymentMethod: paymentMethod,
      paymentDetail: paymentDetail,
      paymentReference: paymentReference,
      status: paymentMethod == PaymentMethod.cod
          ? OrderStatus.confirmed
          : OrderStatus.paid,
      subtotal: subtotal,
      shippingFee: shippingFee,
      total: subtotal + shippingFee,
    );
    state = state.copyWith(orders: [order, ...state.orders]);
    return order;
  }

  String _nextId() {
    _sequence += 1;
    final now = DateTime.now();
    final year = (now.year % 100).toString().padLeft(2, '0');
    final month = now.month.toString().padLeft(2, '0');
    final day = now.day.toString().padLeft(2, '0');
    final sequence = _sequence.toString().padLeft(3, '0');
    return 'ECO$year$month$day-$sequence';
  }
}

final orderProvider = NotifierProvider<OrderNotifier, OrderState>(
  OrderNotifier.new,
);
