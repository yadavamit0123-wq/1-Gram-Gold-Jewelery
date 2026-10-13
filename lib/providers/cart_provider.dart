import 'package:flutter/material.dart';
import '../models/cart_item_model.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import '../utils/constants.dart';

class CartProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<CartItemModel> _items = [];
  bool _isLoading = false;
  bool _isSyncing = false;
  String? _errorMessage;

  List<CartItemModel> get items => _items;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get errorMessage => _errorMessage;

  int get itemCount => _items.fold<int>(0, (sum, item) => sum + item.quantity);

  double get subtotal => _items.fold<double>(0.0, (sum, item) => sum + item.subtotal);

  double get regularSubtotal => _items.fold<double>(0.0, (sum, item) {
        final reg = item.regularPrice ?? item.price;
        return sum + (reg * item.quantity);
      });

  double get discountAmount => regularSubtotal > subtotal ? (regularSubtotal - subtotal) : 0.0;

  double get shippingFee {
    if (_items.isEmpty) return 0.0;
    return subtotal >= AppConstants.freeShippingThreshold ? 0.0 : AppConstants.standardShippingFee;
  }

  double get totalAmount => subtotal + shippingFee;

  double get freeShippingRemaining {
    if (subtotal >= AppConstants.freeShippingThreshold) return 0.0;
    return AppConstants.freeShippingThreshold - subtotal;
  }

  bool get qualifiesForFreeShipping => subtotal >= AppConstants.freeShippingThreshold && _items.isNotEmpty;

  bool hasProductInCart(int productId) {
    return _items.any((item) => item.productId == productId);
  }

  int getProductQuantity(int productId) {
    final item = _items.firstWhere(
      (element) => element.productId == productId,
      orElse: () => CartItemModel(
        id: 0,
        productId: 0,
        name: '',
        price: 0,
        quantity: 0,
        stockQuantity: 0,
      ),
    );
    return item.quantity;
  }

  Future<void> loadCart() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await _apiService.getCart();
      final itemsList = <CartItemModel>[];
      if (res['success'] == true && res['data'] != null) {
        final data = res['data'];
        final list = data is Map && data['items'] is List ? data['items'] : (data is List ? data : []);
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            itemsList.add(CartItemModel.fromJson(item));
          }
        }
      }
      _items = itemsList;
    } catch (e) {
      _errorMessage = 'Could not fetch cart items';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addToCart(ProductModel product, {int quantity = 1}) async {
    _isSyncing = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final success = await _apiService.addToCart(
        productId: product.id,
        quantity: quantity,
      );

      if (success) {
        await loadCart();
        _isSyncing = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isSyncing = false;
    notifyListeners();
    return false;
  }

  Future<bool> updateQuantity(int itemId, int newQuantity) async {
    if (newQuantity <= 0) {
      return await removeItem(itemId);
    }

    _isSyncing = true;
    notifyListeners();

    try {
      final success = await _apiService.updateCartItem(
        itemId: itemId,
        quantity: newQuantity,
      );

      if (success) {
        // Optimistic / fast local update
        final idx = _items.indexWhere((it) => it.id == itemId);
        if (idx != -1) {
          _items[idx].quantity = newQuantity;
        }
        await loadCart();
        _isSyncing = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isSyncing = false;
    notifyListeners();
    return false;
  }

  Future<bool> removeItem(int itemId) async {
    _isSyncing = true;
    notifyListeners();

    try {
      final success = await _apiService.removeCartItem(itemId: itemId);
      if (success) {
        _items.removeWhere((it) => it.id == itemId);
        _isSyncing = false;
        notifyListeners();
        return true;
      }
    } catch (e) {
      _errorMessage = e.toString();
    }

    _isSyncing = false;
    notifyListeners();
    return false;
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
