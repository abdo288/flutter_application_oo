import 'package:flutter/foundation.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'export_template.freezed.dart';
part 'export_template.g.dart';

/// قالب التصدير
@freezed
class ExportTemplate with _$ExportTemplate {
  const factory ExportTemplate({
    required String id,
    required String name,
    required String description,
    required Map<String, dynamic> templateData,
    @Default(false) bool isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _ExportTemplate;

  factory ExportTemplate.fromJson(Map<String, dynamic> json) =>
      _$ExportTemplateFromJson(json);
}
