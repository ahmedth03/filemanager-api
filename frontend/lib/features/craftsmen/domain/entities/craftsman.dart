import 'package:freezed_annotation/freezed_annotation.dart';

import 'portfolio_item.dart';

part 'craftsman.freezed.dart';
part 'craftsman.g.dart';

enum CraftsmanSpecialty {
  plumber,
  electrician,
  carpenter,
  painter,
  mason,
  acTech,
  welder,
  cleaner,
  other;

  String get labelAr {
    switch (this) {
      case CraftsmanSpecialty.plumber:
        return 'سباك';
      case CraftsmanSpecialty.electrician:
        return 'كهربائي';
      case CraftsmanSpecialty.carpenter:
        return 'نجار';
      case CraftsmanSpecialty.painter:
        return 'دهان';
      case CraftsmanSpecialty.mason:
        return 'بناء';
      case CraftsmanSpecialty.acTech:
        return 'تقني تكييف';
      case CraftsmanSpecialty.welder:
        return 'حداد';
      case CraftsmanSpecialty.cleaner:
        return 'عامل نظافة';
      case CraftsmanSpecialty.other:
        return 'أخرى';
    }
  }

  String get key {
    switch (this) {
      case CraftsmanSpecialty.plumber:
        return 'plumber';
      case CraftsmanSpecialty.electrician:
        return 'electrician';
      case CraftsmanSpecialty.carpenter:
        return 'carpenter';
      case CraftsmanSpecialty.painter:
        return 'painter';
      case CraftsmanSpecialty.mason:
        return 'mason';
      case CraftsmanSpecialty.acTech:
        return 'acTech';
      case CraftsmanSpecialty.welder:
        return 'welder';
      case CraftsmanSpecialty.cleaner:
        return 'cleaner';
      case CraftsmanSpecialty.other:
        return 'other';
    }
  }

  static CraftsmanSpecialty fromKey(String key) {
    return CraftsmanSpecialty.values.firstWhere(
      (e) => e.key == key,
      orElse: () => CraftsmanSpecialty.other,
    );
  }
}

@freezed
class Craftsman with _$Craftsman {
  const factory Craftsman({
    required String id,
    required String userId,
    required String name,
    required String phone,
    String? avatar,
    required CraftsmanSpecialty specialty,
    required String bio,
    required String wilaya,
    required String city,
    required double rating,
    required int reviewCount,
    required bool isAvailable,
    required bool isVerified,
    double? hourlyRate,
    required int experience,
    required List<PortfolioItem> portfolio,
    required DateTime createdAt,
  }) = _Craftsman;

  factory Craftsman.fromJson(Map<String, dynamic> json) =>
      _$CraftsmanFromJson(json);
}
