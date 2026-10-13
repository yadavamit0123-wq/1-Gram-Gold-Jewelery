class AddressModel {
  final int id;
  final int? customerId;
  final String fullName;
  final String phone;
  final String addressLine1;
  final String? addressLine2;
  final String city;
  final String state;
  final String postalCode;
  final bool isDefault;

  AddressModel({
    required this.id,
    this.customerId,
    required this.fullName,
    required this.phone,
    required this.addressLine1,
    this.addressLine2,
    required this.city,
    required this.state,
    required this.postalCode,
    this.isDefault = false,
  });

  String get formattedAddress {
    final buffer = StringBuffer();
    buffer.write(addressLine1);
    if (addressLine2 != null && addressLine2!.trim().isNotEmpty) {
      buffer.write(', ${addressLine2!.trim()}');
    }
    buffer.write(', $city, $state - $postalCode');
    return buffer.toString();
  }

  factory AddressModel.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic val) {
      if (val == null) return 0;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString()) ?? 0;
    }

    bool parseBool(dynamic val) {
      if (val == null) return false;
      if (val is bool) return val;
      final str = val.toString().toLowerCase();
      return str == '1' || str == 'true' || str == 'yes';
    }

    return AddressModel(
      id: parseInt(json['id']),
      customerId: json['customer_id'] != null ? parseInt(json['customer_id']) : null,
      fullName: json['full_name']?.toString() ?? json['name']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      addressLine1: json['address_line1']?.toString() ?? json['address']?.toString() ?? '',
      addressLine2: json['address_line2']?.toString() ?? json['landmark']?.toString(),
      city: json['city']?.toString() ?? '',
      state: json['state']?.toString() ?? '',
      postalCode: json['postal_code']?.toString() ?? json['pincode']?.toString() ?? '',
      isDefault: parseBool(json['is_default']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'full_name': fullName,
      'phone': phone,
      'address_line1': addressLine1,
      'address_line2': addressLine2,
      'city': city,
      'state': state,
      'postal_code': postalCode,
      'is_default': isDefault ? 1 : 0,
    };
  }

  AddressModel copyWith({
    int? id,
    int? customerId,
    String? fullName,
    String? phone,
    String? addressLine1,
    String? addressLine2,
    String? city,
    String? state,
    String? postalCode,
    bool? isDefault,
  }) {
    return AddressModel(
      id: id ?? this.id,
      customerId: customerId ?? this.customerId,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      addressLine1: addressLine1 ?? this.addressLine1,
      addressLine2: addressLine2 ?? this.addressLine2,
      city: city ?? this.city,
      state: state ?? this.state,
      postalCode: postalCode ?? this.postalCode,
      isDefault: isDefault ?? this.isDefault,
    );
  }
}
