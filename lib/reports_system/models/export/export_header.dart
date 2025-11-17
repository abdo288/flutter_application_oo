import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'export_header.freezed.dart';
part 'export_header.g.dart';

/// رأس التصدير
@freezed
class ExportHeader with _$ExportHeader {
  const factory ExportHeader({
    String? title,
    String? subtitle,
    String? logo,
    String? companyName,
    String? companyAddress,
    String? phone,
    String? email,
    String? website,
    @Default(true) bool showDate,
    @Default(true) bool showPageNumber,
  }) = _ExportHeader;

  factory ExportHeader.fromJson(Map<String, dynamic> json) =>
      _$ExportHeaderFromJson(json);
}
