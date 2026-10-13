import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/order_model.dart';
import '../../providers/order_provider.dart';
import '../../theme/app_colors.dart';
import '../../utils/formatters.dart';

class OrderDetailScreen extends StatefulWidget {
  final int orderId;

  const OrderDetailScreen({super.key, required this.orderId});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<OrderProvider>(context, listen: false).loadOrderDetails(widget.orderId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final orderProvider = Provider.of<OrderProvider>(context);
    final order = orderProvider.currentOrderDetail;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Order #${widget.orderId}'),
      ),
      body: orderProvider.isLoadingDetail || order == null
          ? const Center(child: CircularProgressIndicator(color: AppColors.gold))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Header Status Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
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
                            Text(
                              order.orderNumber,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: _getStatusColor(order.status).withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                order.status.toUpperCase(),
                                style: TextStyle(
                                  color: _getStatusColor(order.status),
                                  fontWeight: FontWeight.w700,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Placed on ${Formatters.formatDateTime(order.createdAt)}',
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Order Tracking Timeline Card
                  _buildTrackingTimeline(order),
                  const SizedBox(height: 16),

                  // Items List Card
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Items in this Order',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 12),
                        const Divider(height: 1, color: AppColors.borderLight),
                        const SizedBox(height: 12),
                        ...order.items.map((item) => _buildItemRow(item)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Shipping Address Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Delivery Address',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          order.formattedAddress,
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment & Billing Card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.borderLight),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Payment & Billing Details',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Payment Method:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            Text(order.paymentMethod, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Payment Status:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            Text(
                              order.paymentStatus,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: order.paymentStatus.toLowerCase() == 'paid' ? AppColors.success : AppColors.goldDark,
                              ),
                            ),
                          ],
                        ),
                        if (order.discountAmount > 0) ...[
                          const SizedBox(height: 6),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('Coupon Discount (${order.couponCode ?? 'PROMO'}):', style: const TextStyle(fontSize: 13, color: Color(0xFF15803D))),
                              Text('-${Formatters.formatPrice(order.discountAmount)}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF15803D))),
                            ],
                          ),
                        ],
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Shipping Fee:', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                            Text(order.shippingFee == 0 ? 'FREE' : Formatters.formatPrice(order.shippingFee), style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('GST Included (${order.gstRate}%):', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            Text(Formatters.formatPrice(order.taxAmount), style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                          ],
                        ),
                        const SizedBox(height: 10),
                        const Divider(height: 1, color: AppColors.borderLight),
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total Amount:', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                            Text(
                              Formatters.formatPrice(order.totalAmount),
                              style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.goldDark),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Courier Dispatch Details if present
                  if ((order.courierPartner != null && order.courierPartner!.isNotEmpty) ||
                      (order.trackingNumber != null && order.trackingNumber!.isNotEmpty)) ...[
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: AppColors.borderLight),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Dispatch & Courier Partner', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          const SizedBox(height: 6),
                          if (order.courierPartner != null)
                            Text('Courier: ${order.courierPartner!}', style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                          if (order.trackingNumber != null)
                            Text('Tracking (AWB): ${order.trackingNumber!}', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
                        ],
                      ),
                    ),
                  ],

                  // Cancellation button if eligible
                  if (['pending', 'confirmed'].contains(order.status.toLowerCase())) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.cancel_outlined, color: Colors.red, size: 18),
                        label: const Text('Cancel This Order', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w700)),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: Colors.red),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: () => _confirmCancelOrder(order.id),
                      ),
                    ),
                  ],

                  const SizedBox(height: 30),
                ],
              ),
            ),
    );
  }

  Future<void> _confirmCancelOrder(int orderId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Order?'),
        content: const Text('Are you sure you want to cancel this order? Any reserved 1 Gram Gold jewellery will be immediately restored to stock.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Keep Order')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Yes, Cancel Order'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    final orderProvider = Provider.of<OrderProvider>(context, listen: false);
    final ok = await orderProvider.cancelOrder(orderId, 'Cancelled by customer in mobile app');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok ? 'Order cancelled successfully.' : 'Failed to cancel order.'),
        backgroundColor: ok ? AppColors.success : AppColors.error,
      ),
    );
  }

  Widget _buildItemRow(OrderItemModel item) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: Container(
              width: 54,
              height: 54,
              color: const Color(0xFFFBF9F5),
              child: item.fullImageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: item.fullImageUrl,
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) => const Center(
                        child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.gold),
                        ),
                      ),
                      errorWidget: (ctx, url, error) => const Icon(Icons.diamond_outlined, color: AppColors.goldDark),
                    )
                  : const Icon(Icons.diamond_outlined, color: AppColors.goldDark),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${item.quantity}  •  ${Formatters.formatPrice(item.unitPrice)} each',
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            Formatters.formatPrice(item.subtotal),
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingTimeline(OrderModel order) {
    final stages = [
      'Order Placed',
      'Confirmed',
      'Processing',
      'Shipped',
      'Out for Delivery',
      'Delivered',
    ];

    final currentStep = order.statusStepIndex;

    // Index order history entries by status for exact timestamps
    final historyMap = <String, OrderStatusHistoryItem>{};
    for (final h in order.history) {
      historyMap[h.newStatus.toLowerCase()] = h;
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Order Tracking Timeline',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
          ),
          const SizedBox(height: 16),
          if (order.status.toLowerCase() == 'cancelled') ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFEE2E2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.cancel, color: AppColors.error, size: 20),
                  SizedBox(width: 8),
                  Text('This order has been cancelled', style: TextStyle(color: AppColors.error, fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          ] else ...[
            Column(
              children: List.generate(stages.length, (index) {
                final isCompleted = currentStep >= index;
                final isCurrent = currentStep == index;
                final isLast = index == stages.length - 1;
                final hist = historyMap[stages[index].toLowerCase()];

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isCompleted ? AppColors.success : Colors.white,
                            border: Border.all(
                              color: isCompleted ? AppColors.success : AppColors.border,
                              width: 2,
                            ),
                          ),
                          child: isCompleted
                              ? const Icon(Icons.check, size: 14, color: Colors.white)
                              : null,
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: hist != null ? 40 : 28,
                            color: currentStep > index ? AppColors.success : AppColors.border,
                          ),
                      ],
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              stages[index],
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: isCurrent ? FontWeight.w700 : (isCompleted ? FontWeight.w600 : FontWeight.w400),
                                color: isCompleted ? AppColors.textPrimary : AppColors.textMuted,
                              ),
                            ),
                            if (hist != null) ...[
                              const SizedBox(height: 2),
                              Text(
                                hist.formattedDate ?? hist.createdAt,
                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                              ),
                              if (hist.notes != null && hist.notes!.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  hist.notes!,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ],
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'delivered':
        return AppColors.success;
      case 'shipped':
      case 'out for delivery':
        return AppColors.info;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.goldDark;
    }
  }
}
