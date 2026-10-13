import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/api_service.dart';
import 'cart_provider.dart';

class WishlistProvider extends ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<ProductModel> _items = [];
  bool _isLoading = false;
  String? _errorMessage;

  List<ProductModel> get items => _items;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get itemCount => _items.length;

  bool isInWishlist(int productId) {
    return _items.any((p) => p.id == productId);
  }

  Future<void> loadWishlist() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final list = await _apiService.getWishlist();
      _items = list;
    } catch (e) {
      _errorMessage = 'Could not load wishlist';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleWishlist(ProductModel product) async {
    final exists = isInWishlist(product.id);
    if (exists) {
      _items.removeWhere((p) => p.id == product.id);
      notifyListeners();

      try {
        await _apiService.removeFromWishlist(product.id);
        return false;
      } catch (_) {
        // Rollback
        _items.add(product);
        notifyListeners();
        return true;
      }
    } else {
      _items.add(product);
      notifyListeners();

      try {
        await _apiService.addToWishlist(product.id);
        return true;
      } catch (_) {
        // Rollback
        _items.removeWhere((p) => p.id == product.id);
        notifyListeners();
        return false;
      }
    }
  }

  Future<bool> removeFromWishlist(int productId) async {
    final idx = _items.indexWhere((p) => p.id == productId);
    if (idx == -1) return true;

    final removed = _items.removeAt(idx);
    notifyListeners();

    try {
      final ok = await _apiService.removeFromWishlist(productId);
      if (!ok) {
        _items.insert(idx, removed);
        notifyListeners();
        return false;
      }
      return true;
    } catch (_) {
      _items.insert(idx, removed);
      notifyListeners();
      return false;
    }
  }

  Future<bool> moveToCart(ProductModel product, CartProvider cartProvider) async {
    final added = await cartProvider.addToCart(product, quantity: 1);
    if (added) {
      await removeFromWishlist(product.id);
      return true;
    }
    return false;
  }
}
