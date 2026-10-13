import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/address_model.dart';
import '../models/banner_model.dart';
import '../models/category_model.dart';
import '../models/order_model.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';
import 'storage_service.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiService {
  final http.Client _client = http.Client();
  final Duration _timeout = const Duration(seconds: 15);

  Future<Map<String, String>> _getHeaders({bool requireAuth = false}) async {
    final storage = await StorageService.getInstance();
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      'X-Session-ID': storage.getOrCreateGuestSessionId(),
    };

    final token = storage.getAuthToken();
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
      // Shared hosting (cPanel) often drops Authorization; backend also reads this header.
      headers['X-Access-Token'] = token;
    } else if (requireAuth) {
      throw ApiException('Please log in to continue', statusCode: 401);
    }

    return headers;
  }

  dynamic _processResponse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(response.body);
    } catch (_) {
      if (response.statusCode >= 500) {
        throw ApiException('Server error. Please try again later.', statusCode: response.statusCode);
      }
      throw ApiException('Invalid server response (${response.statusCode})', statusCode: response.statusCode);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    // Error response
    String errorMessage = 'Something went wrong';
    if (body is Map<String, dynamic>) {
      if (body['message'] != null) {
        errorMessage = body['message'].toString();
      } else if (body['error'] != null) {
        errorMessage = body['error'].toString();
      }
    }
    throw ApiException(errorMessage, statusCode: response.statusCode);
  }

  Future<dynamic> _safeRequest(Future<http.Response> Function() request) async {
    try {
      final response = await request().timeout(_timeout);
      return _processResponse(response);
    } on SocketException {
      throw ApiException('Network connection failed. Please verify your internet connection.');
    } on TimeoutException {
      throw ApiException('Server request timed out. Please try again.');
    } on http.ClientException {
      throw ApiException('Network error occurred. Please try again.');
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('An unexpected error occurred: ${e.toString()}');
    }
  }

  // ==========================================
  // AUTHENTICATION
  // ==========================================

  Future<UserModel> login({required String email, required String password}) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${AppConstants.baseUrl}/auth/customer_login.php');

    final res = await _safeRequest(() => _client.post(
          url,
          headers: headers,
          body: jsonEncode({
            'identifier': email,
            'email': email,
            'password': password,
          }),
        ));

    if (res['success'] == true && res['data'] != null) {
      final data = res['data'];
      final token = res['token']?.toString() ?? data['token']?.toString();
      final userData = data['customer'] is Map<String, dynamic>
          ? data['customer'] as Map<String, dynamic>
          : (data is Map<String, dynamic> ? data : <String, dynamic>{});
      final user = UserModel.fromJson(userData, token: token);
      final storage = await StorageService.getInstance();
      if (token != null) await storage.setAuthToken(token);
      await storage.setUser(user);
      return user;
    }
    throw ApiException(res['message']?.toString() ?? 'Login failed');
  }

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
    String? phone,
  }) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${AppConstants.baseUrl}/auth/customer_register.php');

    final res = await _safeRequest(() => _client.post(
          url,
          headers: headers,
          body: jsonEncode({
            'name': name,
            'email': email,
            'password': password,
            'phone': phone ?? '',
          }),
        ));

    if (res['success'] == true && res['data'] != null) {
      final data = res['data'];
      final token = res['token']?.toString() ?? data['token']?.toString();
      final userData = data['customer'] is Map<String, dynamic>
          ? data['customer'] as Map<String, dynamic>
          : (data is Map<String, dynamic> ? data : <String, dynamic>{});
      final user = UserModel.fromJson(userData, token: token);
      final storage = await StorageService.getInstance();
      if (token != null) await storage.setAuthToken(token);
      await storage.setUser(user);
      return user;
    }
    throw ApiException(res['message']?.toString() ?? 'Registration failed');
  }

  Future<UserModel?> getProfile() async {
    final headers = await _getHeaders(requireAuth: true);
    final url = Uri.parse('${AppConstants.baseUrl}/auth/profile.php');

    final res = await _safeRequest(() => _client.get(url, headers: headers));
    if (res['success'] == true && res['data'] != null) {
      final data = res['data'];
      final userData = data['customer'] is Map<String, dynamic>
          ? data['customer'] as Map<String, dynamic>
          : (data is Map<String, dynamic> ? data : <String, dynamic>{});
      final storage = await StorageService.getInstance();
      final user = UserModel.fromJson(userData, token: storage.getAuthToken());
      await storage.setUser(user);
      return user;
    }
    return null;
  }

  Future<bool> deleteAccount() async {
    final headers = await _getHeaders(requireAuth: true);
    final url = Uri.parse('${AppConstants.baseUrl}/auth/profile.php');

    final res = await _safeRequest(() => _client.delete(url, headers: headers));
    if (res['success'] == true) {
      final storage = await StorageService.getInstance();
      await storage.clearAllAuth();
      return true;
    }
    throw ApiException(res['message']?.toString() ?? 'Failed to delete account');
  }

  // ==========================================
  // BANNERS & CATEGORIES
  // ==========================================

  Future<List<BannerModel>> getBanners() async {
    final headers = await _getHeaders();
    final url = Uri.parse('${AppConstants.baseUrl}/banners.php');

    final res = await _safeRequest(() => _client.get(url, headers: headers));
    final list = <BannerModel>[];
    if (res['success'] == true && res['data'] != null) {
      final rawList = res['data'] is List
          ? res['data']
          : (res['data'] is Map && res['data']['banners'] is List ? res['data']['banners'] : []);
      for (final b in rawList) {
        if (b is Map<String, dynamic>) {
          list.add(BannerModel.fromJson(b));
        }
      }
    }
    return list;
  }

  Future<List<CategoryModel>> getCategories() async {
    final headers = await _getHeaders();
    final url = Uri.parse('${AppConstants.baseUrl}/categories.php');

    final res = await _safeRequest(() => _client.get(url, headers: headers));
    final list = <CategoryModel>[];
    if (res['success'] == true && res['data'] != null) {
      final rawList = res['data'] is List
          ? res['data']
          : (res['data'] is Map && res['data']['categories'] is List ? res['data']['categories'] : []);
      for (final c in rawList) {
        if (c is Map<String, dynamic>) {
          list.add(CategoryModel.fromJson(c));
        }
      }
    }
    return list;
  }

  // ==========================================
  // PRODUCTS
  // ==========================================

  Future<List<ProductModel>> getProducts({
    String? search,
    int? categoryId,
    int? subcategoryId,
    double? minPrice,
    double? maxPrice,
    String? material,
    bool? inStock,
    bool? isFeatured,
    bool? isBestseller,
    bool? isNewArrival,
    String? sortBy,
    int page = 1,
    int limit = 20,
  }) async {
    final headers = await _getHeaders();
    final queryParams = <String, String>{
      'page': page.toString(),
      'limit': limit.toString(),
    };

    if (search != null && search.trim().isNotEmpty) {
      queryParams['search'] = search.trim();
    }
    if (categoryId != null && categoryId > 0) {
      queryParams['category_id'] = categoryId.toString();
    }
    if (subcategoryId != null && subcategoryId > 0) {
      queryParams['subcategory_id'] = subcategoryId.toString();
    }
    if (minPrice != null) queryParams['min_price'] = minPrice.toString();
    if (maxPrice != null) queryParams['max_price'] = maxPrice.toString();
    if (material != null && material.isNotEmpty) queryParams['material'] = material;
    if (inStock == true) queryParams['in_stock'] = '1';
    if (isFeatured == true) queryParams['is_featured'] = '1';
    if (isBestseller == true) queryParams['is_bestseller'] = '1';
    if (isNewArrival == true) queryParams['is_new_arrival'] = '1';
    if (sortBy != null && sortBy.isNotEmpty) queryParams['sort_by'] = sortBy;

    final url = Uri.parse('${AppConstants.baseUrl}/products.php').replace(queryParameters: queryParams);

    final res = await _safeRequest(() => _client.get(url, headers: headers));
    final list = <ProductModel>[];
    if (res['success'] == true && res['data'] != null) {
      final items = res['data'] is List
          ? res['data']
          : (res['data'] is Map && res['data']['products'] is List
              ? res['data']['products']
              : (res['data'] is Map && res['data']['items'] is List ? res['data']['items'] : []));
      for (final p in items) {
        if (p is Map<String, dynamic>) {
          list.add(ProductModel.fromJson(p));
        }
      }
    }
    return list;
  }

  Future<ProductModel?> getProductDetails(int productId) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${AppConstants.baseUrl}/product_details.php?id=$productId');

    final res = await _safeRequest(() => _client.get(url, headers: headers));
    if (res['success'] == true && res['data'] != null) {
      final data = res['data'] is Map && res['data']['product'] != null
          ? res['data']['product']
          : res['data'];
      if (data is Map<String, dynamic>) {
        return ProductModel.fromJson(data);
      }
    }
    return null;
  }

  // ==========================================
  // CART
  // ==========================================

  Future<Map<String, dynamic>> getCart() async {
    final headers = await _getHeaders();
    final storage = await StorageService.getInstance();
    final sessionId = storage.getOrCreateGuestSessionId();
    final url = Uri.parse('${AppConstants.baseUrl}/cart.php?session_id=$sessionId');

    final res = await _safeRequest(() => _client.get(url, headers: headers));
    return res is Map<String, dynamic> ? res : {'success': false, 'data': {'items': []}};
  }

  Future<bool> addToCart({required int productId, int quantity = 1}) async {
    final headers = await _getHeaders();
    final storage = await StorageService.getInstance();
    final url = Uri.parse('${AppConstants.baseUrl}/cart.php');

    final res = await _safeRequest(() => _client.post(
          url,
          headers: headers,
          body: jsonEncode({
            'action': 'add',
            'product_id': productId,
            'quantity': quantity,
            'session_id': storage.getOrCreateGuestSessionId(),
          }),
        ));
    return res['success'] == true;
  }

  Future<bool> updateCartItem({required int itemId, required int quantity}) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${AppConstants.baseUrl}/cart.php');

    final res = await _safeRequest(() => _client.put(
          url,
          headers: headers,
          body: jsonEncode({
            'action': 'update',
            'item_id': itemId,
            'quantity': quantity,
          }),
        ));
    return res['success'] == true;
  }

  Future<bool> removeCartItem({required int itemId}) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${AppConstants.baseUrl}/cart.php?item_id=$itemId');

    final res = await _safeRequest(() => _client.delete(url, headers: headers));
    return res['success'] == true;
  }

  // ==========================================
  // WISHLIST
  // ==========================================

  Future<List<ProductModel>> getWishlist() async {
    final storage = await StorageService.getInstance();
    final token = storage.getAuthToken();

    // Logged in: fetch from server
    if (token != null && token.isNotEmpty) {
      final headers = await _getHeaders(requireAuth: true);
      final url = Uri.parse('${AppConstants.baseUrl}/wishlist.php');

      final res = await _safeRequest(() => _client.get(url, headers: headers));
      final list = <ProductModel>[];
      if (res['success'] == true && res['data'] is List) {
        for (final p in res['data']) {
          if (p is Map<String, dynamic>) {
            list.add(ProductModel.fromJson(p));
          }
        }
      }
      return list;
    }

    // Guest: fetch product models for saved IDs
    final guestIds = storage.getGuestWishlist();
    if (guestIds.isEmpty) return [];

    final list = <ProductModel>[];
    for (final id in guestIds) {
      try {
        final p = await getProductDetails(id);
        if (p != null) list.add(p);
      } catch (_) {}
    }
    return list;
  }

  Future<bool> addToWishlist(int productId) async {
    final storage = await StorageService.getInstance();
    final token = storage.getAuthToken();

    if (token != null && token.isNotEmpty) {
      final headers = await _getHeaders(requireAuth: true);
      final url = Uri.parse('${AppConstants.baseUrl}/wishlist.php');

      final res = await _safeRequest(() => _client.post(
            url,
            headers: headers,
            body: jsonEncode({'product_id': productId}),
          ));
      return res['success'] == true;
    }

    // Guest local storage
    final guestIds = storage.getGuestWishlist();
    if (!guestIds.contains(productId)) {
      guestIds.add(productId);
      await storage.setGuestWishlist(guestIds);
    }
    return true;
  }

  Future<bool> removeFromWishlist(int productId) async {
    final storage = await StorageService.getInstance();
    final token = storage.getAuthToken();

    if (token != null && token.isNotEmpty) {
      final headers = await _getHeaders(requireAuth: true);
      final url = Uri.parse('${AppConstants.baseUrl}/wishlist.php?product_id=$productId');

      final res = await _safeRequest(() => _client.delete(url, headers: headers));
      return res['success'] == true;
    }

    // Guest local storage
    final guestIds = storage.getGuestWishlist();
    guestIds.remove(productId);
    await storage.setGuestWishlist(guestIds);
    return true;
  }

  // ==========================================
  // ADDRESSES
  // ==========================================

  Future<List<AddressModel>> getAddresses() async {
    final headers = await _getHeaders(requireAuth: true);
    final url = Uri.parse('${AppConstants.baseUrl}/addresses.php');

    final res = await _safeRequest(() => _client.get(url, headers: headers));
    final list = <AddressModel>[];
    if (res['success'] == true && res['data'] != null) {
      final rawList = res['data'] is List
          ? res['data']
          : (res['data'] is Map && res['data']['addresses'] is List ? res['data']['addresses'] : []);
      for (final a in rawList) {
        if (a is Map<String, dynamic>) {
          list.add(AddressModel.fromJson(a));
        }
      }
    }
    return list;
  }

  Future<AddressModel> saveAddress(AddressModel address) async {
    final headers = await _getHeaders(requireAuth: true);
    final url = Uri.parse('${AppConstants.baseUrl}/addresses.php');

    if (address.id > 0) {
      // Update
      final res = await _safeRequest(() => _client.put(
            url,
            headers: headers,
            body: jsonEncode(address.toJson()),
          ));
      if (res['success'] == true && res['data'] != null) {
        final raw = res['data'] is Map && res['data']['address'] is Map
            ? res['data']['address'] as Map<String, dynamic>
            : (res['data'] is Map<String, dynamic> ? res['data'] as Map<String, dynamic> : <String, dynamic>{});
        return AddressModel.fromJson(raw);
      }
    } else {
      // Create
      final res = await _safeRequest(() => _client.post(
            url,
            headers: headers,
            body: jsonEncode(address.toJson()),
          ));
      if (res['success'] == true && res['data'] != null) {
        final raw = res['data'] is Map && res['data']['address'] is Map
            ? res['data']['address'] as Map<String, dynamic>
            : (res['data'] is Map<String, dynamic> ? res['data'] as Map<String, dynamic> : <String, dynamic>{});
        return AddressModel.fromJson(raw);
      }
    }
    throw ApiException('Failed to save address');
  }

  Future<bool> deleteAddress(int addressId) async {
    final headers = await _getHeaders(requireAuth: true);
    final url = Uri.parse('${AppConstants.baseUrl}/addresses.php?id=$addressId');

    final res = await _safeRequest(() => _client.delete(url, headers: headers));
    return res['success'] == true;
  }

  // ==========================================
  // ORDERS & CHECKOUT
  // ==========================================

  Future<List<OrderModel>> getOrders() async {
    final headers = await _getHeaders(requireAuth: true);
    final url = Uri.parse('${AppConstants.baseUrl}/orders.php');

    final res = await _safeRequest(() => _client.get(url, headers: headers));
    final list = <OrderModel>[];
    if (res['success'] == true && res['data'] != null) {
      final rawList = res['data'] is List
          ? res['data']
          : (res['data'] is Map && res['data']['orders'] is List ? res['data']['orders'] : []);
      for (final o in rawList) {
        if (o is Map<String, dynamic>) {
          list.add(OrderModel.fromJson(o));
        }
      }
    }
    return list;
  }

  Future<OrderModel?> getOrderDetails(int orderId) async {
    final headers = await _getHeaders(requireAuth: true);
    final url = Uri.parse('${AppConstants.baseUrl}/orders.php?id=$orderId');

    final res = await _safeRequest(() => _client.get(url, headers: headers));
    if (res['success'] == true && res['data'] != null) {
      final orderData = res['data'] is Map && res['data']['order'] != null ? res['data']['order'] : res['data'];
      return OrderModel.fromJson(orderData);
    }
    return null;
  }

  Future<OrderModel> placeOrder({
    required AddressModel address,
    required String paymentMethod,
    String? couponCode,
    String? notes,
  }) async {
    final headers = await _getHeaders(requireAuth: true);
    final storage = await StorageService.getInstance();
    final url = Uri.parse('${AppConstants.baseUrl}/orders.php');

    final res = await _safeRequest(() => _client.post(
          url,
          headers: headers,
          body: jsonEncode({
            'action': 'place_order',
            'address_id': address.id > 0 ? address.id : null,
            'payment_method': paymentMethod,
            'coupon_code': couponCode,
            'notes': notes ?? '',
            'session_id': storage.getOrCreateGuestSessionId(),
          }),
        ));

    if (res['success'] == true && res['data'] != null) {
      final orderData = res['data'] is Map && res['data']['order'] != null ? res['data']['order'] : res['data'];
      return OrderModel.fromJson(orderData);
    }
    throw ApiException(res['message']?.toString() ?? 'Order placement failed');
  }

  Future<Map<String, dynamic>> getStoreSettings() async {
    final headers = await _getHeaders();
    final url = Uri.parse('${AppConstants.baseUrl}/settings.php');

    final res = await _safeRequest(() => _client.get(url, headers: headers));
    if (res['success'] == true && res['data'] is Map<String, dynamic>) {
      return res['data'];
    }
    return {};
  }

  Future<Map<String, dynamic>> validateCoupon(String code, double subtotal) async {
    final headers = await _getHeaders();
    final url = Uri.parse('${AppConstants.baseUrl}/coupons.php');

    final res = await _safeRequest(() => _client.post(
          url,
          headers: headers,
          body: jsonEncode({
            'code': code,
            'subtotal': subtotal,
          }),
        ));

    if (res['success'] == true && res['data'] != null) {
      return res['data'];
    }
    throw ApiException(res['message']?.toString() ?? 'Invalid coupon');
  }

  Future<bool> cancelOrder(int orderId, String reason) async {
    final headers = await _getHeaders(requireAuth: true);
    final url = Uri.parse('${AppConstants.baseUrl}/orders.php');

    final res = await _safeRequest(() => _client.post(
          url,
          headers: headers,
          body: jsonEncode({
            'action': 'cancel',
            'order_id': orderId,
            'reason': reason,
          }),
        ));

    return res['success'] == true;
  }

  Future<bool> verifyPayment({
    required int orderId,
    required String paymentId,
    required String signature,
    String paymentMethod = 'razorpay',
  }) async {
    final headers = await _getHeaders(requireAuth: true);
    final url = Uri.parse('${AppConstants.baseUrl}/payments/verify.php');

    final res = await _safeRequest(() => _client.post(
          url,
          headers: headers,
          body: jsonEncode({
            'order_id': orderId,
            'gateway_payment_id': paymentId,
            'gateway_signature': signature,
            'payment_method': paymentMethod,
          }),
        ));

    return res['success'] == true;
  }
}
