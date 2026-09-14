import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eco2shop/feature/home/widgets/category_chips.dart';
import 'package:eco2shop/feature/products/widgets/product_card.dart';
import 'package:eco2shop/feature/products/providers/product_provider.dart';
import 'package:eco2shop/feature/products/screens/product_detail_screen.dart';

class ProductCatalogScreen extends ConsumerStatefulWidget {
  const ProductCatalogScreen({super.key});

  @override
  ConsumerState<ProductCatalogScreen> createState() =>
      _ProductCatalogScreenState();
}

class _ProductCatalogScreenState extends ConsumerState<ProductCatalogScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  bool _isLoadingMore = false;
  bool _showBackToTop = false;
  Timer? _debounce;
  late final AnimationController _fabAnimController;
  late final Animation<double> _fabScaleAnimation;

  static const double _backToTopThreshold = 300;

  @override
  void initState() {
    super.initState();
    _fabAnimController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );
    _fabScaleAnimation = CurvedAnimation(
      parent: _fabAnimController,
      curve: Curves.easeOut,
      reverseCurve: Curves.easeIn,
    );
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _fabAnimController.dispose();
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final position = _scrollController.position;

    final shouldShow = position.pixels >= _backToTopThreshold;
    if (shouldShow != _showBackToTop) {
      setState(() => _showBackToTop = shouldShow);
      if (shouldShow) {
        _fabAnimController.forward();
      } else {
        _fabAnimController.reverse();
      }
    }

    if (_isLoadingMore) return;
    if (position.pixels >= position.maxScrollExtent - 400) {
      final st = ref.read(productNotifierProvider);
      if (st.hasMore && !st.isLoading && !st.isMoreLoading) {
        _isLoadingMore = true;
        ref
            .read(productNotifierProvider.notifier)
            .loadMoreProducts()
            .whenComplete(() => _isLoadingMore = false);
      }
    }
  }

  void _scrollToTop() {
    _scrollController.animateTo(
      0,
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeOutCubic,
    );
  }

  void _onSearchChanged(String query) {
    setState(() {});
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      ref.read(productNotifierProvider.notifier).searchProducts(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productNotifierProvider);
    final notifier = ref.read(productNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: const Text(
          'Product Catalog',
          style: TextStyle(
            color: Color(0xFF1E1E2D),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      floatingActionButton: ScaleTransition(
        scale: _fabScaleAnimation,
        child: FloatingActionButton.small(
          onPressed: _scrollToTop,
          backgroundColor: const Color(0xFF1E1E2D),
          foregroundColor: Colors.white,
          elevation: 4,
          tooltip: 'Back to top',
          child: const Icon(Icons.keyboard_arrow_up_rounded, size: 22),
        ),
      ),
      body: RefreshIndicator(
        color: const Color(0xFF5A52EA),
        onRefresh: () async {
          await notifier.fetchProducts(isRefresh: true);
        },
        child: Scrollbar(
          controller: _scrollController,
          thickness: 3,
          radius: const Radius.circular(8),
          thumbVisibility: true,
          child: CustomScrollView(
            controller: _scrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                      decoration: InputDecoration(
                        hintText: 'Search products...',
                        hintStyle:
                            const TextStyle(color: Colors.grey, fontSize: 13),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: Color(0xFF5A52EA)),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear,
                                    color: Colors.grey, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  _debounce?.cancel();
                                  notifier.clearSearch();
                                  setState(() {});
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: CategoryChips(
                    selectedCategory: productState.selectedCategory,
                    onCategorySelected: (category) {
                      notifier.selectCategory(category);
                    },
                  ),
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              if (productState.isLoading)
                const SliverFillRemaining(
                  child: Center(
                    child:
                        CircularProgressIndicator(color: Color(0xFF5A52EA)),
                  ),
                )
              else if (productState.hasError)
                SliverFillRemaining(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              color: Colors.red, size: 48),
                          const SizedBox(height: 12),
                          Text(
                            productState.errorMessage ?? 'An error occurred',
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 14),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () =>
                                notifier.fetchProducts(isRefresh: true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5A52EA),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else if (productState.products.isEmpty)
                const SliverFillRemaining(
                  child: Center(
                    child: Text(
                      'No products found matching your search.',
                      style: TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                  ),
                )
              else ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          productState.searchQuery.isNotEmpty
                              ? 'Results for "${productState.searchQuery}"'
                              : (productState.selectedCategory.isNotEmpty
                                  ? productState.selectedCategory
                                          .substring(0, 1)
                                          .toUpperCase() +
                                      productState.selectedCategory.substring(1)
                                  : 'All Products'),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1E1E2D),
                          ),
                        ),
                        Text(
                          '${productState.products.length} Items',
                          style: const TextStyle(
                              fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = productState.products[index];
                        return ProductCard(
                          product: product,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ProductDetailScreen(
                                    productId: product.id),
                              ),
                            );
                          },
                        );
                      },
                      childCount: productState.products.length,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.72,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                    ),
                  ),
                ),
              ],
              if (productState.isMoreLoading)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: CircularProgressIndicator(
                          color: Color(0xFF5A52EA)),
                    ),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 80)),
            ],
          ),
        ),
      ),
    );
  }
}
