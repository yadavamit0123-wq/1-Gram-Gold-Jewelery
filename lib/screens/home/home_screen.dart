import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/banner_model.dart';
import '../../models/category_model.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/product_card.dart';
import '../../widgets/search_bar_widget.dart';
import '../products/product_detail_screen.dart';
import '../products/product_listing_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final PageController _bannerController = PageController();
  int _currentBannerIndex = 0;

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  void _navigateToProduct(ProductModel product) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductDetailScreen(productId: product.id),
      ),
    );
  }

  void _navigateToListing({
    String? title,
    int? categoryId,
    int? subcategoryId,
    String? material,
    bool? isFeatured,
    bool? isBestseller,
    bool? isNewArrival,
  }) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ProductListingScreen(
          title: title ?? 'Jewellery Collection',
          categoryId: categoryId,
          subcategoryId: subcategoryId,
          material: material,
          isFeatured: isFeatured,
          isBestseller: isBestseller,
          isNewArrival: isNewArrival,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final productProvider = Provider.of<ProductProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final wishlistProvider = Provider.of<WishlistProvider>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        color: AppColors.gold,
        onRefresh: () async {
          await productProvider.loadHomeData();
          await cartProvider.loadCart();
        },
        child: CustomScrollView(
          slivers: [
            // Amazon-Style Sticky App Bar with Search Header
            SliverAppBar(
              pinned: true,
              floating: false,
              backgroundColor: AppColors.primary,
              expandedHeight: 120,
              elevation: 2,
              title: Row(
                children: [
                  Container(
                    width: 52,
                    height: 28,
                    padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: AppColors.goldLight, width: 1),
                    ),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          AppConstants.appName,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.2,
                          ),
                        ),
                        Text(
                          AppConstants.brandTagline,
                          style: TextStyle(
                            color: AppColors.goldLight,
                            fontSize: 10,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              actions: [
                // Wishlist Icon with count
                IconButton(
                  icon: Badge(
                    isLabelVisible: wishlistProvider.itemCount > 0,
                    label: Text('${wishlistProvider.itemCount}'),
                    backgroundColor: AppColors.badgeDiscount,
                    child: const Icon(Icons.favorite_border, color: Colors.white),
                  ),
                  onPressed: () {
                    _navigateToListing(title: 'All Products');
                  },
                ),
                // Cart Icon with count
                IconButton(
                  icon: Badge(
                    isLabelVisible: cartProvider.itemCount > 0,
                    label: Text('${cartProvider.itemCount}'),
                    backgroundColor: AppColors.gold,
                    child: const Icon(Icons.shopping_cart_outlined, color: Colors.white),
                  ),
                  onPressed: () {
                    // Navigate to listing or let bottom nav handle
                  },
                ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(56),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                  child: SearchBarWidget(
                    readOnly: true,
                    onTap: () {
                      _navigateToListing(title: 'Search Results');
                    },
                  ),
                ),
              ),
            ),

            // Content Body
            if (productProvider.isLoadingHome)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
              )
            else if (productProvider.homeError != null)
              SliverFillRemaining(
                child: EmptyStateWidget(
                  icon: Icons.wifi_off_rounded,
                  title: 'Connection Issue',
                  description: productProvider.homeError!,
                  buttonText: 'Retry',
                  onButtonPressed: () {
                    productProvider.loadHomeData();
                  },
                ),
              )
            else
              SliverList(
                delegate: SliverChildListDelegate([
                  // Free Delivery Top Alert
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                    color: const Color(0xFFFEF3C7),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.local_shipping_outlined, size: 16, color: AppColors.goldDark),
                        const SizedBox(width: 8),
                        Text(
                          'FREE Express Delivery on orders above ₹${AppConstants.freeShippingThreshold.toInt()}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.goldDark,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Hero Banners Carousel
                  if (productProvider.banners.isNotEmpty) ...[
                    _buildBannersCarousel(productProvider.banners),
                  ],

                  // Shop By Category Pills / Circles
                  if (productProvider.categories.isNotEmpty) ...[
                    _buildCategoryRow(productProvider.categories),
                  ],

                  // 1 Gram Gold Jewellery Spotlight Section
                  _buildCuratedSection(
                    title: '1 Gram Gold Jewellery',
                    subtitle: 'Exclusive Hallmarked Designs in 1 Gram Pure Gold Imitate',
                    products: productProvider.goldProducts,
                    badgeText: 'TRADEMARK',
                    onViewAll: () => _navigateToListing(
                      title: '1 Gram Gold Jewellery',
                      material: 'Gold',
                    ),
                  ),

                  // Promotional Banner Card
                  _buildPromoMidBanner(),

                  // Best Sellers Section
                  if (productProvider.bestsellerProducts.isNotEmpty) ...[
                    _buildCuratedSection(
                      title: 'Best Sellers',
                      subtitle: 'Most loved customer favorites this season',
                      products: productProvider.bestsellerProducts,
                      badgeText: 'POPULAR',
                      onViewAll: () => _navigateToListing(
                        title: 'Best Sellers',
                        isBestseller: true,
                      ),
                    ),
                  ],

                  // Brass Items Section
                  if (productProvider.brassProducts.isNotEmpty) ...[
                    _buildCuratedSection(
                      title: 'Brass Items Collection',
                      subtitle: 'Ordinary, Premium & Luxury handcrafted Brass temple jewellery',
                      products: productProvider.brassProducts,
                      badgeText: 'BRASS',
                      onViewAll: () => _navigateToListing(
                        title: 'Brass Items',
                        material: 'Brass',
                      ),
                    ),
                  ],

                  // Copper Items Section
                  if (productProvider.copperProducts.isNotEmpty) ...[
                    _buildCuratedSection(
                      title: 'Copper Items Collection',
                      subtitle: 'Ordinary & Premium Copper finish ornaments',
                      products: productProvider.copperProducts,
                      badgeText: 'COPPER',
                      onViewAll: () => _navigateToListing(
                        title: 'Copper Items',
                        material: 'Copper',
                      ),
                    ),
                  ],

                  // New Arrivals Section
                  if (productProvider.newArrivalProducts.isNotEmpty) ...[
                    _buildCuratedSection(
                      title: 'New Arrivals',
                      subtitle: 'Fresh bridal and everyday designs just crafted',
                      products: productProvider.newArrivalProducts,
                      badgeText: 'NEW',
                      onViewAll: () => _navigateToListing(
                        title: 'New Arrivals',
                        isNewArrival: true,
                      ),
                    ),
                  ],

                  // Trust Badges (Amazon style trust cards)
                  _buildTrustBadges(),

                  const SizedBox(height: 32),
                ]),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannersCarousel(List<BannerModel> banners) {
    return Column(
      children: [
        SizedBox(
          height: 180,
          child: PageView.builder(
            controller: _bannerController,
            itemCount: banners.length,
            onPageChanged: (idx) {
              setState(() {
                _currentBannerIndex = idx;
              });
            },
            itemBuilder: (context, index) {
              final banner = banners[index];
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      banner.fullImageUrl.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: banner.fullImageUrl,
                              fit: BoxFit.cover,
                              placeholder: (c, u) => Container(color: AppColors.primaryLight),
                              errorWidget: (c, u, e) => _buildBannerFallback(banner),
                            )
                          : _buildBannerFallback(banner),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              AppColors.primaryDark.withOpacity(0.75),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                      Positioned(
                        left: 20,
                        top: 24,
                        bottom: 24,
                        child: SizedBox(
                          width: 220,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                banner.title,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.3,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (banner.subtitle != null && banner.subtitle!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Text(
                                  banner.subtitle!,
                                  style: const TextStyle(
                                    color: AppColors.goldLight,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () {
                                  _navigateToListing(title: banner.title);
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.gold,
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  minimumSize: Size.zero,
                                ),
                                child: const Text(
                                  'Explore Now',
                                  style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            banners.length,
            (idx) => Container(
              width: _currentBannerIndex == idx ? 18 : 6,
              height: 6,
              margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 6),
              decoration: BoxDecoration(
                color: _currentBannerIndex == idx ? AppColors.gold : AppColors.border,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBannerFallback(BannerModel banner) {
    return Container(
      decoration: const BoxDecoration(
        gradient: AppColors.headerGradient,
      ),
      child: Center(
        child: Icon(Icons.diamond_outlined, size: 60, color: AppColors.gold.withOpacity(0.3)),
      ),
    );
  }

  Widget _buildCategoryRow(List<CategoryModel> categories) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Shop by Category',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              InkWell(
                onTap: () {
                  _navigateToListing(title: 'All Categories');
                },
                child: const Text(
                  'View All',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.goldDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 105,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: categories.length,
            itemBuilder: (context, index) {
              final cat = categories[index];
              return InkWell(
                onTap: () {
                  _navigateToListing(
                    title: cat.name,
                    categoryId: cat.id,
                  );
                },
                child: Container(
                  width: 82,
                  margin: const EdgeInsets.symmetric(horizontal: 5),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          border: Border.all(color: AppColors.borderLight, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            cat.name.toLowerCase().contains('gold')
                                ? Icons.stars_rounded
                                : (cat.name.toLowerCase().contains('brass')
                                    ? Icons.shield_outlined
                                    : Icons.circle_outlined),
                            color: AppColors.gold,
                            size: 30,
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        cat.name,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                          height: 1.15,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildCuratedSection({
    required String title,
    required String subtitle,
    required List<ProductModel> products,
    required String badgeText,
    required VoidCallback onViewAll,
  }) {
    if (products.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.symmetric(vertical: 16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.gold.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              badgeText,
                              style: const TextStyle(
                                color: AppColors.goldDark,
                                fontSize: 9,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: onViewAll,
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                  ),
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      color: AppColors.goldDark,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 220,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final prod = products[index];
                return ProductCard(
                  product: prod,
                  isHorizontal: true,
                  onTap: () => _navigateToProduct(prod),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPromoMidBanner() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryLight],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.gold.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.gold,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'AUTHENTICITY GUARANTEE',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  '1 Gram Gold Imitate Jewellery',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Real 24 Karat gold micro-plating on premium metal base. 100% skin-safe & durable shine.',
                  style: TextStyle(
                    color: AppColors.borderLight,
                    fontSize: 11,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          const Icon(
            Icons.verified,
            color: AppColors.goldLight,
            size: 48,
          ),
        ],
      ),
    );
  }

  Widget _buildTrustBadges() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: const Column(
        children: [
          Row(
            children: [
              Icon(Icons.security, color: AppColors.goldDark, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Registered Trademark — Class 14',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    Text(
                      'Legally registered mark guaranteeing high quality imitation standards.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Divider(color: AppColors.borderLight),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.currency_rupee, color: AppColors.success, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transparent Gold Price Breakdown',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    Text(
                      'Complete visibility of gold weight, crafting charges and applicable taxes.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Divider(color: AppColors.borderLight),
          SizedBox(height: 12),
          Row(
            children: [
              Icon(Icons.replay_circle_filled, color: AppColors.info, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '7-Day Return Policy & Safe Delivery',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    ),
                    Text(
                      'Hassle-free replacement if damaged in transit. Tamper-evident packaging.',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
