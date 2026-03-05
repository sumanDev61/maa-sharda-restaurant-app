import 'dart:convert';

class Address {
  final String id;
  final String fullName;
  final String phone;
  final String line1;
  final String line2;
  final String city;
  final String state;
  final String pincode;
  final String landmark;
  final String type;
  final bool isDefault;
  final double? latitude;
  final double? longitude;
  final DateTime createdAt;
  Address({
    required this.id,
    required this.fullName,
    required this.phone,
    required this.line1,
    required this.line2,
    required this.city,
    required this.state,
    required this.pincode,
    required this.landmark,
    required this.type,
    required this.isDefault,
    this.latitude,
    this.longitude,
    required this.createdAt,
  });
  Address copyWith({
    String? id,
    String? fullName,
    String? phone,
    String? line1,
    String? line2,
    String? city,
    String? state,
    String? pincode,
    String? landmark,
    String? type,
    bool? isDefault,
    double? latitude,
    double? longitude,
    DateTime? createdAt,
  }) {
    return Address(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phone: phone ?? this.phone,
      line1: line1 ?? this.line1,
      line2: line2 ?? this.line2,
      city: city ?? this.city,
      state: state ?? this.state,
      pincode: pincode ?? this.pincode,
      landmark: landmark ?? this.landmark,
      type: type ?? this.type,
      isDefault: isDefault ?? this.isDefault,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      createdAt: createdAt ?? this.createdAt,
    );
  }
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'fullName': fullName,
      'phone': phone,
      'line1': line1,
      'line2': line2,
      'city': city,
      'state': state,
      'pincode': pincode,
      'landmark': landmark,
      'type': type,
      'isDefault': isDefault,
      'latitude': latitude,
      'longitude': longitude,
      'createdAt': createdAt.toIso8601String(),
    };
  }
  factory Address.fromMap(Map<String, dynamic> map) {
    return Address(
      id: map['id'] as String,
      fullName: map['fullName'] as String,
      phone: map['phone'] as String,
      line1: map['line1'] as String,
      line2: map['line2'] as String,
      city: map['city'] as String,
      state: map['state'] as String,
      pincode: map['pincode'] as String,
      landmark: map['landmark'] as String,
      type: map['type'] as String,
      isDefault: map['isDefault'] as bool? ?? false,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      createdAt: DateTime.parse(map['createdAt'] as String),
    );
  }
  String toJson() => json.encode(toMap());
  factory Address.fromJson(String source) => Address.fromMap(json.decode(source) as Map<String, dynamic>);
}
