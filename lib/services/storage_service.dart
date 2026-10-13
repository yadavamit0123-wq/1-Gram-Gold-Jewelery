import 'dart:convert';
import 'dart:math';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../utils/constants.dart';

class StorageService {
  static StorageService? _instance;
  static SharedPreferences? _prefs;

  StorageService._();

  static Future<StorageService> getInstance() async {
    _instance ??= StorageService._();
    _prefs ??= await SharedPreferences.getInstance();
    return _instance!;
  }

  // Auth Token
  String? getAuthToken() {
    return _prefs?.getString(AppConstants.keyAuthToken);
  }

  Future<bool> setAuthToken(String token) async {
    return await _prefs?.setString(AppConstants.keyAuthToken, token) ?? false;
  }

  Future<bool> clearAuthToken() async {
    return await _prefs?.remove(AppConstants.keyAuthToken) ?? false;
  }

  // User Profile
  UserModel? getUser() {
    final raw = _prefs?.getString(AppConstants.keyUserData);
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw);
      return UserModel.fromJson(map, token: getAuthToken());
    } catch (_) {
      return null;
    }
  }

  Future<bool> setUser(UserModel user) async {
    final raw = jsonEncode(user.toJson());
    return await _prefs?.setString(AppConstants.keyUserData, raw) ?? false;
  }

  Future<bool> clearUser() async {
    return await _prefs?.remove(AppConstants.keyUserData) ?? false;
  }

  // Guest Session ID for Cart & Wishlist persistence across sessions
  String getOrCreateGuestSessionId() {
    String? id = _prefs?.getString(AppConstants.keyGuestSessionId);
    if (id == null || id.isEmpty) {
      final random = Random();
      id = 'guest_${DateTime.now().millisecondsSinceEpoch}_${random.nextInt(999999)}';
      _prefs?.setString(AppConstants.keyGuestSessionId, id);
    }
    return id;
  }

  // Guest Wishlist (list of product IDs)
  List<int> getGuestWishlist() {
    final list = _prefs?.getStringList(AppConstants.keyGuestWishlist);
    if (list == null) return [];
    return list.map((e) => int.tryParse(e) ?? 0).where((id) => id > 0).toList();
  }

  Future<bool> setGuestWishlist(List<int> productIds) async {
    final list = productIds.map((e) => e.toString()).toList();
    return await _prefs?.setStringList(AppConstants.keyGuestWishlist, list) ?? false;
  }

  // API Host Override (for testing on LAN or emulator)
  String? getHostOverride() {
    return _prefs?.getString(AppConstants.keyApiHostOverride);
  }

  Future<bool> setHostOverride(String host) async {
    return await _prefs?.setString(AppConstants.keyApiHostOverride, host) ?? false;
  }

  // Complete Logout cleanup
  Future<void> clearAllAuth() async {
    await clearAuthToken();
    await clearUser();
  }
}
