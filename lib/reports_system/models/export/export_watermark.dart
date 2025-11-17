import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'export_watermark.freezed.dart';
part 'export_watermark.g.dart';

/// علامة مائية
@freezed
class ExportWatermark with _$ExportWatermark {
  const factory ExportWatermark({
    required String text,
    @Default(0.3) double opacity,
    @Default(45.0) double angle,
    @Default(48.0) double fontSize,
    @Default('#CCCCCC') String color,
  }) = _ExportWatermark;

  factory ExportWatermark.fromJson(Map<String, dynamic> json) =>
      _$ExportWatermarkFromJson(json);
}
