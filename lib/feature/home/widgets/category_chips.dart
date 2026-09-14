import 'package:flutter/material.dart';

class CategoryChips extends StatelessWidget {
  final String selectedCategory;
  final ValueChanged<String> onCategorySelected;

  const CategoryChips({
    super.key,
    required this.selectedCategory,
    required this.onCategorySelected,
  });

  static const List<Map<String, dynamic>> categories = [
    {'id': 'all', 'label': 'All', 'showIcon': true, 'icon': Icons.grid_view_rounded},
    {'id': 'beauty', 'label': 'Beauty', 'showIcon': false},
    {'id': 'fragrances', 'label': 'Fragrances', 'showIcon': false},
    {'id': 'furniture', 'label': 'Furniture', 'showIcon': false},
    {'id': 'groceries', 'label': 'Groceries', 'showIcon': false},
    {'id': 'home-decoration', 'label': 'Home Decor', 'showIcon': false},
    {'id': 'kitchen-accessories', 'label': 'Kitchen', 'showIcon': false},
    {'id': 'laptops', 'label': 'Laptops', 'showIcon': false},
    {'id': 'mens-shirts', 'label': "Men's Shirts", 'showIcon': false},
    {'id': 'mens-shoes', 'label': "Men's Shoes", 'showIcon': false},
    {'id': 'mens-watches', 'label': "Men's Watches", 'showIcon': false},
    {'id': 'mobile-accessories', 'label': 'Mobile', 'showIcon': false},
    {'id': 'motorcycle', 'label': 'Motorcycle', 'showIcon': false},
    {'id': 'skin-care', 'label': 'Skin Care', 'showIcon': false},
    {'id': 'smartphones', 'label': 'Smartphones', 'showIcon': false},
    {'id': 'sports-accessories', 'label': 'Sports', 'showIcon': false},
    {'id': 'sunglasses', 'label': 'Sunglasses', 'showIcon': false},
    {'id': 'tablets', 'label': 'Tablets', 'showIcon': false},
    {'id': 'tops', 'label': 'Tops', 'showIcon': false},
    {'id': 'vehicle', 'label': 'Vehicle', 'showIcon': false},
    {'id': 'womens-bags', 'label': "Women's Bags", 'showIcon': false},
    {'id': 'womens-dresses', 'label': "Women's Dresses", 'showIcon': false},
    {'id': 'womens-jewellery', 'label': "Women's Jewellery", 'showIcon': false},
    {'id': 'womens-shoes', 'label': "Women's Shoes", 'showIcon': false},
    {'id': 'womens-watches', 'label': "Women's Watches", 'showIcon': false},
  ];

  static const Color _activeBgColor = Color(0xFF1E1E2D);
  static const Color _inactiveBgColor = Color(0xFFF0F0F3);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final category = categories[index];
          final String catId = category['id'] as String;
          final String label = category['label'] as String;
          final bool showIcon = category['showIcon'] as bool;
          final IconData? icon =
              showIcon ? category['icon'] as IconData? : null;

          final bool isSelected =
              (selectedCategory.isEmpty && catId == 'all') ||
                  selectedCategory.toLowerCase() == catId.toLowerCase();

          return InkWell(
            onTap: () => onCategorySelected(catId == 'all' ? '' : catId),
            borderRadius: BorderRadius.circular(20),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected ? _activeBgColor : _inactiveBgColor,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(
                      icon,
                      size: 16,
                      color: isSelected ? Colors.white : Colors.black54,
                    ),
                    const SizedBox(width: 6),
                  ],
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight:
                          isSelected ? FontWeight.bold : FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
