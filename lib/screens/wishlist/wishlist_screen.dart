import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../theme/app_colors.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/product_card.dart';
import '../products/product_detail_screen.dart';
import '../products/product_listing_screen.dart';

class WishlistScreen extends StatelessWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final items = wishlistProvider.items;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('My Wishlist (${wishlistProvider.itemCount})'),
        elevation: 1,
        actions: [
          if (items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => wishlistProvider.loadWishlist(),
            ),
        ],
      ),
      body: wishlistProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : items.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.favorite_border,
                  title: 'Your Wishlist is Empty',
                  description: 'Save your favorite bridal necklaces, bangles and earrings to review later.',
                  buttonText: 'Explore Collections',
                  onButtonPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProductListingScreen(title: 'All Jewellery'),
                      ),
                    );
                  },
                )
              : RefreshIndicator(
                  color: AppColors.gold,
                  onRefresh: () => wishlistProvider.loadWishlist(),
                  child: GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.60,
                      crossAxisSpacing: 10,
                      mainAxisSpacing: 10,
                    ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final prod = items[index];
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
    );
  }
}
