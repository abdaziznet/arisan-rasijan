class MemberModel {
  const MemberModel({
    required this.id,
    required this.fullName,
    this.phoneNumber,
    this.address,
    this.photoUrl,
    this.role = 'member',
    this.isActive = true,
    this.hasWonBefore = false,
    this.createdAt,
  });

  factory MemberModel.fromJson(Map<String, dynamic> json) => MemberModel(
        id: json['id'] as String,
        fullName: json['full_name'] as String? ?? '',
        phoneNumber: json['phone_number'] as String?,
        address: json['address'] as String?,
        photoUrl: json['photo_url'] as String?,
        role: json['role'] as String? ?? 'member',
        isActive: json['is_active'] as bool? ?? true,
        hasWonBefore: json['has_won_before'] as bool? ?? false,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : null,
      );

  final String id;
  final String fullName;
  final String? phoneNumber;
  final String? address;
  final String? photoUrl;
  final String role;
  final bool isActive;
  final bool hasWonBefore;
  final DateTime? createdAt;

  bool get isAdmin => role == 'admin';

  Map<String, dynamic> toJson() => {
        'id': id,
        'full_name': fullName,
        'phone_number': phoneNumber,
        'address': address,
        'photo_url': photoUrl,
        'role': role,
        'is_active': isActive,
        'has_won_before': hasWonBefore,
        if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
      };

  MemberModel copyWith({
    String? id,
    String? fullName,
    String? phoneNumber,
    String? address,
    String? photoUrl,
    String? role,
    bool? isActive,
    bool? hasWonBefore,
    DateTime? createdAt,
  }) =>
      MemberModel(
        id: id ?? this.id,
        fullName: fullName ?? this.fullName,
        phoneNumber: phoneNumber ?? this.phoneNumber,
        address: address ?? this.address,
        photoUrl: photoUrl ?? this.photoUrl,
        role: role ?? this.role,
        isActive: isActive ?? this.isActive,
        hasWonBefore: hasWonBefore ?? this.hasWonBefore,
        createdAt: createdAt ?? this.createdAt,
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
          photoUrl == other.photoUrl &&
          role == other.role &&
          isActive == other.isActive &&
          hasWonBefore == other.hasWonBefore;

  @override
  int get hashCode =>
      id.hashCode ^
      fullName.hashCode ^
      phoneNumber.hashCode ^
      address.hashCode ^
      photoUrl.hashCode ^
      role.hashCode ^
      isActive.hashCode ^
      hasWonBefore.hashCode;
}
