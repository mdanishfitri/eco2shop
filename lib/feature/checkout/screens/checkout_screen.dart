import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eco2shop/feature/cart/models/cart_item.dart';
import 'package:eco2shop/feature/cart/providers/cart_provider.dart';
import 'package:eco2shop/feature/checkout/checkout_pricing.dart';
import 'package:eco2shop/feature/checkout/mock_payment.dart';
import 'package:eco2shop/feature/checkout/screens/payment_success_screen.dart';
import 'package:eco2shop/feature/orders/models/order.dart';
import 'package:eco2shop/feature/orders/order_format.dart';
import 'package:eco2shop/feature/orders/providers/order_provider.dart';

const _banks = [
  'Maybank2u',
  'CIMB Clicks',
  'Public Bank',
  'RHB Now',
  'Hong Leong Connect',
  'Bank Islam',
];

const _wallets = [
  "Touch 'n Go eWallet",
  'GrabPay',
  'ShopeePay',
];

const _states = [
  'Johor',
  'Kedah',
  'Kelantan',
  'Melaka',
  'Negeri Sembilan',
  'Pahang',
  'Penang',
  'Perak',
  'Perlis',
  'Sabah',
  'Sarawak',
  'Selangor',
  'Terengganu',
  'Kuala Lumpur',
  'Putrajaya',
  'Labuan',
];

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key});

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'Muhammad Danish Fitri');
  final _phoneController = TextEditingController(text: '0123456789');
  final _addressController =
      TextEditingController(text: '12, Jalan Eco 2, Taman Hijau');
  final _cityController = TextEditingController(text: 'Shah Alam');
  final _postcodeController = TextEditingController(text: '40150');
  final _cardNameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _expiryController = TextEditingController();
  final _cvvController = TextEditingController();

  String _state = 'Selangor';
  PaymentMethod? _method;
  String? _bank;
  String? _wallet;
  String? _error;
  bool _paying = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postcodeController.dispose();
    _cardNameController.dispose();
    _cardNumberController.dispose();
    _expiryController.dispose();
    _cvvController.dispose();
    super.dispose();
  }

  Future<void> _pay() async {
    if (_paying) return;

    final formOk = _formKey.currentState?.validate() ?? false;
    final methodError = _methodError();
    if (!formOk || methodError != null) {
      setState(() {
        _error = methodError ?? 'Check the highlighted fields.';
      });
      return;
    }

    final cart = ref.read(cartProvider);
    if (cart.isEmpty) {
      setState(() => _error = 'Your cart is empty.');
      return;
    }

    setState(() {
      _paying = true;
      _error = null;
    });

    final result = await showDialog<_PayResult>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _PaymentDialog(onPay: _charge),
    );

    if (!mounted) return;
    if (result?.order != null) {
      ref.read(cartProvider.notifier).clearCart();
      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => PaymentSuccessScreen(orderId: result!.order!.id),
        ),
      );
      return;
    }

    setState(() {
      _paying = false;
      _error = result?.error ?? 'Payment was cancelled.';
    });
  }

  String? _methodError() {
    if (_method == null) return 'Select a payment method.';
    if (_method == PaymentMethod.fpx && _bank == null) {
      return 'Select a bank.';
    }
    if (_method == PaymentMethod.ewallet && _wallet == null) {
      return 'Select an e-wallet.';
    }
    return null;
  }

  Future<Order> _charge() async {
    final cart = ref.read(cartProvider);
    final subtotal = cart.totalPrice;
    final method = _method!;
    final detail = _paymentDetail(method);
    final reference = await ref.read(mockPaymentProvider).charge(
          method: method,
          amount: checkoutTotal(subtotal),
          cardNumber:
              method == PaymentMethod.card ? _cardNumberController.text : null,
        );

    final items = cart.items.values.map(_toOrderItem).toList();
    return ref.read(orderProvider.notifier).placeOrder(
          items: items,
          address: ShippingAddress(
            fullName: _nameController.text.trim(),
            phone: _phoneController.text.trim(),
            addressLine: _addressController.text.trim(),
            city: _cityController.text.trim(),
            postcode: _postcodeController.text.trim(),
            state: _state,
          ),
          paymentMethod: method,
          paymentDetail: detail,
          paymentReference: reference,
          shippingFee: shippingFor(subtotal),
        );
  }

  OrderItem _toOrderItem(CartItem item) {
    return OrderItem(
      productId: item.product.id,
      title: item.product.title,
      thumbnail: item.product.thumbnail,
      unitPrice: item.product.price,
      quantity: item.quantity,
    );
  }

  String _paymentDetail(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.card:
        return _maskedCard(_cardNumberController.text);
      case PaymentMethod.fpx:
        return _bank ?? 'FPX';
      case PaymentMethod.ewallet:
        return _wallet ?? 'E-Wallet';
      case PaymentMethod.cod:
        return 'Pay on delivery';
    }
  }

  String _maskedCard(String raw) {
    final digits = raw.replaceAll(RegExp(r'\D'), '');
    final last4 =
        digits.length >= 4 ? digits.substring(digits.length - 4) : digits;
    final brand = digits.startsWith('5')
        ? 'Mastercard'
        : digits.startsWith('4')
            ? 'Visa'
            : 'Card';
    return '$brand •••• $last4';
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartProvider);
    final subtotal = cart.totalPrice;
    final shipping = shippingFor(subtotal);
    final total = subtotal + shipping;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Checkout',
          style: TextStyle(
            color: Color(0xFF1E1E2D),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: cart.isEmpty
          ? const Center(
              child: Text(
                'Your cart is empty.',
                style: TextStyle(color: Colors.grey),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: Form(
                    key: _formKey,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        const _Heading('Shipping address'),
                        const SizedBox(height: 8),
                        _panel(
                          child: Column(
                            children: [
                              TextFormField(
                                controller: _nameController,
                                textCapitalization: TextCapitalization.words,
                                decoration: _field('Full name'),
                                validator: (value) =>
                                    _required(value, 'Enter the recipient name'),
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                decoration: _field('Phone number'),
                                validator: (value) {
                                  final digits =
                                      value?.replaceAll(RegExp(r'\D'), '') ?? '';
                                  if (digits.length < 9) {
                                    return 'Enter a valid phone number';
                                  }
                                  return null;
                                },
                              ),
                              const SizedBox(height: 12),
                              TextFormField(
                                controller: _addressController,
                                decoration: _field('Address'),
                                validator: (value) =>
                                    _required(value, 'Enter a delivery address'),
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: TextFormField(
                                      controller: _cityController,
                                      decoration: _field('City'),
                                      validator: (value) =>
                                          _required(value, 'Enter a city'),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextFormField(
                                      controller: _postcodeController,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                        LengthLimitingTextInputFormatter(5),
                                      ],
                                      decoration: _field('Postcode'),
                                      validator: (value) {
                                        if (value == null || value.length != 5) {
                                          return '5-digit postcode';
                                        }
                                        return null;
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              DropdownButtonFormField<String>(
                                initialValue: _state,
                                isExpanded: true,
                                decoration: _field('State'),
                                items: [
                                  for (final name in _states)
                                    DropdownMenuItem(value: name, child: Text(name)),
                                ],
                                onChanged: (value) {
                                  if (value == null) return;
                                  setState(() => _state = value);
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const _Heading('Order summary'),
                        const SizedBox(height: 8),
                        _panel(
                          child: Column(
                            children: [
                              for (final item in cart.items.values) ...[
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.product.title,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      'x${item.quantity}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Text(
                                      formatRm(item.totalPrice),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ],
                                ),
                                if (item != cart.items.values.last)
                                  const SizedBox(height: 10),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        const _Heading('Payment method'),
                        const SizedBox(height: 8),
                        for (final method in PaymentMethod.values) ...[
                          _MethodTile(
                            method: method,
                            selected: _method == method,
                            onTap: () => setState(() {
                              _method = method;
                              _error = null;
                            }),
                          ),
                          const SizedBox(height: 8),
                        ],
                        if (_method != null) _methodExtra(_method!),
                      ],
                    ),
                  ),
                ),
                _payBar(subtotal, shipping, total),
              ],
            ),
    );
  }

  Widget _methodExtra(PaymentMethod method) {
    if (method == PaymentMethod.card) return _cardForm();
    if (method == PaymentMethod.fpx) {
      return _choiceField(
        label: 'Bank',
        value: _bank,
        options: _banks,
        onChanged: (value) => setState(() {
          _bank = value;
          _error = null;
        }),
      );
    }
    if (method == PaymentMethod.ewallet) {
      return _choiceField(
        label: 'E-wallet',
        value: _wallet,
        options: _wallets,
        onChanged: (value) => setState(() {
          _wallet = value;
          _error = null;
        }),
      );
    }
    return const Padding(
      padding: EdgeInsets.only(top: 4),
      child: Text(
        'Pay the rider when the order arrives.',
        style: TextStyle(fontSize: 12, color: Colors.grey),
      ),
    );
  }

  Widget _choiceField({
    required String label,
    required String? value,
    required List<String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: DropdownButtonFormField<String>(
        initialValue: value,
        isExpanded: true,
        decoration: _field(label),
        items: [
          for (final option in options)
            DropdownMenuItem(value: option, child: Text(option)),
        ],
        onChanged: onChanged,
      ),
    );
  }

  Widget _cardForm() {
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: _panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              key: const Key('card_name'),
              controller: _cardNameController,
              textCapitalization: TextCapitalization.words,
              decoration: _field('Name on card'),
              validator: (value) {
                if (_method != PaymentMethod.card) return null;
                return _required(value, 'Enter the name on the card');
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              key: const Key('card_number'),
              controller: _cardNumberController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9 ]')),
                LengthLimitingTextInputFormatter(19),
              ],
              decoration: _field('Card number', hint: '4242 4242 4242 4242'),
              validator: (value) {
                if (_method != PaymentMethod.card) return null;
                final digits = value?.replaceAll(RegExp(r'\D'), '') ?? '';
                if (digits.length != 16) return 'Enter a 16-digit card number';
                return null;
              },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    key: const Key('card_expiry'),
                    controller: _expiryController,
                    keyboardType: TextInputType.number,
                    decoration: _field('Expiry', hint: 'MM/YY'),
                    validator: (value) {
                      if (_method != PaymentMethod.card) return null;
                      if (!RegExp(r'^(0[1-9]|1[0-2])\/\d{2}$')
                          .hasMatch(value ?? '')) {
                        return 'Use MM/YY';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    key: const Key('card_cvv'),
                    controller: _cvvController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(4),
                    ],
                    decoration: _field('CVV'),
                    validator: (value) {
                      if (_method != PaymentMethod.card) return null;
                      if ((value ?? '').length < 3) return 'Invalid CVV';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'Any 16-digit number works. Ending in 0002 is declined.',
              style: TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _payBar(double subtotal, double shipping, double total) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            _amountRow('Subtotal', formatRm(subtotal)),
            const SizedBox(height: 6),
            _amountRow(
              'Shipping',
              shipping == 0 ? 'FREE' : formatRm(shipping),
            ),
            const SizedBox(height: 8),
            _amountRow('Total', formatRm(total), emphasize: true),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(
                _error!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ],
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                key: const Key('checkout_pay_button'),
                onPressed: _paying ? null : _pay,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5A52EA),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  _paying ? 'Processing...' : 'Pay ${formatRm(total)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentDialog extends StatefulWidget {
  final Future<Order> Function() onPay;

  const _PaymentDialog({required this.onPay});

  @override
  State<_PaymentDialog> createState() => _PaymentDialogState();
}

class _PaymentDialogState extends State<_PaymentDialog> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _run());
  }

  Future<void> _run() async {
    try {
      final order = await widget.onPay();
      if (!mounted) return;
      Navigator.of(context).pop(_PayResult.ok(order));
    } on PaymentException catch (error) {
      if (!mounted) return;
      Navigator.of(context).pop(_PayResult.fail(error.message));
    } catch (_) {
      if (!mounted) return;
      Navigator.of(context).pop(
        _PayResult.fail('Payment failed. Please try again.'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return const PopScope(
      canPop: false,
      child: AlertDialog(
        content: Row(
          children: [
            SizedBox(
              width: 28,
              height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: Color(0xFF5A52EA),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Text(
                'Processing payment...',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PayResult {
  final Order? order;
  final String? error;

  _PayResult.ok(this.order) : error = null;
  _PayResult.fail(this.error) : order = null;
}

class _Heading extends StatelessWidget {
  final String text;

  const _Heading(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: Color(0xFF1E1E2D),
      ),
    );
  }
}

IconData _methodIcon(PaymentMethod method) {
  switch (method) {
    case PaymentMethod.card:
      return Icons.credit_card;
    case PaymentMethod.fpx:
      return Icons.account_balance;
    case PaymentMethod.ewallet:
      return Icons.account_balance_wallet;
    case PaymentMethod.cod:
      return Icons.payments_outlined;
  }
}

class _MethodTile extends StatelessWidget {
  final PaymentMethod method;
  final bool selected;
  final VoidCallback onTap;

  const _MethodTile({
    required this.method,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFF4F3FF) : Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        key: Key('payment_method_${method.name}'),
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: selected ? const Color(0xFF5A52EA) : const Color(0xFFE8EAF2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                _methodIcon(method),
                color: const Color(0xFF5A52EA),
                size: 22,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      method.subtitle,
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_off,
                color: selected ? const Color(0xFF5A52EA) : Colors.grey,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Widget _panel({required Widget child}) {
  return Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: child,
  );
}

InputDecoration _field(String label, {String? hint}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    isDense: true,
    filled: true,
    fillColor: const Color(0xFFF7F8FC),
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFFE8EAF2)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF5A52EA)),
    ),
  );
}

String? _required(String? value, String message) {
  if (value == null || value.trim().isEmpty) return message;
  return null;
}

Widget _amountRow(String label, String value, {bool emphasize = false}) {
  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(
        label,
        style: TextStyle(
          fontSize: emphasize ? 14 : 13,
          color: emphasize ? const Color(0xFF1E1E2D) : Colors.grey,
          fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
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
