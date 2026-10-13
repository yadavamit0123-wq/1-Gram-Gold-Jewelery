import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category_model.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/empty_state_widget.dart';
import '../products/product_listing_screen.dart';

class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key});

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  int _selectedCategoryIndex = 0;

  void _navigateToListing({
    required String title,
    int? categoryId,
    int? subcategoryId,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductListingScreen(
          title: title,
          categoryId: categoryId,
          subcategoryId: subcategoryId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final categories = productProvider.categories;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Categories & Collections'),
        elevation: 1,
      ),
      body: categories.isEmpty
          ? (productProvider.isLoadingHome
              ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
              : EmptyStateWidget(
                  icon: Icons.category_outlined,
                  title: 'No Categories Found',
                  description: 'Unable to load categories. Please check connection.',
                  buttonText: 'Retry',
                  onButtonPressed: () => productProvider.loadHomeData(),
                ))
          : Row(
              children: [
                // Left Column: Main Category List (Amazon style side-rail)
                Container(
                  width: 110,
                  color: Colors.white,
                  child: ListView.builder(
                    itemCount: categories.length,
                    itemBuilder: (context, index) {
                      final cat = categories[index];
                      final isSelected = index == _selectedCategoryIndex;

                      return InkWell(
                        onTap: () {
                          setState(() {
                            _selectedCategoryIndex = index;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 14),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.surfaceVariant : Colors.white,
                            border: Border(
                              left: BorderSide(
                                color: isSelected ? AppColors.gold : Colors.transparent,
                                width: 4,
                              ),
                              bottom: const BorderSide(
                                color: AppColors.borderLight,
                                width: 1,
                              ),
                            ),
                          ),
                          child: Column(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isSelected ? Colors.white : AppColors.surfaceVariant,
                                  border: Border.all(
                                    color: isSelected ? AppColors.gold : Colors.transparent,
                                    width: 1.5,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    _getCategoryIcon(cat.name),
                                    size: 22,
                                    color: isSelected ? AppColors.goldDark : AppColors.textSecondary,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                cat.name,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                  color: isSelected ? AppColors.primary : AppColors.textSecondary,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const VerticalDivider(width: 1, color: AppColors.borderLight),

                // Right Area: Selected Category Subcategories and Tiers
                Expanded(
                  child: _buildSubcategoryContent(categories[_selectedCategoryIndex]),
                ),
              ],
            ),
    );
  }

  Widget _buildSubcategoryContent(CategoryModel category) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Category Header Banner Card
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.primaryLight],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  category.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (category.description != null && category.description!.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    category.description!,
                    style: const TextStyle(
                      color: AppColors.goldLight,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    _navigateToListing(
                      title: 'All ${category.name}',
                      categoryId: category.id,
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    minimumSize: Size.zero,
                  ),
                  child: const Text(
                    'View All in Category',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Subcategories / Tiers Grid
          const Text(
            'Subcategories & Tiers',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),

          if (category.subcategories.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(24),
              alignment: Alignment.center,
              child: Column(
                children: [
                  const Icon(Icons.info_outline, color: AppColors.textMuted, size: 36),
                  const SizedBox(height: 8),
                  Text(
                    'Browse all products in ${category.name}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                ],
              ),
            ),
          ] else ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                childAspectRatio: 1.1,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: category.subcategories.length,
              itemBuilder: (context, index) {
                final sub = category.subcategories[index];
                return InkWell(
                  onTap: () {
                    _navigateToListing(
                      title: '${category.name} - ${sub.name}',
                      categoryId: category.id,
                      subcategoryId: sub.id,
                    );
                  },
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderLight),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceVariant,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            _getSubcategoryIcon(sub.name),
                            color: AppColors.goldDark,
                            size: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          sub.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('gold')) return Icons.workspace_premium;
    if (lower.contains('brass')) return Icons.shield;
    if (lower.contains('copper')) return Icons.circle;
    return Icons.diamond;
  }

  IconData _getSubcategoryIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('luxury')) return Icons.auto_awesome;
    if (lower.contains('premium')) return Icons.star_rounded;
    if (lower.contains('ordinary')) return Icons.check_circle_outline;
    return Icons.style_outlined;
  }
}
