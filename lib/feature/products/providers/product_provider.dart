import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eco2shop/api/api_service.dart';
import 'package:eco2shop/api/api_exception.dart';
import 'package:eco2shop/feature/products/models/product_model.dart';

final apiServiceProvider = Provider<ApiService>((ref) => ApiService());

class ProductState {
  final List<Product> products;
  final int total;
  final int skip;
  final int limit;
  final bool isLoading;
  final bool isMoreLoading;
  final String? errorMessage;
  final String searchQuery;

  const ProductState({
    this.products = const [],
    this.total = 0,
    this.skip = 0,
    this.limit = 20,
    this.isLoading = false,
    this.isMoreLoading = false,
    this.errorMessage,
    this.searchQuery = '',
  });

  bool get hasMore => products.length < total;
  bool get hasError => errorMessage != null;

  ProductState copyWith({
    List<Product>? products,
    int? total,
    int? skip,
    int? limit,
    bool? isLoading,
    bool? isMoreLoading,
    String? errorMessage,
    bool clearError = false,
    String? searchQuery,
  }) {
    return ProductState(
      products: products ?? this.products,
      total: total ?? this.total,
      skip: skip ?? this.skip,
      limit: limit ?? this.limit,
      isLoading: isLoading ?? this.isLoading,
      isMoreLoading: isMoreLoading ?? this.isMoreLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class ProductNotifier extends Notifier<ProductState> {
  @override
  ProductState build() {
    return const ProductState();
  }

  ApiService get _apiService => ref.read(apiServiceProvider);

  Future<void> fetchProducts({bool isRefresh = false}) async {
    if (state.isLoading || state.isMoreLoading) return;

    if (isRefresh) {
      state = state.copyWith(
        skip: 0,
        products: [],
        total: 0,
        clearError: true,
        isLoading: true,
      );
    } else if (state.products.isEmpty) {
      state = state.copyWith(isLoading: true, clearError: true);
    } else {
      if (!state.hasMore) return;
      state = state.copyWith(isMoreLoading: true, clearError: true);
    }

    try {
      final ProductResponse response;
      if (state.searchQuery.trim().isEmpty) {
        response = await _apiService.getProducts(
          limit: state.limit,
          skip: state.skip,
        );
      } else {
        response = await _apiService.searchProducts(
          state.searchQuery,
          limit: state.limit,
          skip: state.skip,
        );
      }

      final updatedProducts = isRefresh
          ? response.products
          : [...state.products, ...response.products];

      state = state.copyWith(
        products: updatedProducts,
        total: response.total,
        skip: state.skip + response.products.length,
        isLoading: false,
        isMoreLoading: false,
        clearError: true,
      );
    } on ApiException catch (e) {
      state = state.copyWith(
        errorMessage: e.message,
        isLoading: false,
        isMoreLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        errorMessage: 'An unexpected error occurred: $e',
        isLoading: false,
        isMoreLoading: false,
      );
    }
  }

  Future<void> loadMoreProducts() async {
    if (state.hasMore && !state.isLoading && !state.isMoreLoading) {
      await fetchProducts(isRefresh: false);
    }
  }

  Future<void> searchProducts(String query) async {
    state = state.copyWith(searchQuery: query);
    await fetchProducts(isRefresh: true);
  }

  Future<void> clearSearch() async {
    state = state.copyWith(searchQuery: '');
    await fetchProducts(isRefresh: true);
  }
}

final productNotifierProvider = NotifierProvider<ProductNotifier, ProductState>(
  ProductNotifier.new,
);

final productDetailProvider = FutureProvider.family<Product, int>((
  ref,
  id,
) async {
  final apiService = ref.watch(apiServiceProvider);
  return await apiService.getProductById(id);
});
