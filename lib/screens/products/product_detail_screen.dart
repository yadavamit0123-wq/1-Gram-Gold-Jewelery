import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/product_model.dart';
import '../../providers/cart_provider.dart';
import '../../providers/product_provider.dart';
import '../../providers/wishlist_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../../widgets/price_breakdown_card.dart';
import '../../widgets/product_card.dart';
import '../checkout/checkout_screen.dart';

class ProductDetailScreen extends StatefulWidget {
  final int productId;

  const ProductDetailScreen({super.key, required this.productId});

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  ProductModel? _product;
  List<ProductModel> _relatedProducts = [];
  bool _isLoading = true;
  int _selectedImageIndex = 0;
  int _quantity = 1;
  final TextEditingController _pincodeController = TextEditingController();
  String? _pincodeResult;

  @override
  void initState() {
    super.initState();
    _loadDetails();
  }

  @override
  void dispose() {
    _pincodeController.dispose();
    super.dispose();
  }

  Future<void> _loadDetails() async {
    setState(() => _isLoading = true);
    final productProvider = Provider.of<ProductProvider>(context, listen: false);
    final prod = await productProvider.getProductDetails(widget.productId);

    if (prod != null) {
      final related = await productProvider.getRelatedProducts(prod);
      if (mounted) {
        setState(() {
          _product = prod;
          _relatedProducts = related;
          _isLoading = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _checkPincode() {
    final pin = _pincodeController.text.trim();
    if (pin.length != 6 || int.tryParse(pin) == null) {
      setState(() {
        _pincodeResult = 'Please enter a valid 6-digit Indian PIN code';
      });
      return;
    }

    setState(() {
      _pincodeResult = '✓ Express delivery available to $pin in 3-5 business days. Free shipping above ₹999!';
    });
  }

  void _showZoomDialog(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.black,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            InteractiveViewer(
              minScale: 0.5,
              maxScale: 4.0,
              child: Center(
                child: CachedNetworkImage(
                  imageUrl: imageUrl,
                  fit: BoxFit.contain,
                  placeholder: (c, u) => const CircularProgressIndicator(color: AppColors.gold),
                  errorWidget: (c, u, e) => const Icon(Icons.error, color: Colors.white),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Details')),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.gold),
        ),
      );
    }

    if (_product == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Product Details')),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: AppColors.error),
              const SizedBox(height: 12),
              const Text('Product not found or unavailable'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final prod = _product!;
    final wishlistProvider = Provider.of<WishlistProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final isWishlisted = wishlistProvider.isInWishlist(prod.id);
    final images = prod.allImageUrls;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(prod.sku.isNotEmpty ? prod.sku : 'Jewellery Details'),
        actions: [
          IconButton(
            icon: Icon(
              isWishlisted ? Icons.favorite : Icons.favorite_border,
              color: isWishlisted ? AppColors.badgeDiscount : Colors.white,
            ),
            onPressed: () => wishlistProvider.toggleWishlist(prod),
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: Colors.white),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Sharing ${prod.name}')),
              );
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Gallery with Main View & Thumbnail Row
            _buildImageGallery(images),

            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Brand & Category Bar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        prod.categoryName?.toUpperCase() ?? 'JEWELLERY',
                        style: const TextStyle(
                          color: AppColors.goldDark,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(
                        'SKU: ${prod.sku}',
                        style: const TextStyle(
                          color: AppColors.textMuted,
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Title
                  Text(
                    prod.name,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Price Box with MRP & Savings
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceVariant,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.baseline,
                          textBaseline: TextBaseline.alphabetic,
                          children: [
                            if (prod.hasDiscount) ...[
                              Text(
                                '-${prod.discountPercent}%',
                                style: const TextStyle(
                                  color: AppColors.badgeDiscount,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              Formatters.formatPrice(prod.price),
                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                        if (prod.hasDiscount) ...[
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              const Text(
                                'M.R.P.: ',
                                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
                              ),
                              Text(
                                Formatters.formatPrice(prod.regularPrice),
                                style: const TextStyle(
                                  color: AppColors.textMuted,
                                  fontSize: 13,
                                  decoration: TextDecoration.lineThrough,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Save ${Formatters.formatPrice(prod.savings)}',
                                style: const TextStyle(
                                  color: AppColors.success,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
                        const Text(
                          'Inclusive of all taxes & crafting duties',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 11),
                        ),
                      ],
                    ),
                  ),

                  // Transparent Jewellery Breakdown (Required for Gold Jewellery)
                  PriceBreakdownCard(product: prod),

                  // Stock & Availability
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Icon(
                        prod.isInStock ? Icons.check_circle : Icons.cancel,
                        color: prod.isInStock ? AppColors.success : AppColors.error,
                        size: 18,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        prod.isInStock ? 'In Stock (Ready to Dispatch)' : 'Currently Out of Stock',
                        style: TextStyle(
                          color: prod.isInStock ? AppColors.success : AppColors.error,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),

                  // Quantity Selector
                  if (prod.isInStock) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text(
                          'Quantity:',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(width: 16),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: AppColors.border),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove, size: 16),
                                onPressed: _quantity > 1 ? () => setState(() => _quantity--) : null,
                              ),
                              Text(
                                '$_quantity',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add, size: 16),
                                onPressed: _quantity < prod.stockQuantity
                                    ? () => setState(() => _quantity++)
                                    : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Pincode Delivery Estimator
                  const SizedBox(height: 20),
                  const Text(
                    'Delivery Options',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _pincodeController,
                          keyboardType: TextInputType.number,
                          maxLength: 6,
                          decoration: const InputDecoration(
                            hintText: 'Enter 6-digit delivery pincode',
                            counterText: '',
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        onPressed: _checkPincode,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: const Text('Check'),
                      ),
                    ],
                  ),
                  if (_pincodeResult != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _pincodeResult!,
                      style: TextStyle(
                        fontSize: 12,
                        color: _pincodeResult!.startsWith('✓') ? AppColors.success : AppColors.error,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  // Product Description
                  if (prod.shortDescription != null || prod.longDescription != null) ...[
                    const SizedBox(height: 24),
                    const Text(
                      'About This Item',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      prod.longDescription ?? prod.shortDescription ?? '',
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        height: 1.5,
                      ),
                    ),
                  ],

                  // Specifications Table
                  const SizedBox(height: 24),
                  const Text(
                    'Specifications',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 10),
                  _buildSpecTable(prod),

                  // Related Products
                  if (_relatedProducts.isNotEmpty) ...[
                    const SizedBox(height: 32),
                    const Text(
                      'Similar Designs You May Like',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 220,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: _relatedProducts.length,
                        itemBuilder: (context, index) {
                          final p = _relatedProducts[index];
                          return ProductCard(
                            product: p,
                            isHorizontal: true,
                            onTap: () {
                              Navigator.of(context).pushReplacement(
                                MaterialPageRoute(
                                  builder: (_) => ProductDetailScreen(productId: p.id),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],

                  const SizedBox(height: 80),
                ],
              ),
            ),
          ],
        ),
      ),
      // Sticky Bottom Buy Box (Amazon style: Add to Cart & Buy Now)
      bottomSheet: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: prod.isInStock
                      ? () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final ok = await cartProvider.addToCart(prod, quantity: _quantity);
                          if (ok) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Added $_quantity × ${prod.name} to cart'),
                                backgroundColor: AppColors.primary,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        }
                      : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Add to Cart'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: prod.isInStock
                      ? () async {
                          final nav = Navigator.of(context);
                          await cartProvider.addToCart(prod, quantity: _quantity);
                          nav.push(
                            MaterialPageRoute(builder: (_) => const CheckoutScreen()),
                          );
                        }
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.gold,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text('Buy Now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageGallery(List<String> images) {
    return Column(
      children: [
        GestureDetector(
          onTap: () {
            if (images.isNotEmpty && images[_selectedImageIndex].isNotEmpty) {
              _showZoomDialog(images[_selectedImageIndex]);
            }
          },
          child: AspectRatio(
            aspectRatio: 1.1,
            child: Container(
              color: const Color(0xFFFBF9F5),
              child: Stack(
                children: [
                  Center(
                    child: images.isNotEmpty && images[_selectedImageIndex].isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: images[_selectedImageIndex],
                            fit: BoxFit.contain,
                            placeholder: (c, u) => const CircularProgressIndicator(color: AppColors.gold),
                            errorWidget: (c, u, e) => const Icon(Icons.diamond_outlined, size: 72, color: AppColors.gold),
                          )
                        : const Icon(Icons.diamond_outlined, size: 72, color: AppColors.gold),
                  ),
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.5),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.zoom_in, color: Colors.white, size: 18),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        if (images.length > 1) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: images.length,
              itemBuilder: (context, index) {
                final isSelected = index == _selectedImageIndex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedImageIndex = index),
                  child: Container(
                    width: 60,
                    margin: const EdgeInsets.only(right: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: isSelected ? AppColors.gold : AppColors.border,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(5),
                      child: CachedNetworkImage(
                        imageUrl: images[index],
                        fit: BoxFit.cover,
                        errorWidget: (c, u, e) => const Icon(Icons.broken_image, size: 20),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSpecTable(ProductModel prod) {
    final specs = <MapEntry<String, String>>[];
    if (prod.material != null && prod.material!.isNotEmpty) specs.add(MapEntry('Material', prod.material!));
    if (prod.goldType != null && prod.goldType!.isNotEmpty) specs.add(MapEntry('Gold Type', prod.goldType!));
    if (prod.goldWeight != null && prod.goldWeight! > 0) specs.add(MapEntry('Gold Weight', '${prod.goldWeight} g'));
    if (prod.weight != null && prod.weight! > 0) specs.add(MapEntry('Gross Weight', '${prod.weight} g'));
    if (prod.dimensions != null && prod.dimensions!.isNotEmpty) specs.add(MapEntry('Dimensions', prod.dimensions!));
    if (prod.size != null && prod.size!.isNotEmpty) specs.add(MapEntry('Size / Length', prod.size!));
    if (prod.color != null && prod.color!.isNotEmpty) specs.add(MapEntry('Finish / Color', prod.color!));
    specs.add(const MapEntry('Trademark Standard', 'Class 14 — Quality Jewellery'));

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.borderLight),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: specs.asMap().entries.map((entry) {
          final idx = entry.key;
          final item = entry.value;
          final isEven = idx % 2 == 0;
          return Container(
            color: isEven ? AppColors.surfaceVariant : Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text(
                    item.key,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, fontWeight: FontWeight.w500),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Text(
                    item.value,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}
