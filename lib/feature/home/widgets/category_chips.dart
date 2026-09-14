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
    {
      'id': 'all',
      'label': 'All',
      'icon': Icons.grid_view_rounded,
      'activeColor': Color(0xFF5A52EA),
      'bgColor': Color(0xFFECE9FF),
    },
    {
      'id': 'beauty',
      'label': 'Beauty',
      'icon': Icons.face_retouching_natural_rounded,
      'activeColor': Color(0xFFFFB800),
      'bgColor': Color(0xFFFFF7E6),
    },
    {
      'id': 'fragrances',
      'label': 'Fragrances',
      'icon': Icons.local_florist_rounded,
      'activeColor': Color(0xFF2ECD8A),
      'bgColor': Color(0xFFE8FAF2),
    },
    {
      'id': 'furniture',
      'label': 'Furniture',
      'icon': Icons.chair_rounded,
      'activeColor': Color(0xFFFF5252),
      'bgColor': Color(0xFFFFF0F3),
    },
    {
      'id': 'groceries',
      'label': 'Groceries',
      'icon': Icons.shopping_basket_rounded,
      'activeColor': Color(0xFF2196F3),
      'bgColor': Color(0xFFEDF6FF),
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, index) {
          final category = categories[index];
          final String catId = category['id'] as String;
          final String label = category['label'] as String;
          final IconData icon = category['icon'] as IconData;
          final Color activeColor = category['activeColor'] as Color;
          final Color bgColor = category['bgColor'] as Color;

          final bool isSelected =
              (selectedCategory.isEmpty && catId == 'all') ||
                  selectedCategory.toLowerCase() == catId.toLowerCase();

          return InkWell(
            onTap: () => onCategorySelected(catId == 'all' ? '' : catId),
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? activeColor : bgColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: isSelected
                    ? [
                        BoxShadow(
                          color: activeColor.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        )
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    icon,
                    size: 18,
                    color: isSelected ? Colors.white : activeColor,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: TextStyle(
                      color: isSelected ? Colors.white : Colors.black87,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
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
