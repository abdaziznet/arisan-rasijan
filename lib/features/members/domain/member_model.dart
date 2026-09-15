class MemberModel {
  const MemberModel({
    required this.id,
    required this.fullName,
    this.phoneNumber,
    this.address,
    this.city,
    this.latitude,
    this.longitude,
    this.photoUrl,
    this.role = 'member',
    this.isActive = true,
    this.hasWonBefore = false,
    this.createdAt,
    this.updatedAt,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) => MemberModel(
        id: json['id'] as String,
        fullName: json['full_name'] as String? ?? '',
        phoneNumber: json['phone_number'] as String?,
        address: json['address'] as String?,
        city: json['city'] as String?,
        latitude: _parseDouble(json['latitude']),
        longitude: _parseDouble(json['longitude']),
        photoUrl: json['photo_url'] as String?,
        role: json['role'] as String? ?? 'member',
        isActive: json['is_active'] as bool? ?? true,
        hasWonBefore: json['has_won_before'] as bool? ?? false,
        createdAt: _parseDate(json['created_at']),
        updatedAt: _parseDate(json['updated_at']),
      );

  static double? _parseDouble(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  final String id;
  final String fullName;
  final String? phoneNumber;
  final String? address;
  final String? city;
  final double? latitude;
  final double? longitude;
  final String? photoUrl;
  final String role;
  final bool isActive;
  final bool hasWonBefore;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isAdmin => role == 'admin';

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'address': address,
        'city': city,
        'latitude': latitude,
        'longitude': longitude,
        'photo_url': photoUrl,
        'role': role,
        'is_active': isActive,
        'has_won_before': hasWonBefore,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
        if (updatedAt != null) 'updated_at': updatedAt!.toIso8601String(),
      };

  MemberModel copyWith({
    String? id,
    String? fullName,
    String? phoneNumber,
    String? address,
    String? city,
    double? latitude,
    double? longitude,
    String? photoUrl,
    String? role,
    bool? isActive,
    bool? hasWonBefore,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      MemberModel(
        id: id ?? this.id,
        fullName: fullName ?? this.fullName,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        address: address ?? this.address,
        city: city ?? this.city,
        latitude: latitude ?? this.latitude,
        longitude: longitude ?? this.longitude,
        photoUrl: photoUrl ?? this.photoUrl,
        role: role ?? this.role,
        isActive: isActive ?? this.isActive,
        hasWonBefore: hasWonBefore ?? this.hasWonBefore,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MemberModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fullName == other.fullName &&
          phoneNumber == other.phoneNumber &&
          address == other.address &&
          city == other.city &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          photoUrl == other.photoUrl &&
          role == other.role &&
          isActive == other.isActive &&
          hasWonBefore == other.hasWonBefore &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      fullName.hashCode ^
      phoneNumber.hashCode ^
      address.hashCode ^
      city.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      photoUrl.hashCode ^
      role.hashCode ^
      isActive.hashCode ^
      hasWonBefore.hashCode ^
      updatedAt.hashCode;
}
