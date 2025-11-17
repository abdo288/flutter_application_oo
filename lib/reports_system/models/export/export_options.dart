import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../common/date_range.dart';
import '../common/page_margins.dart';
import '../enums/export_enums.dart';
import '../report_filter.dart';
import 'export_footer.dart';
import 'export_header.dart';
import 'export_template.dart';
import 'export_watermark.dart';

part 'export_options.freezed.dart';
part 'export_options.g.dart';

/// نموذج خيارات التصدير
@freezed
class ExportOptions with _$ExportOptions {
  const factory ExportOptions({
    required ExportFormat format,
    required String fileName,
    @Default(true) bool includeCharts,
    @Default(true) bool includeData,
    @Default(true) bool includeSummary,
    DateRange? dateRange,
    ReportFilter? filters,
    ExportTemplate? template,
    @Default(ExportQuality.high) ExportQuality quality,
    @Default(PageOrientation.portrait) PageOrientation orientation,
    @Default(PageSize.a4) PageSize pageSize,
    @Default(PageMargins.all(20.0)) PageMargins margins,
    ExportHeader? header,
    ExportFooter? footer,
    ExportWatermark? watermark,
    String? password,
    @Default(false) bool compression,
  }) = _ExportOptions;

  factory ExportOptions.fromJson(Map<String, dynamic> json) =>
      _$ExportOptionsFromJson(json);
}

/// Extensions for computed properties
extension ExportOptionsX on ExportOptions {
  /// التحقق من صحة الخيارات
  bool get isValid => fileName.isNotEmpty && format != ExportFormat.unknown;
}
