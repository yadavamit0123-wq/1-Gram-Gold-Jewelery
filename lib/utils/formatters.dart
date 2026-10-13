import 'package:intl/intl.dart';

class Formatters {
  static final NumberFormat _currencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 0,
  );

  static final NumberFormat _decimalCurrencyFormat = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  static final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  static final DateFormat _dateTimeFormat = DateFormat('dd MMM yyyy, hh:mm a');

  static String formatPrice(num? price, {bool showDecimals = false}) {
    if (price == null) return '₹0';
    if (showDecimals) {
      return _decimalCurrencyFormat.format(price);
    }
    return _currencyFormat.format(price.round());
  }

  static String formatDate(dynamic date) {
    if (date == null) return '';
    if (date is DateTime) return _dateFormat.format(date);
    try {
      final parsed = DateTime.parse(date.toString());
      return _dateFormat.format(parsed);
    } catch (_) {
      return date.toString();
    }
  }

  static String formatDateTime(dynamic date) {
    if (date == null) return '';
    if (date is DateTime) return _dateTimeFormat.format(date);
    try {
      final parsed = DateTime.parse(date.toString());
      return _dateTimeFormat.format(parsed);
    } catch (_) {
      return date.toString();
    }
  }

  static int calculateDiscountPercent(num? regularPrice, num? salePrice) {
    if (regularPrice == null || salePrice == null || regularPrice <= 0) return 0;
    if (salePrice >= regularPrice) return 0;
    final discount = ((regularPrice - salePrice) / regularPrice) * 100;
    return discount.round();
  }

  static double calculateSavings(num? regularPrice, num? salePrice) {
    if (regularPrice == null || salePrice == null) return 0.0;
    final savings = regularPrice - salePrice;
    return savings > 0 ? savings.toDouble() : 0.0;
  }
}
