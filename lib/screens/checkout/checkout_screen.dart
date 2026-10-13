import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/cart_provider.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';
import '../account/addresses_screen.dart';
import '../auth/login_screen.dart';
import '../orders/order_detail_screen.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});

  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  int _currentStep = 0; // 0: Address, 1: Payment, 2: Review & Place
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _couponController = TextEditingController();
  OrderModel? _placedOrder;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final orderProvider = Provider.of<OrderProvider>(context, listen: false);
      orderProvider.loadStoreSettings();
      final auth = Provider.of<AuthProvider>(context, listen: false);
      if (auth.isLoggedIn) {
        orderProvider.loadAddresses();
      }
    });
  }

  @override
  void dispose() {
    _notesController.dispose();
    _couponController.dispose();
    super.dispose();
  }

  Future<void> _handlePlaceOrder() async {
    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final cartProvider = Provider.of<CartProvider>(context, listen: false);

    final order = await orderProvider.placeOrder(
      cartProvider: cartProvider,
      notes: _notesController.text.trim(),
    );

    if (order != null && mounted) {
      setState(() {
        _placedOrder = order;
        _currentStep = 3; // Confirmation
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final cartProvider = Provider.of<CartProvider>(context);
    final orderProvider = Provider.of<OrderProvider>(context);

    // If not logged in, prompt customer to sign in or sign up
    if (!authProvider.isLoggedIn) {
      return Scaffold(
        appBar: AppBar(title: const Text('Checkout')),
        body: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 64, color: AppColors.gold),
              const SizedBox(height: 16),
              const Text(
                'Sign In to Checkout',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Please sign in or create an account to select delivery address and place your order safely.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => LoginScreen(
                          onLoginSuccess: () {
                            Navigator.pop(context);
                            orderProvider.loadAddresses();
                          },
                        ),
                      ),
                    );
                  },
                  child: const Text('Sign In or Register'),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_currentStep == 3 && _placedOrder != null) {
      return _buildConfirmationScreen(_placedOrder!);
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Checkout'),
      ),
      body: Column(
        children: [
          // Step Progress Indicator Bar (Amazon style)
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStepPill('1. Address', _currentStep >= 0, _currentStep == 0),
                const Icon(Icons.chevron_right, size: 16, color: AppColors.border),
                _buildStepPill('2. Payment', _currentStep >= 1, _currentStep == 1),
                const Icon(Icons.chevron_right, size: 16, color: AppColors.border),
                _buildStepPill('3. Summary', _currentStep >= 2, _currentStep == 2),
              ],
            ),
          ),
          const Divider(height: 1, color: AppColors.borderLight),

          // Step Body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  if (_currentStep == 0) _buildAddressStep(orderProvider),
                  if (_currentStep == 1) _buildPaymentStep(orderProvider),
                  if (_currentStep == 2) _buildReviewStep(cartProvider, orderProvider),
                ],
              ),
            ),
          ),

          // Bottom Bar
          _buildBottomAction(cartProvider, orderProvider),
        ],
      ),
    );
  }

  Widget _buildStepPill(String title, bool isCompleted, bool isCurrent) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 12,
        fontWeight: isCurrent ? FontWeight.w700 : (isCompleted ? FontWeight.w600 : FontWeight.w400),
        color: isCurrent ? AppColors.goldDark : (isCompleted ? AppColors.textPrimary : AppColors.textMuted),
      ),
    );
  }

  Widget _buildAddressStep(OrderProvider orderProvider) {
    final addresses = orderProvider.addresses;
    final selected = orderProvider.selectedAddress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Select Delivery Address', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            TextButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AddressesScreen(isSelecting: true)),
                );
              },
              icon: const Icon(Icons.add, size: 16),
              label: const Text('Add / Manage'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (addresses.isEmpty) ...[
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                const Icon(Icons.location_off_outlined, size: 36, color: AppColors.textMuted),
                const SizedBox(height: 8),
                const Text('No saved addresses found', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                const Text('Please add a delivery address to proceed with your order.'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AddressesScreen(isSelecting: true)),
                    );
                  },
                  child: const Text('Add Shipping Address'),
                ),
              ],
            ),
          ),
        ] else ...[
          ...addresses.map((addr) {
            final isSelected = selected?.id == addr.id;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isSelected ? AppColors.gold : AppColors.borderLight,
                  width: isSelected ? 2 : 1,
                ),
              ),
              child: RadioListTile<int>(
                value: addr.id,
                groupValue: selected?.id,
                activeColor: AppColors.gold,
                title: Text(addr.fullName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(addr.phone, style: const TextStyle(color: AppColors.textSecondary, fontSize: 12)),
                    const SizedBox(height: 2),
                    Text(addr.formattedAddress, style: const TextStyle(fontSize: 12, height: 1.3)),
                  ],
                ),
                onChanged: (_) => orderProvider.selectAddress(addr),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildPaymentStep(OrderProvider orderProvider) {
    final currentMethod = orderProvider.paymentMethod;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Select Payment Method', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),

        // Cash on Delivery (Admin Managed)
        if (orderProvider.codEnabled) ...[
          _buildPaymentTile(
            icon: Icons.money,
            title: 'Cash on Delivery (COD)',
            subtitle: 'Pay with cash upon delivery at your doorstep.',
            value: 'COD',
            currentGroup: currentMethod,
            onSelected: (val) => orderProvider.setPaymentMethod(val),
          ),
          const SizedBox(height: 10),
        ],

        // UPI / Google Pay / PhonePe
        _buildPaymentTile(
          icon: Icons.qr_code,
          title: 'UPI / QR Code',
          subtitle: 'Instant payment via Google Pay, PhonePe, Paytm, or BHIM.',
          value: 'UPI',
          currentGroup: currentMethod,
          onSelected: (val) => orderProvider.setPaymentMethod(val),
        ),
        const SizedBox(height: 10),

        // Credit / Debit Card & NetBanking
        _buildPaymentTile(
          icon: Icons.credit_card,
          title: 'Online NetBanking & Cards',
          subtitle: 'Visa, MasterCard, RuPay and top Indian banks.',
          value: 'Online',
          currentGroup: currentMethod,
          onSelected: (val) => orderProvider.setPaymentMethod(val),
        ),
      ],
    );
  }

  Widget _buildPaymentTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required String value,
    required String currentGroup,
    required ValueChanged<String> onSelected,
  }) {
    final isSelected = currentGroup == value;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isSelected ? AppColors.gold : AppColors.borderLight,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: RadioListTile<String>(
        value: value,
        groupValue: currentGroup,
        activeColor: AppColors.gold,
        title: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.goldDark),
            const SizedBox(width: 8),
            Expanded(child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14))),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
        ),
        onChanged: (val) {
          if (val != null) onSelected(val);
        },
      ),
    );
  }

  Widget _buildReviewStep(CartProvider cartProvider, OrderProvider orderProvider) {
    final selectedAddress = orderProvider.selectedAddress;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Review Order Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),

        // Delivery Address Recap
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Delivery To:', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                  TextButton(
                    onPressed: () => setState(() => _currentStep = 0),
                    child: const Text('Change', style: TextStyle(color: AppColors.goldDark, fontSize: 12)),
                  ),
                ],
              ),
              if (selectedAddress != null) ...[
                Text(selectedAddress.fullName, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 2),
                Text(selectedAddress.formattedAddress, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text('Phone: ${selectedAddress.phone}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Items Summary
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Items (${cartProvider.itemCount})', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
              const Divider(color: AppColors.borderLight),
              ...cartProvider.items.map((item) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            '${item.quantity} × ${item.name}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13),
                          ),
                        ),
                        Text(Formatters.formatPrice(item.subtotal), style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Promotional Coupon Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.borderLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.local_offer_outlined, size: 18, color: AppColors.goldDark),
                  SizedBox(width: 8),
                  Text('Promotional Coupon', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                ],
              ),
              const SizedBox(height: 10),
              if (orderProvider.couponCode != null) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECFDF5),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Coupon ${orderProvider.couponCode} Applied!', style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF065F46), fontSize: 13)),
                          Text('Saved ${Formatters.formatPrice(orderProvider.couponDiscount)}', style: const TextStyle(color: Color(0xFF047857), fontSize: 11)),
                        ],
                      ),
                      TextButton(
                        onPressed: () => orderProvider.removeCoupon(),
                        child: const Text('Remove', style: TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _couponController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: const InputDecoration(
                          hintText: 'Enter coupon code',
                          contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: orderProvider.isApplyingCoupon
                          ? null
                          : () {
                              final c = _couponController.text.trim();
                              if (c.isNotEmpty) {
                                orderProvider.applyCoupon(c, cartProvider.subtotal);
                              }
                            },
                      child: orderProvider.isApplyingCoupon
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Apply'),
                    ),
                  ],
                ),
                if (orderProvider.couponMessage != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    orderProvider.couponMessage!,
                    style: const TextStyle(fontSize: 12, color: Colors.red),
                  ),
                ],
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  children: ['WELCOME100', 'GOLD10', 'FESTIVE500'].map((chip) => ActionChip(
                    label: Text(chip, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.goldDark)),
                    backgroundColor: const Color(0xFFFFFDF5),
                    onPressed: () {
                      _couponController.text = chip;
                      orderProvider.applyCoupon(chip, cartProvider.subtotal);
                    },
                  )).toList(),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Authoritative Server-Calculated Price Breakdown
        Builder(builder: (context) {
          final subtotal = cartProvider.subtotal;
          final discount = orderProvider.couponDiscount;
          final taxable = (subtotal - discount).clamp(0.0, double.infinity);
          final shipping = (subtotal >= orderProvider.freeShippingThreshold) ? 0.0 : orderProvider.shippingFee;
          final taxAmount = (taxable * 0.03); // 3% GST standard
          final grandTotal = taxable + shipping;

          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderLight),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Items Subtotal:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    Text(Formatters.formatPrice(subtotal), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                  ],
                ),
                if (discount > 0) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Coupon Discount (${orderProvider.couponCode}):', style: const TextStyle(fontSize: 13, color: Color(0xFF15803D))),
                      Text('-${Formatters.formatPrice(discount)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF15803D))),
                    ],
                  ),
                ],
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Standard Insured Shipping:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                    Text(
                      shipping == 0 ? 'FREE' : Formatters.formatPrice(shipping),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: shipping == 0 ? AppColors.success : AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('GST Included (3%):', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                    Text(Formatters.formatPrice(taxAmount), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                  ],
                ),
                const SizedBox(height: 8),
                const Divider(color: AppColors.borderLight),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Final Total Amount:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                    Text(
                      Formatters.formatPrice(grandTotal),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.goldDark),
                    ),
                  ],
                ),
              ],
            ),
          );
        }),

        // Error message if any
        if (orderProvider.checkoutError != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFEE2E2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    orderProvider.checkoutError!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildBottomAction(CartProvider cartProvider, OrderProvider orderProvider) {
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
        child: Row(
          children: [
            if (_currentStep > 0)
              OutlinedButton(
                onPressed: () => setState(() => _currentStep--),
                child: const Text('Back'),
              ),
            if (_currentStep > 0) const SizedBox(width: 12),
            Expanded(
              child: ElevatedButton(
                onPressed: orderProvider.isPlacingOrder
                    ? null
                    : () {
                        if (_currentStep == 0) {
                          if (orderProvider.selectedAddress == null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please select or add a delivery address')),
                            );
                            return;
                          }
                          setState(() => _currentStep = 1);
                        } else if (_currentStep == 1) {
                          setState(() => _currentStep = 2);
                        } else if (_currentStep == 2) {
                          _handlePlaceOrder();
                        }
                      },
                child: orderProvider.isPlacingOrder
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        _currentStep == 2
                            ? 'Place Order (${Formatters.formatPrice(cartProvider.totalAmount)})'
                            : 'Continue',
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfirmationScreen(OrderModel order) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Order Placed'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Color(0xFFECFDF5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_circle, size: 72, color: AppColors.success),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Order Placed Successfully!',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: AppColors.primary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Thank you for your jewellery order. Your order number is:',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.gold.withOpacity(0.5)),
                  ),
                  child: Text(
                    order.orderNumber,
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.goldDark),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Total Paid / Payable: ${Formatters.formatPrice(order.totalAmount)} via ${order.paymentMethod}',
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OrderDetailScreen(orderId: order.id),
                        ),
                      );
                    },
                    child: const Text('Track Order Live'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },
                    child: const Text('Continue Shopping'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
