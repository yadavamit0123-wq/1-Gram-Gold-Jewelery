import 'dart:convert';
import '../utils/constants.dart';

class OrderItemModel {
  final int id;
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double subtotal;
  final String? image;
  final String? slug;

  OrderItemModel({
    required this.id,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.subtotal,
    this.image,
    this.slug,
  });

  String get fullImageUrl => AppConstants.resolveImageUrl(image);

  factory OrderItemModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? 0;
    }

    return OrderItemModel(
      id: parseInt(json['id']),
      productId: parseInt(json['product_id']),
      productName: json['product_name']?.toString() ?? json['name']?.toString() ?? 'Jewellery',
      quantity: parseInt(json['quantity']),
      unitPrice: parseDouble(json['unit_price'] ?? json['price']),
      subtotal: parseDouble(json['subtotal'] ?? json['total']),
      image: json['primary_image']?.toString() ?? json['image']?.toString() ?? json['product_image']?.toString(),
      slug: json['slug']?.toString() ?? json['product_slug']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': productId,
      'product_name': productName,
      'quantity': quantity,
      'unit_price': unitPrice,
      'subtotal': subtotal,
      'image': image,
      'slug': slug,
    };
  }
}

class OrderStatusHistoryItem {
  final int id;
  final String? previousStatus;
  final String newStatus;
  final String changedBy;
  final String? notes;
  final String createdAt;
  final String? formattedDate;

  OrderStatusHistoryItem({
    required this.id,
    this.previousStatus,
    required this.newStatus,
    required this.changedBy,
    this.notes,
    required this.createdAt,
    this.formattedDate,
  });

  factory OrderStatusHistoryItem.fromJson(Map<String, dynamic> json) {
    return OrderStatusHistoryItem(
      id: json['id'] is int ? json['id'] : int.tryParse(json['id'].toString()) ?? 0,
      previousStatus: json['previous_status']?.toString(),
      newStatus: json['new_status']?.toString() ?? 'Pending',
      changedBy: json['changed_by']?.toString() ?? 'System',
      notes: json['notes']?.toString(),
      createdAt: json['created_at']?.toString() ?? '',
      formattedDate: json['formatted_date']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'previous_status': previousStatus,
      'new_status': newStatus,
      'changed_by': changedBy,
      'notes': notes,
      'created_at': createdAt,
      'formatted_date': formattedDate,
    };
  }
}

class OrderModel {
  final int id;
  final String orderNumber;
  final double totalAmount;
  final double discountAmount;
  final double shippingFee;
  final double taxAmount;
  final double gstRate;
  final String? couponCode;
  final String status;
  final String paymentStatus;
  final String paymentMethod;
  final String? shippingAddressRaw;
  final String? trackingNumber;
  final String? courierPartner;
  final String? notes;
  final String createdAt;
  final String? updatedAt;
  final List<OrderItemModel> items;
  final List<OrderStatusHistoryItem> history;

  OrderModel({
    required this.id,
    required this.orderNumber,
    required this.totalAmount,
    this.discountAmount = 0.0,
    this.shippingFee = 0.0,
    this.taxAmount = 0.0,
    this.gstRate = 3.0,
    this.couponCode,
    required this.status,
    this.paymentStatus = 'Pending',
    this.paymentMethod = 'COD',
    this.shippingAddressRaw,
    this.trackingNumber,
    this.courierPartner,
    this.notes,
    required this.createdAt,
    this.updatedAt,
    this.items = const [],
    this.history = const [],
  });

  String get formattedAddress {
    if (shippingAddressRaw == null || shippingAddressRaw!.isEmpty) {
      return 'No address specified';
    }
    try {
      final decoded = jsonDecode(shippingAddressRaw!);
      if (decoded is Map<String, dynamic>) {
        final buffer = StringBuffer();
        if (decoded['full_name'] != null) buffer.writeln(decoded['full_name']);
        if (decoded['phone'] != null) buffer.writeln('Phone: ${decoded['phone']}');
        if (decoded['address_line1'] != null) buffer.write(decoded['address_line1']);
        if (decoded['address_line2'] != null && decoded['address_line2'].toString().isNotEmpty) {
          buffer.write(', ${decoded['address_line2']}');
        }
        if (decoded['city'] != null) buffer.write(', ${decoded['city']}');
        if (decoded['state'] != null) buffer.write(', ${decoded['state']}');
        if (decoded['postal_code'] != null) buffer.write(' - ${decoded['postal_code']}');
        return buffer.toString().trim();
      }
    } catch (_) {}
    return shippingAddressRaw!;
  }

  int get statusStepIndex {
    switch (status.toLowerCase()) {
      case 'pending':
        return 0;
      case 'confirmed':
        return 1;
      case 'processing':
        return 2;
      case 'shipped':
        return 3;
      case 'out for delivery':
        return 4;
      case 'delivered':
        return 5;
      case 'cancelled':
        return -1;
      default:
        return 0;
    }
  }

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    double parseDouble(dynamic val) {
      if (val == null) return 0.0;
      if (val is num) return val.toDouble();
      return double.tryParse(val.toString()) ?? 0.0;
    }

    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? 0;
    }

    final itemsList = <OrderItemModel>[];
    if (json['items'] is List) {
      for (final it in json['items']) {
        if (it is Map<String, dynamic>) {
          itemsList.add(OrderItemModel.fromJson(it));
        }
      }
    }

    final historyList = <OrderStatusHistoryItem>[];
    if (json['history'] is List) {
      for (final h in json['history']) {
        if (h is Map<String, dynamic>) {
          historyList.add(OrderStatusHistoryItem.fromJson(h));
        }
      }
    }

    return OrderModel(
      id: parseInt(json['id'] ?? json['order_id']),
      orderNumber: json['order_number']?.toString() ?? 'ORD-${json['id'] ?? json['order_id']}',
      totalAmount: parseDouble(json['total_amount'] ?? json['total']),
      discountAmount: parseDouble(json['discount_amount'] ?? json['coupon_discount'] ?? json['discount']),
      shippingFee: parseDouble(json['shipping_fee'] ?? json['shipping']),
      taxAmount: parseDouble(json['tax_amount'] ?? json['tax']),
      gstRate: parseDouble(json['gst_rate'] ?? 3.0),
      couponCode: json['coupon_code']?.toString(),
      status: json['order_status']?.toString() ?? json['status']?.toString() ?? 'Pending',
      paymentStatus: json['payment_status']?.toString() ?? 'Pending',
      paymentMethod: json['payment_method']?.toString() ?? 'COD',
      shippingAddressRaw: json['shipping_address']?.toString() ?? json['shipping_address_snapshot']?.toString(),
      trackingNumber: json['tracking_number']?.toString(),
      courierPartner: json['courier_partner']?.toString(),
      notes: json['notes']?.toString(),
      createdAt: json['created_at']?.toString() ?? DateTime.now().toIso8601String(),
      updatedAt: json['updated_at']?.toString(),
      items: itemsList,
      history: historyList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order_number': orderNumber,
      'total_amount': totalAmount,
      'discount_amount': discountAmount,
      'shipping_fee': shippingFee,
      'tax_amount': taxAmount,
      'gst_rate': gstRate,
      'coupon_code': couponCode,
      'status': status,
      'payment_status': paymentStatus,
      'payment_method': paymentMethod,
      'shipping_address': shippingAddressRaw,
      'tracking_number': trackingNumber,
      'courier_partner': courierPartner,
      'notes': notes,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'items': items.map((i) => i.toJson()).toList(),
      'history': history.map((h) => h.toJson()).toList(),
    };
  }
}
