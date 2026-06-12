import 'package:freezed_annotation/freezed_annotation.dart';

part 'user.freezed.dart';
part 'user.g.dart';

// ---------------------------------------------------------------------------
// UserType enum
// ---------------------------------------------------------------------------
enum UserType {
  @JsonValue('client')
  client,
  @JsonValue('craftsman')
  craftsman,
  @JsonValue('owner')
  owner,
}

extension UserTypeExtension on UserType {
  String get displayName {
    switch (this) {
      case UserType.client:
        return 'Client';
      case UserType.craftsman:
        return 'Craftsman';
      case UserType.owner:
        return 'Property Owner';
    }
  }

  String get displayNameAr {
    switch (this) {
      case UserType.client:
        return 'عميل';
      case UserType.craftsman:
        return 'حرفي';
      case UserType.owner:
        return 'مالك عقار';
    }
  }
}

// ---------------------------------------------------------------------------
// User entity
// ---------------------------------------------------------------------------
@freezed
class User with _$User {
  const User._();

  const factory User({
    required String id,
    required String name,
    required String phone,
    String? email,
    String? avatar,
    @Default(UserType.client) UserType userType,
    String? wilaya,
    @Default(false) bool isVerified,
    @Default(false) bool isPhoneVerified,
    String? bio,
    double? rating,
    @Default(0) int reviewCount,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _User;

  factory User.fromJson(Map<String, dynamic> json) => _$UserFromJson(json);

  // ------------------------------------------------------------------ helpers

  bool get isClient => userType == UserType.client;
  bool get isCraftsman => userType == UserType.craftsman;
  bool get isOwner => userType == UserType.owner;

  String get initials {
    final parts = name.trim().split(' ');
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return '${parts[0][0]}${parts[parts.length - 1][0]}'.toUpperCase();
  }

  String get formattedPhone {
    // Format: 0X XX XX XX XX
    final digits = phone.replaceAll(RegExp(r'\D'), '');
    if (digits.length >= 10) {
      return '${digits.substring(0, 2)} ${digits.substring(2, 4)} ${digits.substring(4, 6)} ${digits.substring(6, 8)} ${digits.substring(8, 10)}';
    }
    return phone;
  }
}
