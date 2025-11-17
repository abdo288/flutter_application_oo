import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'page_margins.freezed.dart';
part 'page_margins.g.dart';

/// هوامش الصفحة
@freezed
class PageMargins with _$PageMargins {
  const factory PageMargins({
    required double left,
    required double top,
    required double right,
    required double bottom,
  }) = _PageMargins;

  const factory PageMargins.all(double value) = _PageMarginsAll;

  const factory PageMargins.symmetric({
    required double horizontal,
    required double vertical,
  }) = _PageMarginsSymmetric;

  factory PageMargins.fromJson(Map<String, dynamic> json) =>
      _$PageMarginsFromJson(json);
}
