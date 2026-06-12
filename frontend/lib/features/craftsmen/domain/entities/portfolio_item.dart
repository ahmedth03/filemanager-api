import 'package:freezed_annotation/freezed_annotation.dart';

part 'portfolio_item.freezed.dart';
part 'portfolio_item.g.dart';

@freezed
class PortfolioItem with _$PortfolioItem {
  const factory PortfolioItem({
    required String id,
    required String imageUrl,
    required String title,
    required String craftsmanId,
    String? description,
    required DateTime createdAt,
  }) = _PortfolioItem;

  factory PortfolioItem.fromJson(Map<String, dynamic> json) =>
      _$PortfolioItemFromJson(json);
}
