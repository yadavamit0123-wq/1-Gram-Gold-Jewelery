import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/category_model.dart';
import '../../providers/product_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/product_card.dart';
import '../../widgets/search_bar_widget.dart';
import '../../widgets/shimmer_loader.dart';
import 'product_detail_screen.dart';

class ProductListingScreen extends StatefulWidget {
  final String title;
  final String? initialSearch;
  final int? categoryId;
  final int? subcategoryId;
  final String? material;
  final bool? isFeatured;
  final bool? isBestseller;
  final bool? isNewArrival;

  const ProductListingScreen({
    super.key,
    required this.title,
    this.initialSearch,
    this.categoryId,
    this.subcategoryId,
    this.material,
    this.isFeatured,
    this.isBestseller,
    this.isNewArrival,
  });

  @override
  State<ProductListingScreen> createState() => _ProductListingScreenState();
}

class _ProductListingScreenState extends State<ProductListingScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  // Active filters
  late int? _categoryId;
  late int? _subcategoryId;
  late String? _material;
  double? _minPrice;
  double? _maxPrice;
  bool? _inStockOnly;
  String _sortBy = 'relevance';

  @override
  void initState() {
    super.initState();
    _categoryId = widget.categoryId;
    _subcategoryId = widget.subcategoryId;
    _material = widget.material;
    if (widget.initialSearch != null) {
      _searchController.text = widget.initialSearch!;
    }

    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchData(refresh: true);
    });
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 300) {
      final provider = Provider.of<ProductProvider>(context, listen: false);
      if (!provider.isLoadingMore && provider.hasMore) {
        provider.fetchProducts(refresh: false);
      }
    }
  }

  void _fetchData({bool refresh = false}) {
    final provider = Provider.of<ProductProvider>(context, listen: false);
    provider.fetchProducts(
      refresh: refresh,
      search: _searchController.text.trim().isNotEmpty ? _searchController.text.trim() : null,
      categoryId: _categoryId,
      subcategoryId: _subcategoryId,
      material: _material,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      inStock: _inStockOnly,
      sortBy: _sortBy,
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _showSortSheet() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Text(
                    'Sort By',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ),
                const Divider(),
                _buildSortTile('Relevance', 'relevance'),
                _buildSortTile('Newest Arrivals', 'newest'),
                _buildSortTile('Price: Low to High', 'price_low_high'),
                _buildSortTile('Price: High to Low', 'price_high_low'),
                _buildSortTile('Popularity / Bestsellers', 'popularity'),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSortTile(String title, String value) {
    final isSelected = _sortBy == value;
    return ListTile(
      title: Text(
        title,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w400,
          color: isSelected ? AppColors.goldDark : AppColors.textPrimary,
        ),
      ),
      trailing: isSelected ? const Icon(Icons.check, color: AppColors.goldDark) : null,
      onTap: () {
        setState(() {
          _sortBy = value;
        });
        Navigator.pop(context);
        _fetchData(refresh: true);
      },
    );
  }

  void _showFilterSheet(List<CategoryModel> categories) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Container(
              height: MediaQuery.of(context).size.height * 0.75,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filter Jewellery',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                      ),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            _categoryId = null;
                            _subcategoryId = null;
                            _material = null;
                            _minPrice = null;
                            _maxPrice = null;
                            _inStockOnly = null;
                          });
                        },
                        child: const Text('Reset All', style: TextStyle(color: AppColors.error)),
                      ),
                    ],
                  ),
                  const Divider(),
                  Expanded(
                    child: ListView(
                      children: [
                        // Material Filter
                        const Text('Material & Alloy', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: ['All', 'Gold', 'Brass', 'Copper'].map((mat) {
                            final isSel = (mat == 'All' && _material == null) || _material == mat;
                            return ChoiceChip(
                              label: Text(mat),
                              selected: isSel,
                              selectedColor: AppColors.gold.withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: isSel ? AppColors.goldDark : AppColors.textPrimary,
                                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                              ),
                              onSelected: (val) {
                                setSheetState(() {
                                  _material = mat == 'All' ? null : mat;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // Categories
                        const Text('Category', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: categories.map((cat) {
                            final isSel = _categoryId == cat.id;
                            return FilterChip(
                              label: Text(cat.name),
                              selected: isSel,
                              selectedColor: AppColors.gold.withOpacity(0.2),
                              labelStyle: TextStyle(
                                color: isSel ? AppColors.goldDark : AppColors.textPrimary,
                                fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                              ),
                              onSelected: (val) {
                                setSheetState(() {
                                  _categoryId = val ? cat.id : null;
                                  _subcategoryId = null;
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 20),

                        // In Stock Only
                        CheckboxListTile(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('In Stock Only', style: TextStyle(fontSize: 14)),
                          value: _inStockOnly == true,
                          activeColor: AppColors.gold,
                          onChanged: (val) {
                            setSheetState(() {
                              _inStockOnly = val;
                            });
                          },
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        setState(() {});
                        _fetchData(refresh: true);
                      },
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final products = productProvider.listingProducts;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(widget.title),
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search & Filter Header Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            color: AppColors.primary,
            child: SearchBarWidget(
              controller: _searchController,
              onSubmitted: (query) {
                _fetchData(refresh: true);
              },
              onClear: () {
                _searchController.clear();
                _fetchData(refresh: true);
              },
            ),
          ),

          // Filter & Sort Control Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white,
              border: const Border(bottom: BorderSide(color: AppColors.borderLight)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _showSortSheet,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.sort, size: 18, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Sort (${_getSortLabel(_sortBy)})',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20, child: VerticalDivider(color: AppColors.borderLight)),
                Expanded(
                  child: InkWell(
                    onTap: () => _showFilterSheet(productProvider.categories),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.tune, size: 18, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Text(
                          'Filter ${_hasActiveFilters() ? '(Active)' : ''}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: _hasActiveFilters() ? AppColors.goldDark : AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Product Grid
          Expanded(
            child: productProvider.isLoadingListing
                ? const ProductGridSkeleton(itemCount: 6)
                : products.isEmpty
                    ? EmptyStateWidget(
                        icon: Icons.search_off_rounded,
                        title: 'No Jewellery Found',
                        description: 'Try adjusting your search keywords or clearing filters.',
                        buttonText: 'Reset Filters',
                        onButtonPressed: () {
                          _searchController.clear();
                          setState(() {
                            _categoryId = null;
                            _subcategoryId = null;
                            _material = null;
                            _minPrice = null;
                            _maxPrice = null;
                            _inStockOnly = null;
                            _sortBy = 'relevance';
                          });
                          _fetchData(refresh: true);
                        },
                      )
                    : RefreshIndicator(
                        color: AppColors.gold,
                        onRefresh: () async => _fetchData(refresh: true),
                        child: GridView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            childAspectRatio: 0.60,
                            crossAxisSpacing: 10,
                            mainAxisSpacing: 10,
                          ),
                          itemCount: products.length + (productProvider.isLoadingMore ? 2 : 0),
                          itemBuilder: (context, index) {
                            if (index >= products.length) {
                              return const Center(
                                child: SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                                ),
                              );
                            }
                            final prod = products[index];
                            return ProductCard(
                              product: prod,
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ProductDetailScreen(productId: prod.id),
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  bool _hasActiveFilters() {
    return _categoryId != null || _subcategoryId != null || _material != null || _inStockOnly != null;
  }

  String _getSortLabel(String val) {
    switch (val) {
      case 'newest':
        return 'Newest';
      case 'price_low_high':
        return 'Price: Low-High';
      case 'price_high_low':
        return 'Price: High-Low';
      case 'popularity':
        return 'Popularity';
      default:
        return 'Relevance';
    }
  }
}
