import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eco2shop/feature/products/models/product_model.dart';
import 'package:eco2shop/feature/cart/models/cart_item.dart';

class CartState {
  final Map<int, CartItem> items;

  const CartState({this.items = const {}});

  int get totalItemCount =>
      items.values.fold(0, (sum, item) => sum + item.quantity);

  double get totalPrice =>
      items.values.fold(0.0, (sum, item) => sum + item.totalPrice);

  bool get isEmpty => items.isEmpty;

  CartState copyWith({Map<int, CartItem>? items}) {
    return CartState(items: items ?? this.items);
  }
}

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() {
    return const CartState();
  }

  void addToCart(Product product, {int quantity = 1}) {
    final updatedItems = Map<int, CartItem>.from(state.items);
    if (updatedItems.containsKey(product.id)) {
      final existing = updatedItems[product.id]!;
      updatedItems[product.id] = existing.copyWith(
        quantity: existing.quantity + quantity,
      );
    } else {
      updatedItems[product.id] = CartItem(
        product: product,
        quantity: quantity,
      );
    }
    state = state.copyWith(items: updatedItems);
  }

  void removeFromCart(int productId) {
    final updatedItems = Map<int, CartItem>.from(state.items);
    updatedItems.remove(productId);
    state = state.copyWith(items: updatedItems);
  }

  void updateQuantity(int productId, int delta) {
    if (!state.items.containsKey(productId)) return;
    final existing = state.items[productId]!;
    final newQuantity = existing.quantity + delta;

    if (newQuantity <= 0) {
      removeFromCart(productId);
    } else {
      final updatedItems = Map<int, CartItem>.from(state.items);
      updatedItems[productId] = existing.copyWith(quantity: newQuantity);
      state = state.copyWith(items: updatedItems);
    }
  }

  void clearCart() {
    state = const CartState();
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(
  CartNotifier.new,
);
