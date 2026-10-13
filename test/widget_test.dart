import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:jewellery_app/models/product_model.dart';
import 'package:jewellery_app/utils/formatters.dart';
import 'package:jewellery_app/widgets/empty_state_widget.dart';
import 'package:jewellery_app/widgets/price_breakdown_card.dart';

void main() {
  group('1 Gram Gold Jewellery Unit & Widget Tests', () {
    test('ProductModel parses JSON and calculates discounts correctly', () {
      final json = {
        'id': 101,
        'category_id': 1,
        'subcategory_id': 2,
        'name': '1 Gram Gold Royal Bridal Necklace Set',
        'slug': '1-gram-gold-bridal-necklace',
        'sku': 'JWL-GLD-001',
        'regular_price': 5999.00,
        'sale_price': 4499.00,
        'stock_quantity': 15,
        'material': '1 Gram Gold',
        'gold_type': '24K Micron Gold Plated',
        'gold_weight': 1.0,
        'weight': 42.5,
        'making_charges': 450.0,
        'gst_percentage': 3.0,
      };

      final product = ProductModel.fromJson(json);

      expect(product.id, 101);
      expect(product.name, '1 Gram Gold Royal Bridal Necklace Set');
      expect(product.price, 4499.00);
      expect(product.regularPrice, 5999.00);
      expect(product.hasDiscount, true);
      expect(product.discountPercent, 25);
      expect(product.savings, 1500.00);
      expect(product.isGoldJewellery, true);
      expect(product.hasBreakdown, true);
      expect(product.isInStock, true);
    });

    test('Formatters formats Indian currency and dates correctly', () {
      expect(Formatters.formatPrice(4499), '₹4,499');
      expect(Formatters.formatPrice(0), '₹0');
      expect(Formatters.calculateDiscountPercent(5999, 4499), 25);
      expect(Formatters.calculateSavings(5999, 4499), 1500.0);
    });

    testWidgets('EmptyStateWidget renders title, icon, and button properly', (WidgetTester tester) async {
      bool buttonClicked = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyStateWidget(
              icon: Icons.shopping_cart_outlined,
              title: 'Your Shopping Cart is Empty',
              description: 'Discover hallmark 1 Gram Gold jewellery.',
              buttonText: 'Start Shopping',
              onButtonPressed: () {
                buttonClicked = true;
              },
            ),
          ),
        ),
      );

      expect(find.text('Your Shopping Cart is Empty'), findsOneWidget);
      expect(find.text('Discover hallmark 1 Gram Gold jewellery.'), findsOneWidget);
      expect(find.text('Start Shopping'), findsOneWidget);
      expect(find.byIcon(Icons.shopping_cart_outlined), findsOneWidget);

      await tester.tap(find.text('Start Shopping'));
      expect(buttonClicked, true);
    });

    testWidgets('PriceBreakdownCard displays transparent gold jewellery pricing', (WidgetTester tester) async {
      final product = ProductModel(
        id: 1,
        categoryId: 1,
        name: 'Heritage Choker',
        slug: 'heritage-choker',
        sku: 'GLD-CHK-01',
        regularPrice: 3999,
        salePrice: 2999,
        stockQuantity: 5,
        material: '1 Gram Gold',
        goldType: '24K Micron Gold Formulated',
        goldWeight: 1.0,
        makingCharges: 350,
        gstPercentage: 3.0,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PriceBreakdownCard(product: product),
          ),
        ),
      );

      expect(find.text('Transparent Jewellery Price Breakdown'), findsOneWidget);
      expect(find.text('24K Micron Gold Formulated'), findsOneWidget);
      expect(find.text('1.0 grams'), findsOneWidget);
      expect(find.text('Final Selling Price'), findsOneWidget);
    });

    test('ProductModel parses live backend PHP response keys without crash', () {
      final backendJson = {
        'id': 11,
        'name': '99.9% Pure Solid Copper Kada',
        'slug': 'pure-solid-copper-kada',
        'sku': 'CPR-KAD-011',
        'category_id': 3,
        'category_name': 'Copper Items',
        'price': 749,
        'mrp': 1299,
        'stock_quantity': 45,
        'is_featured': 1,
        'is_best_seller': 1,
        'is_new_arrival': 1,
        'material': '99.9% Pure Copper',
        'making_charge': 80,
        'gst_percent': 3,
        'primary_image': 'https://gold.dccsakti.in/uploads/products/copper_kada.jpg'
      };

      final product = ProductModel.fromJson(backendJson);
      expect(product.id, 11);
      expect(product.name, '99.9% Pure Solid Copper Kada');
      expect(product.regularPrice, 1299.0);
      expect(product.salePrice, 749.0);
      expect(product.price, 749.0);
      expect(product.isBestseller, true);
      expect(product.makingCharges, 80.0);
      expect(product.gstPercentage, 3.0);
    });
  });
}
