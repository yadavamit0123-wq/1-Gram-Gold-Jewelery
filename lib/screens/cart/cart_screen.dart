import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/cart_item_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/constants.dart';
import '../../utils/formatters.dart';
import '../../widgets/empty_state_widget.dart';
import '../checkout/checkout_screen.dart';
import '../products/product_listing_screen.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cartProvider = Provider.of<CartProvider>(context);
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final items = cartProvider.items;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Shopping Cart (${cartProvider.itemCount})'),
        actions: [
          if (items.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: () => cartProvider.loadCart(),
            ),
        ],
      ),
      body: cartProvider.isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : items.isEmpty
              ? EmptyStateWidget(
                  icon: Icons.shopping_cart_outlined,
                  title: 'Your Shopping Cart is Empty',
                  description: 'Discover hallmark 1 Gram Gold, Brass and Copper jewellery.',
                  buttonText: 'Start Shopping',
                  onButtonPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const ProductListingScreen(title: 'All Jewellery'),
                      ),
                    );
                  },
                )
              : Column(
                  children: [
                    // Free Delivery Progress Banner (Amazon style)
                    _buildFreeDeliveryProgress(cartProvider),

                    // Items List
                    Expanded(
                      child: RefreshIndicator(
                        color: AppColors.gold,
                        onRefresh: () => cartProvider.loadCart(),
                        child: ListView.separated(
                          padding: const EdgeInsets.all(12),
                          itemCount: items.length,
                          separatorBuilder: (context, index) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = items[index];
                            return _buildCartItemCard(context, item, cartProvider, wishlistProvider);
                          },
                        ),
                      ),
                    ),

                    // Cart Summary Order Box
                    _buildCartSummary(context, cartProvider),
                  ],
                ),
    );
  }

  Widget _buildFreeDeliveryProgress(CartProvider cart) {
    final qualifies = cart.qualifiesForFreeShipping;
    final remaining = cart.freeShippingRemaining;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      color: qualifies ? const Color(0xFFECFDF5) : const Color(0xFFFEF3C7),
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                qualifies ? Icons.check_circle : Icons.local_shipping_outlined,
                size: 18,
                color: qualifies ? AppColors.success : AppColors.goldDark,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  qualifies
                      ? 'Congratulations! You unlocked FREE Express Delivery'
                      : 'Add ${Formatters.formatPrice(remaining)} more to get FREE Delivery!',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: qualifies ? AppColors.success : AppColors.goldDark,
                  ),
                ),
              ),
            ],
          ),
          if (!qualifies) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (cart.subtotal / AppConstants.freeShippingThreshold).clamp(0.0, 1.0),
                backgroundColor: AppColors.borderLight,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.gold),
                minHeight: 5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCartItemCard(
    BuildContext context,
    CartItemModel item,
    CartProvider cartProvider,
    WishlistProvider wishlistProvider,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Image
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 80,
                  height: 80,
                  color: const Color(0xFFFBF9F5),
                  child: item.fullImageUrl.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: item.fullImageUrl,
                          fit: BoxFit.contain,
                          errorWidget: (c, u, e) => const Icon(Icons.diamond_outlined, color: AppColors.gold),
                        )
                      : const Icon(Icons.diamond_outlined, color: AppColors.gold),
                ),
              ),
              const SizedBox(width: 12),

              // Info & Price
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    if (item.material != null && item.material!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.material!,
                        style: const TextStyle(fontSize: 11, color: AppColors.goldDark, fontWeight: FontWeight.w600),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          Formatters.formatPrice(item.price),
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        if (item.regularPrice != null && item.regularPrice! > item.price) ...[
                          const SizedBox(width: 6),
                          Text(
                            Formatters.formatPrice(item.regularPrice),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textMuted,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (item.isOutOfStock) ...[
                      const SizedBox(height: 4),
                      const Text(
                        'Out of Stock',
                        style: TextStyle(color: AppColors.error, fontSize: 11, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderLight),
          const SizedBox(height: 8),

          // Stepper + Move to Wishlist + Remove
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Stepper
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: () {
                        cartProvider.updateQuantity(item.id, item.quantity - 1);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Icon(Icons.remove, size: 16, color: AppColors.textPrimary),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      color: AppColors.surfaceVariant,
                      child: Text(
                        '${item.quantity}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        cartProvider.updateQuantity(item.id, item.quantity + 1);
                      },
                      child: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Icon(Icons.add, size: 16, color: AppColors.textPrimary),
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              Row(
                children: [
                  TextButton.icon(
                    onPressed: () async {
                      final productProvider = Provider.of<ProductProvider>(context, listen: false);
                      final product = await productProvider.getProductDetails(item.productId);
                      if (product != null) {
                        await wishlistProvider.toggleWishlist(product);
                      }
                      await cartProvider.removeItem(item.id);
                    },
                    icon: const Icon(Icons.favorite_border, size: 14, color: AppColors.textSecondary),
                    label: const Text(
                      'Save for Later',
                      style: TextStyle(fontSize: 11, color: AppColors.textSecondary),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.textMuted),
                    onPressed: () => cartProvider.removeItem(item.id),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCartSummary(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Subtotal:',
                  style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                Text(
                  Formatters.formatPrice(cart.subtotal),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
              ],
            ),
            if (cart.discountAmount > 0) ...[
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Instant Savings:',
                    style: TextStyle(fontSize: 13, color: AppColors.success),
                  ),
                  Text(
                    '- ${Formatters.formatPrice(cart.discountAmount)}',
                    style: const TextStyle(fontSize: 13, color: AppColors.success, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Shipping Fee:',
                  style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
                Text(
                  cart.shippingFee == 0 ? 'FREE' : Formatters.formatPrice(cart.shippingFee),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: cart.shippingFee == 0 ? AppColors.success : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Divider(color: AppColors.borderLight),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Payable:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
                Text(
                  Formatters.formatPrice(cart.totalAmount),
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.goldDark),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: Text('Proceed to Checkout (${cart.itemCount} items)'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
