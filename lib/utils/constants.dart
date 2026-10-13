import 'package:flutter/foundation.dart';

class AppConstants {
  // Brand Identity (Class 14 Registered Trademark)
  static const String appName = '1 Gram Gold Jewellery';
  static const String brandTagline = 'Gold Imitate Quality Jewellery';
  static const String trademarkClass = 'Class 14 — Jewellery & Precious Metal Alloys';
  static const String trademarkNotice = 
      '1 GRAM GOLD JEWELLERY – GOLD IMITATE QUALITY JEWELLERY is a registered trademark under Class 14. '
      'All designs, formulations, and presentation materials are protected by intellectual property laws.';

  // Support & Store Details
  static const String supportEmail = 'support@1gramgoldjewellery.com';
  static const String supportPhone = '+91 98765 43210';
  static const String storeAddress = '123 Swarna Bourse, Jewelers Street, Mumbai, Maharashtra - 400002';
  static const double freeShippingThreshold = 999.0;
  static const double standardShippingFee = 99.0;

  // Production Domain & Live API Configuration
  static const String productionHost = 'https://1gramgoldjewelery.in';

  // API Configuration
  // 1. Build-time override via --dart-define=API_URL=https://...
  // 2. Automatically routes to live productionHost in release mode (kReleaseMode)
  // 3. Defaults to local emulator/web in debug mode
  static String get defaultHost {
    const envApi = String.fromEnvironment('API_URL');
    if (envApi.isNotEmpty) {
      return envApi;
    }
    // Default to the live production server so that all APK builds (debug or release)
    // and physical Android devices connect immediately out of the box.
    return productionHost;
  }

  // Base URLs
  static String baseUrl = '$defaultHost/api';
  static String mediaBaseUrl = defaultHost;

  static void setCustomHost(String host) {
    baseUrl = '$host/api';
    mediaBaseUrl = host;
  }

  // Resolves relative image path from API into full URL
  static String resolveImageUrl(String? path) {
    if (path == null || path.isEmpty) {
      return '';
    }
    if (path.startsWith('http://') || path.startsWith('https://')) {
      // If the URL has 127.0.0.1 and we're on android emulator, replace with 10.0.2.2
      if (!kIsWeb && defaultHost.contains('10.0.2.2') && path.contains('127.0.0.1:8000')) {
        return path.replaceAll('127.0.0.1:8000', '10.0.2.2:8000');
      }
      return path;
    }
    final cleanPath = path.startsWith('/') ? path : '/$path';
    return '$mediaBaseUrl$cleanPath';
  }

  // Storage Keys
  static const String keyAuthToken = 'auth_token';
  static const String keyUserData = 'user_data';
  static const String keyGuestSessionId = 'guest_session_id';
  static const String keyGuestWishlist = 'guest_wishlist';
  static const String keySavedAddresses = 'saved_addresses';
  static const String keyApiHostOverride = 'api_host_override';

  // Order Statuses
  static const String statusPending = 'Pending';
  static const String statusConfirmed = 'Confirmed';
  static const String statusProcessing = 'Processing';
  static const String statusShipped = 'Shipped';
  static const String statusOutForDelivery = 'Out for Delivery';
  static const String statusDelivered = 'Delivered';
  static const String statusCancelled = 'Cancelled';

  // Payment Methods
  static const String paymentCod = 'COD';
  static const String paymentOnline = 'Online';
  static const String paymentUpi = 'UPI';
}
