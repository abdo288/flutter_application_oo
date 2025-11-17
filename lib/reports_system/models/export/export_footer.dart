import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'export_footer.freezed.dart';
part 'export_footer.g.dart';

/// تذييل التصدير
@freezed
class ExportFooter with _$ExportFooter {
  const factory ExportFooter({
    String? text,
    @Default(true) bool showDate,
    @Default(true) bool showPageNumber,
    @Default(true) bool showTotalPages,
  }) = _ExportFooter;

  factory ExportFooter.fromJson(Map<String, dynamic> json) =>
      _$ExportFooterFromJson(json);
}
