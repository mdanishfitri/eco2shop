import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eco2shop/feature/home/widgets/category_chips.dart';
import 'package:eco2shop/feature/home/widgets/bottom_nav_bar.dart';
import 'package:eco2shop/feature/products/widgets/product_card.dart';
import 'package:eco2shop/feature/products/providers/product_provider.dart';
import 'package:eco2shop/feature/products/screens/product_detail_screen.dart';
import 'package:eco2shop/feature/products/screens/product_catalog_screen.dart';
import 'package:eco2shop/feature/cart/screens/cart_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with SingleTickerProviderStateMixin {
  int _currentNavIndex = 0;
  final ScrollController _scrollController = ScrollController();
  bool _isLoadingMore = false;
  bool _showBackToTop = false;
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productNotifierProvider.notifier).fetchProducts(isRefresh: true);
    });
  }

  @override
  void dispose() {
    _fabAnimController.dispose();
    _scrollController.dispose();
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

  void _onNavTap(int index) {
    if (index == 0 && _currentNavIndex != 0) {
      ref.read(productNotifierProvider.notifier).resetToHome();
    }
    setState(() {
      _currentNavIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: _onNavTap,
      ),
      body: IndexedStack(
        index: _currentNavIndex,
        children: [
          _buildHomeView(),
          const ProductCatalogScreen(),
          const CartScreen(),
          _buildAccountPlaceholderView(),
        ],
      ),
    );
  }

  Widget _buildHomeView() {
    final productState = ref.watch(productNotifierProvider);
    final notifier = ref.read(productNotifierProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
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
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            const CircleAvatar(
              radius: 18,
              backgroundColor: Color(0xFF5A52EA),
              child: Icon(Icons.person, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Hello, User',
                  style: TextStyle(
                    color: Color(0xFF1E1E2D),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  'Welcome to Eco2Shop',
                  style: TextStyle(
                    color: Colors.grey,
                    fontSize: 11,
                    fontWeight: FontWeight.normal,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.notifications_none_rounded,
              color: Color(0xFF1E1E2D),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        color: const Color(0xFF5A52EA),
        onRefresh: () async {
          await notifier.fetchProducts(isRefresh: true);
        },
        child: _buildScrollBody(productState, notifier),
      ),
    );
  }

  Widget _buildScrollBody(ProductState productState, ProductNotifier notifier) {
    if (productState.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF5A52EA)),
      );
    }

    if (productState.hasError) {
      return Center(
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
                onPressed: () => notifier.fetchProducts(isRefresh: true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5A52EA),
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    final grouped = <String, List<dynamic>>{};
    for (final p in productState.products) {
      grouped.putIfAbsent(p.category, () => []).add(p);
    }

    if (productState.selectedCategory.isNotEmpty) {
      return _buildCategoryGrid(productState, notifier);
    }

    if (productState.products.isEmpty) {
      return const Center(
        child: Text(
          'No products found.',
          style: TextStyle(color: Colors.grey, fontSize: 16),
        ),
      );
    }

    return _buildGroupedSliver(productState, notifier, grouped);
  }

  Widget _buildCategoryGrid(
      ProductState productState, ProductNotifier notifier) {
    final categoryTitle =
        productState.selectedCategory.substring(0, 1).toUpperCase() +
            productState.selectedCategory.substring(1);

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 16),
            child: CategoryChips(
              selectedCategory: productState.selectedCategory,
              onCategorySelected: (cat) =>
                  ref.read(productNotifierProvider.notifier).selectCategory(cat),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  categoryTitle,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E1E2D),
                  ),
                ),
                Text(
                  '${productState.products.length} Items',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.w500,
                  ),
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
                        builder: (_) =>
                            ProductDetailScreen(productId: product.id),
                      ),
                    );
                  },
                );
              },
              childCount: productState.products.length,
            ),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.72,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
          ),
        ),
        if (productState.isMoreLoading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF5A52EA)),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildGroupedSliver(
    ProductState productState,
    ProductNotifier notifier,
    Map<String, List<dynamic>> grouped,
  ) {
    final entries = grouped.entries.toList();

    return CustomScrollView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 16).copyWith(top: 16),
            child: CategoryChips(
              selectedCategory: productState.selectedCategory,
              onCategorySelected: (cat) =>
                  ref.read(productNotifierProvider.notifier).selectCategory(cat),
            ),
          ),
        ),
        SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, sectionIndex) {
              final entry = entries[sectionIndex];
              final categoryName = entry.key.substring(0, 1).toUpperCase() +
                  entry.key.substring(1);
              final categoryProducts = entry.value;

              return Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            categoryName,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E1E2D),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              ref
                                  .read(productNotifierProvider.notifier)
                                  .selectCategory(entry.key);
                            },
                            child: const Text(
                              'See All',
                              style: TextStyle(
                                color: Color(0xFF5A52EA),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 230,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        scrollDirection: Axis.horizontal,
                        itemCount: categoryProducts.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(width: 12),
                        itemBuilder: (context, index) {
                          final product = categoryProducts[index];
                          return SizedBox(
                            width: 160,
                            child: ProductCard(
                              product: product,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailScreen(
                                        productId: product.id),
                                  ),
                                );
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
            childCount: entries.length,
          ),
        ),
        if (productState.isMoreLoading)
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFF5A52EA)),
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    );
  }

  Widget _buildAccountPlaceholderView() {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FD),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'My Account',
          style: TextStyle(
            color: Color(0xFF1E1E2D),
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircleAvatar(
              radius: 40,
              backgroundColor: Color(0xFFECE9FF),
              child: Icon(Icons.person, size: 48, color: Color(0xFF5A52EA)),
            ),
            SizedBox(height: 16),
            Text(
              'Muhammad Danish Fitri',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Color(0xFF1E1E2D),
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Junior Mobile Developer Candidate',
              style: TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}
