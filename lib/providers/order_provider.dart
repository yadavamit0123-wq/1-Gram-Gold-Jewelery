import 'package:flutter/material.dart';
import '../models/address_model.dart';
import '../models/order_model.dart';
import '../services/api_service.dart';
import 'cart_provider.dart';

class OrderProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();

  // Orders
  List<OrderModel> _orders = [];
  bool _isLoadingOrders = false;
  String? _ordersError;

  // Selected Order
  OrderModel? _currentOrderDetail;
  bool _isLoadingDetail = false;

  // Addresses
  List<AddressModel> _addresses = [];
  AddressModel? _selectedAddress;
  bool _isLoadingAddresses = false;
  String? _addressError;

  // Checkout
  String _paymentMethod = 'COD';
  bool _isPlacingOrder = false;
  String? _checkoutError;

  // Coupon & Settings
  String? _couponCode;
  double _couponDiscount = 0.0;
  String? _couponMessage;
  bool _isApplyingCoupon = false;
  double _shippingFee = 99.0;
  double _freeShippingThreshold = 999.0;
  bool _codEnabled = true;

  // Getters
  List<OrderModel> get orders => _orders;
  bool get isLoadingOrders => _isLoadingOrders;
  String? get ordersError => _ordersError;

  OrderModel? get currentOrderDetail => _currentOrderDetail;
  bool get isLoadingDetail => _isLoadingDetail;

  List<AddressModel> get addresses => _addresses;
  AddressModel? get selectedAddress => _selectedAddress;
  bool get isLoadingAddresses => _isLoadingAddresses;
  String? get addressError => _addressError;

  String get paymentMethod => _paymentMethod;
  bool get isPlacingOrder => _isPlacingOrder;
  String? get checkoutError => _checkoutError;

  String? get couponCode => _couponCode;
  double get couponDiscount => _couponDiscount;
  String? get couponMessage => _couponMessage;
  bool get isApplyingCoupon => _isApplyingCoupon;
  double get shippingFee => _shippingFee;
  double get freeShippingThreshold => _freeShippingThreshold;
  bool get codEnabled => _codEnabled;

  void setPaymentMethod(String method) {
    _paymentMethod = method;
    notifyListeners();
  }

  void selectAddress(AddressModel address) {
    _selectedAddress = address;
    notifyListeners();
  }

  // Load Settings
  Future<void> loadStoreSettings() async {
    try {
      final s = await _apiService.getStoreSettings();
      if (s.isNotEmpty) {
        if (s['shipping_fee'] != null) {
          _shippingFee = double.tryParse(s['shipping_fee'].toString()) ?? 99.0;
        }
        if (s['free_shipping_threshold'] != null) {
          _freeShippingThreshold = double.tryParse(s['free_shipping_threshold'].toString()) ?? 999.0;
        }
        if (s['cod_enabled'] != null) {
          _codEnabled = s['cod_enabled'] == true || s['cod_enabled'].toString() == '1';
        }
        notifyListeners();
      }
    } catch (_) {}
  }

  // Apply Coupon
  Future<bool> applyCoupon(String code, double subtotal) async {
    _isApplyingCoupon = true;
    _couponMessage = null;
    notifyListeners();

    try {
      final res = await _apiService.validateCoupon(code, subtotal);
      if (res['valid'] == true) {
        _couponCode = res['coupon_code']?.toString() ?? code.toUpperCase();
        _couponDiscount = double.tryParse(res['discount_amount']?.toString() ?? '0') ?? 0.0;
        _couponMessage = 'Coupon applied successfully!';
        _isApplyingCoupon = false;
        notifyListeners();
        return true;
      }
    } on ApiException catch (e) {
      _couponMessage = e.message;
    } catch (e) {
      _couponMessage = 'Failed to apply coupon';
    }

    _isApplyingCoupon = false;
    notifyListeners();
    return false;
  }

  void removeCoupon() {
    _couponCode = null;
    _couponDiscount = 0.0;
    _couponMessage = null;
    notifyListeners();
  }

  // Cancel Order
  Future<bool> cancelOrder(int orderId, String reason) async {
    try {
      final success = await _apiService.cancelOrder(orderId, reason);
      if (success) {
        await loadOrders();
        await loadOrderDetails(orderId);
        return true;
      }
    } catch (_) {}
    return false;
  }

  // Load Addresses
  Future<void> loadAddresses() async {
    _isLoadingAddresses = true;
    _addressError = null;
    notifyListeners();

    try {
      final list = await _apiService.getAddresses();
      _addresses = list;
      if (_addresses.isNotEmpty) {
        // Select default address if none selected
        _selectedAddress ??= _addresses.firstWhere(
          (a) => a.isDefault,
          orElse: () => _addresses.first,
        );
      }
    } catch (e) {
      _addressError = 'Failed to load addresses';
    } finally {
      _isLoadingAddresses = false;
      notifyListeners();
    }
  }

  // Save Address (Create or Update)
  Future<bool> saveAddress(AddressModel address) async {
    _isLoadingAddresses = true;
    notifyListeners();

    try {
      final saved = await _apiService.saveAddress(address);
      await loadAddresses();
      _selectedAddress = saved;
      _isLoadingAddresses = false;
      notifyListeners();
      return true;
    } catch (e) {
      _addressError = e.toString();
      _isLoadingAddresses = false;
      notifyListeners();
      return false;
    }
  }

  // Delete Address
  Future<bool> deleteAddress(int addressId) async {
    try {
      final ok = await _apiService.deleteAddress(addressId);
      if (ok) {
        if (_selectedAddress?.id == addressId) {
          _selectedAddress = null;
        }
        await loadAddresses();
        return true;
      }
    } catch (_) {}
    return false;
  }

  // Load Orders
  Future<void> loadOrders() async {
    _isLoadingOrders = true;
    _ordersError = null;
    notifyListeners();

    try {
      final list = await _apiService.getOrders();
      _orders = list;
    } catch (e) {
      _ordersError = 'Could not load your orders';
    } finally {
      _isLoadingOrders = false;
      notifyListeners();
    }
  }

  // Load Single Order Details
  Future<OrderModel?> loadOrderDetails(int orderId) async {
    _isLoadingDetail = true;
    _currentOrderDetail = null;
    notifyListeners();

    try {
      final order = await _apiService.getOrderDetails(orderId);
      _currentOrderDetail = order;
      return order;
    } catch (_) {
      return null;
    } finally {
      _isLoadingDetail = false;
      notifyListeners();
    }
  }

  // Place Order Checkout
  Future<OrderModel?> placeOrder({
    required CartProvider cartProvider,
    String? notes,
  }) async {
    if (_selectedAddress == null) {
      _checkoutError = 'Please select a delivery address';
      notifyListeners();
      return null;
    }

    _isPlacingOrder = true;
    _checkoutError = null;
    notifyListeners();

    try {
      final order = await _apiService.placeOrder(
        address: _selectedAddress!,
        paymentMethod: _paymentMethod,
        couponCode: _couponCode,
        notes: notes,
      );

      // Successfully placed: reload orders, clear cart, and reset coupon
      removeCoupon();
      cartProvider.clearCart();
      await loadOrders();
      _isPlacingOrder = false;
      notifyListeners();
      return order;
    } on ApiException catch (e) {
      _checkoutError = e.message;
    } catch (e) {
      _checkoutError = 'Failed to place order. Please try again.';
    }

    _isPlacingOrder = false;
    notifyListeners();
    return null;
  }

  void clearCheckoutError() {
    _checkoutError = null;
    notifyListeners();
  }
}
