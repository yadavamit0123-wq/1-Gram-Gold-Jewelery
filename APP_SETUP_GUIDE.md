# 1 GRAM GOLD JEWELLERY - FLUTTER MOBILE APP
## Source Code & Deployment Handover Guide

### 1. Overview
- **App Name**: 1 Gram Gold Jewellery
- **Package ID**: `com.onegramgold.jewellery`
- **Framework**: Flutter (Dart)
- **Target Platform**: Android & iOS
- **Architecture**: Modular BLoC / Repository Service Pattern with Dio HTTP client and offline caching.

---

### 2. Pre-Compiled Production Releases
Inside the `release_builds/` folder:
- `1_gram_gold_jewellery_app_release.apk` : Ready-to-install Android APK (can be installed on any Android phone directly).
- `1_gram_gold_jewellery_app_release.aab` : Google Play Store Release App Bundle (for uploading to Google Play Console).
- **Keystore**: The Android keystore is configured at `android/upload-keystore.jks` with credentials in `android/key.properties`.

---

### 3. How to Connect with Backend Server
Open `lib/utils/constants.dart`:
```dart
class AppConstants {
  // Update this to your live server domain:
  static const String defaultHost = 'https://your-domain.com';
  
  static String baseUrl = '$defaultHost/api';
  static String mediaBaseUrl = defaultHost;
}
```

---

### 4. How to Run & Build
#### Prerequisites:
- Flutter SDK (v3.19+ or higher)
- Android Studio / VS Code with Flutter & Dart extensions
- Java JDK 17

#### Steps:
1. Open terminal in this folder:
   ```bash
   flutter clean
   flutter pub get
   ```
2. Run on connected device / emulator:
   ```bash
   flutter run
   ```
3. Build new Release APK:
   ```bash
   flutter build apk --release
   ```
4. Build new Google Play Bundle (AAB):
   ```bash
   flutter build appbundle --release
   ```

---

### 5. Features Included
- Category & Subcategory Catalog Browsing (Ordinary, Premium, Luxury tiers)
- Live Search & Filtering
- Certified 1 Gram Gold Specification Badges (Micron plating, base metals)
- Customer Authentication (Login, Register, Profile management)
- Persistent Cart & Saved Delivery Addresses
- Instant Coupon Discounts
- Razorpay Payment Gateway & Cash on Delivery (COD)
- Real-time Order History & Stage Tracking
- Wishlist with 1-click Move to Cart
- Offline Cache & Network Resiliency