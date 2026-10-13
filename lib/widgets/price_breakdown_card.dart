import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../theme/app_colors.dart';
import '../utils/formatters.dart';

class PriceBreakdownCard extends StatelessWidget {
  final ProductModel product;

  const PriceBreakdownCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    if (!product.hasBreakdown && !product.isGoldJewellery) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // Soft Warm Gold Tint
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.verified_outlined, color: AppColors.goldDark, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Transparent Jewellery Price Breakdown',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.gold,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '100% Verified',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(color: Color(0xFFFDE68A), height: 1),
          const SizedBox(height: 12),

          // Purity / Gold Type
          if (product.goldType != null && product.goldType!.isNotEmpty)
            _buildRow('Formulation / Gold Type', product.goldType!),

          // Gold / Net Weight
          if (product.goldWeight != null && product.goldWeight! > 0)
            _buildRow('Gold Weight', '${product.goldWeight} grams')
          else if (product.weight != null && product.weight! > 0)
            _buildRow('Net Weight', '${product.weight} grams'),

          // Making Charges
          if (product.makingCharges != null && product.makingCharges! > 0)
            _buildRow('Crafting & Making Charges', Formatters.formatPrice(product.makingCharges)),

          // GST / Taxes
          if (product.gstPercentage != null && product.gstPercentage! > 0)
            _buildRow('Applicable GST', '${product.gstPercentage}% Included')
          else
            _buildRow('Taxes & Duties', 'All GST Included'),

          // MRP Strikethrough
          if (product.hasDiscount)
            _buildRow(
              'Maximum Retail Price (MRP)',
              Formatters.formatPrice(product.regularPrice),
              isStrikethrough: true,
            ),

          const SizedBox(height: 8),
          const Divider(color: Color(0xFFFDE68A), height: 1),
          const SizedBox(height: 8),

          // Final Selling Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Final Selling Price',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                  color: AppColors.primary,
                ),
              ),
              Text(
                Formatters.formatPrice(product.price),
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 17,
                  color: AppColors.goldDark,
                ),
              ),
            ],
          ),

          if (product.hasDiscount) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Text(
                  'You Save ${Formatters.formatPrice(product.savings)} (${product.discountPercent}% Off)',
                  style: const TextStyle(
                    color: AppColors.success,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {bool isStrikethrough = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textSecondary,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isStrikethrough ? AppColors.textMuted : AppColors.textPrimary,
              decoration: isStrikethrough ? TextDecoration.lineThrough : null,
            ),
          ),
        ],
      ),
    );
  }
}
