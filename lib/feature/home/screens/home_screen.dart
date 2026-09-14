import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eco2shop/feature/home/widgets/category_chips.dart';
import 'package:eco2shop/feature/home/widgets/bottom_nav_bar.dart';
import 'package:eco2shop/feature/products/widgets/product_card.dart';
import 'package:eco2shop/feature/products/providers/product_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  int _currentNavIndex = 0;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productNotifierProvider.notifier).fetchProducts(isRefresh: true);
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(productNotifierProvider.notifier).loadMoreProducts();
    }
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
      bottomNavigationBar: BottomNavBar(
        currentIndex: _currentNavIndex,
        onTap: (index) {
          setState(() {
            _currentNavIndex = index;
          });
        },
      ),
      body: RefreshIndicator(
        color: const Color(0xFF5A52EA),
        onRefresh: () async {
          await notifier.fetchProducts(isRefresh: true);
        },
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),

              CategoryChips(
                selectedCategory: productState.selectedCategory,
                onCategorySelected: (category) {
                  notifier.selectCategory(category);
                },
              ),

              const SizedBox(height: 20),

              if (productState.isLoading)
                const SizedBox(
                  height: 300,
                  child: Center(
                    child: CircularProgressIndicator(color: Color(0xFF5A52EA)),
                  ),
                )
              else if (productState.hasError)
                Container(
                  height: 250,
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        color: Colors.red,
                        size: 48,
                      ),
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
                )
              else if (productState.products.isEmpty)
                Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: const Text(
                    'No products found.',
                    style: TextStyle(color: Colors.grey, fontSize: 16),
                  ),
                )
              else ...[
                _buildProductCatalog(productState),

                if (productState.isMoreLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF5A52EA),
                      ),
                    ),
                  ),

                const SizedBox(height: 24),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductCatalog(ProductState productState) {
    if (productState.selectedCategory.isNotEmpty) {
      final categoryTitle =
          productState.selectedCategory.substring(0, 1).toUpperCase() +
          productState.selectedCategory.substring(1);

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
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
            const SizedBox(height: 14),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: productState.products.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 0.72,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemBuilder: (context, index) {
                return ProductCard(product: productState.products[index]);
              },
            ),
          ],
        ),
      );
    }

    final Map<String, List<dynamic>> grouped = {};
    for (var p in productState.products) {
      grouped.putIfAbsent(p.category, () => []).add(p);
    }

    return Column(
      children: grouped.entries.map((entry) {
        final categoryName =
            entry.key.substring(0, 1).toUpperCase() + entry.key.substring(1);
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
                  separatorBuilder: (_, __) => const SizedBox(width: 12),
                  itemBuilder: (context, index) {
                    return SizedBox(
                      width: 160,
                      child: ProductCard(product: categoryProducts[index]),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
