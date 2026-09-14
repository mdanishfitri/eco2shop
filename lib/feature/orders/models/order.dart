enum PaymentMethod { card, fpx, ewallet, cod }

extension PaymentMethodX on PaymentMethod {
  String get label => switch (this) {
        PaymentMethod.card => 'Credit / Debit Card',
        PaymentMethod.fpx => 'Online Banking (FPX)',
        PaymentMethod.ewallet => 'E-Wallet',
        PaymentMethod.cod => 'Cash on Delivery',
      };

  String get subtitle => switch (this) {
        PaymentMethod.card => 'Visa, Mastercard',
        PaymentMethod.fpx => 'Pay via Malaysian banks',
        PaymentMethod.ewallet => "Touch 'n Go, GrabPay, ShopeePay",
        PaymentMethod.cod => 'Pay when your order arrives',
      };
}

enum OrderStatus { paid, confirmed }

extension OrderStatusX on OrderStatus {
  String get label => switch (this) {
        OrderStatus.paid => 'Paid',
        OrderStatus.confirmed => 'Confirmed',
      };
}

class ShippingAddress {
  final String fullName;
  final String phone;
  final String addressLine;
  final String city;
  final String postcode;
  final String state;

  const ShippingAddress({
    required this.fullName,
    required this.phone,
    required this.addressLine,
    required this.city,
    required this.postcode,
    required this.state,
  });

  String get singleLine => '$addressLine, $postcode $city, $state';
}

class OrderItem {
  final int productId;
  final String title;
  final String thumbnail;
  final double unitPrice;
  final int quantity;

  const OrderItem({
    required this.productId,
    required this.title,
    required this.thumbnail,
    required this.unitPrice,
    required this.quantity,
  });

  double get lineTotal => unitPrice * quantity;
}

class Order {
  final String id;
  final DateTime createdAt;
  final List<OrderItem> items;
  final ShippingAddress address;
  final PaymentMethod paymentMethod;
  final String paymentDetail;
  final String paymentReference;
  final OrderStatus status;
  final double subtotal;
  final double shippingFee;
  final double total;

  const Order({
    required this.id,
    required this.createdAt,
    required this.items,
    required this.address,
    required this.paymentMethod,
    required this.paymentDetail,
    required this.paymentReference,
    required this.status,
    required this.subtotal,
    required this.shippingFee,
    required this.total,
  });

  int get itemCount => items.fold(0, (sum, item) => sum + item.quantity);

  DateTime get estimatedDelivery => createdAt.add(const Duration(days: 3));
}
