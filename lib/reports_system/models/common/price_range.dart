import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'price_range.freezed.dart';
part 'price_range.g.dart';

/// نطاق السعر
@freezed
class PriceRange with _$PriceRange {
  const factory PriceRange({
    required double minPrice,
    required double maxPrice,
  }) = _PriceRange;

  factory PriceRange.fromJson(Map<String, dynamic> json) =>
      _$PriceRangeFromJson(json);
}

/// Extensions for computed properties
extension PriceRangeX on PriceRange {
  /// التحقق من صحة النطاق
  bool get isValid => maxPrice >= minPrice && minPrice >= 0;

  /// التحقق من وجود سعر في النطاق
  bool contains(double price) => price >= minPrice && price <= maxPrice;
}
