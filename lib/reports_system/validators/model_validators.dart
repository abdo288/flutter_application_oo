/// نتيجة التحقق من صحة البيانات
class ValidationResult {
  const ValidationResult.success({List<String>? warnings})
      : isValid = true,
        error = null,
        warnings = warnings ?? const <String>[];

  const ValidationResult.error(this.error, {List<String>? warnings})
      : isValid = false,
        warnings = warnings ?? const <String>[];
  final bool isValid;
  final String? error;
  final List<String> warnings;

  /// Getter للوصول إلى errorMessage
  String? get errorMessage => error;

  /// دمج نتائج التحقق
  ValidationResult combine(ValidationResult other) {
    if (!isValid || !other.isValid) {
      return ValidationResult.error(
        error ?? other.error,
        warnings: <String>[...warnings, ...other.warnings],
      );
    }
    return ValidationResult.success(
      warnings: <String>[...warnings, ...other.warnings],
    );
  }
}

/// محقق إعدادات الإشعارات
class NotificationValidator {
  static ValidationResult validate(config) {
    final List<String> errors = <String>[];
    final List<String> warnings = <String>[];

    // التحقق من الاسم
    final String name = config.name?.toString() ?? '';
    if (name.isEmpty) {
      errors.add('اسم الإشعار مطلوب');
    } else if (name.length < 3) {
      warnings.add('اسم الإشعار قصير جداً');
    }

    // التحقق من النوع
    if (config.type == null) {
      errors.add('نوع الإشعار مطلوب');
    }

    // التحقق من الشروط
    final List<dynamic> conditions =
        config.conditions as List<dynamic>? ?? <dynamic>[];
    if (conditions.isEmpty) {
      errors.add('يجب تحديد شرط واحد على الأقل');
    } else {
      for (int i = 0; i < conditions.length; i++) {
        final condition = conditions[i];
        final String field = condition?.field?.toString() ?? '';
        if (field.isEmpty) {
          errors.add('حقل الشرط ${i + 1} مطلوب');
        }
        if (condition?.operator == null) {
          errors.add('مشغل الشرط ${i + 1} مطلوب');
        }
      }
    }

    // التحقق من الإجراءات
    final List<dynamic> actions =
        config.actions as List<dynamic>? ?? <dynamic>[];
    if (actions.isEmpty) {
      errors.add('يجب تحديد إجراء واحد على الأقل');
    }

    if (errors.isNotEmpty) {
      return ValidationResult.error(errors.join('; '), warnings: warnings);
    }

    return ValidationResult.success(warnings: warnings);
  }
}

/// محقق خيارات التصدير
class ExportOptionsValidator {
  static ValidationResult validate(options) {
    final List<String> errors = <String>[];
    final List<String> warnings = <String>[];

    // التحقق من اسم الملف
    final String fileName = options.fileName?.toString() ?? '';
    if (fileName.isEmpty) {
      errors.add('اسم الملف مطلوب');
    } else {
      if (fileName.length < 3) {
        warnings.add('اسم الملف قصير جداً');
      }
      if (!fileName.contains('.')) {
        warnings.add('اسم الملف لا يحتوي على امتداد');
      }
    }

    // التحقق من التنسيق
    if (options.format == null) {
      errors.add('تنسيق التصدير مطلوب');
    }

    // التحقق من جودة التصدير
    final String quality = options.quality?.toString() ?? '';
    if (quality == 'ultra') {
      warnings.add('الجودة الفائقة قد تستهلك ذاكرة أكثر');
    }

    // التحقق من حجم الصفحة
    final String pageSize = options.pageSize?.toString() ?? '';
    if (pageSize == 'a3' || pageSize == 'tabloid') {
      warnings.add('حجم الصفحة الكبير قد يؤثر على الأداء');
    }

    // التحقق من كلمة المرور
    final String password = options.password?.toString() ?? '';
    if (password.isNotEmpty && password.length < 6) {
      warnings.add('كلمة المرور قصيرة جداً');
    }

    if (errors.isNotEmpty) {
      return ValidationResult.error(errors.join('; '), warnings: warnings);
    }

    return ValidationResult.success(warnings: warnings);
  }
}

/// محقق تقرير المدفوعات
class PaymentReportValidator {
  static ValidationResult validate(report) {
    final List<String> errors = <String>[];
    final List<String> warnings = <String>[];

    // التحقق من المبلغ الإجمالي
    final double totalAmount = (report.totalAmount as num?)?.toDouble() ?? 0.0;
    if (totalAmount < 0) {
      errors.add('المبلغ الإجمالي لا يمكن أن يكون سالباً');
    }

    // التحقق من عدد المعاملات
    final int totalTransactions =
        (report.totalTransactions as num?)?.toInt() ?? 0;
    if (totalTransactions < 0) {
      errors.add('عدد المعاملات لا يمكن أن يكون سالباً');
    }

    // التحقق من طرق الدفع
    final List<dynamic> paymentMethods =
        report.paymentMethods as List<dynamic>? ?? <dynamic>[];
    if (paymentMethods.isEmpty) {
      warnings.add('لا توجد طرق دفع محددة');
    } else {
      double totalPercentage = 0;
      for (int i = 0; i < paymentMethods.length; i++) {
        final method = paymentMethods[i];
        final double percentage =
            (method?.percentage as num?)?.toDouble() ?? 0.0;
        totalPercentage += percentage;
        final double amount = (method?.amount as num?)?.toDouble() ?? 0.0;
        if (amount < 0) {
          errors.add('مبلغ طريقة الدفع ${i + 1} لا يمكن أن يكون سالباً');
        }
      }
      if (totalPercentage > 100) {
        warnings.add('مجموع النسب المئوية لطرق الدفع يتجاوز 100%');
      }
    }

    // التحقق من المبالغ المستردة
    final List<dynamic> refunds =
        report.refunds as List<dynamic>? ?? <dynamic>[];
    for (int i = 0; i < refunds.length; i++) {
      final refund = refunds[i];
      final double amount = (refund?.amount as num?)?.toDouble() ?? 0.0;
      if (amount < 0) {
        errors.add('مبلغ الاسترداد ${i + 1} لا يمكن أن يكون سالباً');
      }
      final String reason = refund?.reason?.toString() ?? '';
      if (reason.isEmpty) {
        warnings.add('سبب الاسترداد ${i + 1} غير محدد');
      }
    }

    // التحقق من الديون
    final List<dynamic> debts = report.debts as List<dynamic>? ?? <dynamic>[];
    for (int i = 0; i < debts.length; i++) {
      final debt = debts[i];
      final double amount = (debt?.amount as num?)?.toDouble() ?? 0.0;
      if (amount < 0) {
        errors.add('مبلغ الدين ${i + 1} لا يمكن أن يكون سالباً');
      }
      final double originalAmount =
          (debt?.originalAmount as num?)?.toDouble() ?? 0.0;
      if (originalAmount < amount) {
        errors.add('المبلغ الأصلي للدين ${i + 1} أقل من المبلغ المتبقي');
      }
    }

    if (errors.isNotEmpty) {
      return ValidationResult.error(errors.join('; '), warnings: warnings);
    }

    return ValidationResult.success(warnings: warnings);
  }
}

/// محقق فلتر التقارير
class ReportFilterValidator {
  static ValidationResult validate(filter) {
    final List<String> errors = <String>[];
    final List<String> warnings = <String>[];

    // التحقق من نطاق التاريخ
    final dateRange = filter.dateRange;
    if (dateRange != null) {
      if (dateRange.startDate == null) {
        errors.add('تاريخ البداية مطلوب');
      }
      if (dateRange.endDate == null) {
        errors.add('تاريخ النهاية مطلوب');
      }
      if (dateRange.startDate != null &&
          dateRange.endDate != null &&
          (dateRange.endDate as DateTime)
              .isBefore(dateRange.startDate as DateTime)) {
        errors.add('تاريخ النهاية يجب أن يكون بعد تاريخ البداية');
      }
    }

    // التحقق من نطاق السعر
    final priceRange = filter.priceRange;
    if (priceRange != null) {
      final double minPrice = (priceRange.minPrice as num?)?.toDouble() ?? 0.0;
      final double maxPrice = (priceRange.maxPrice as num?)?.toDouble() ?? 0.0;
      if (minPrice < 0) {
        errors.add('الحد الأدنى للسعر لا يمكن أن يكون سالباً');
      }
      if (maxPrice < minPrice) {
        errors
            .add('الحد الأقصى للسعر يجب أن يكون أكبر من أو يساوي الحد الأدنى');
      }
    }

    // التحقق من الحد الأقصى للنتائج
    final int limit = (filter.limit as num?)?.toInt() ?? 0;
    if (limit > 1000) {
      warnings.add('الحد الأقصى للنتائج كبير جداً وقد يؤثر على الأداء');
    }

    // التحقق من استعلام البحث
    final String searchQuery = filter.searchQuery?.toString() ?? '';
    if (searchQuery.isNotEmpty && searchQuery.length < 2) {
      warnings.add('استعلام البحث قصير جداً');
    }

    if (errors.isNotEmpty) {
      return ValidationResult.error(errors.join('; '), warnings: warnings);
    }

    return ValidationResult.success(warnings: warnings);
  }
}

/// محقق عام للبيانات
class DataValidator {
  /// التحقق من صحة البيانات
  static ValidationResult validateData(data, String dataType) {
    switch (dataType.toLowerCase()) {
      case 'notification':
        return NotificationValidator.validate(data);
      case 'export':
        return ExportOptionsValidator.validate(data);
      case 'payment':
        return PaymentReportValidator.validate(data);
      case 'filter':
        return ReportFilterValidator.validate(data);
      default:
        return const ValidationResult.error('نوع البيانات غير مدعوم');
    }
  }

  /// التحقق من صحة البيانات المطلوبة
  static ValidationResult validateRequiredFields(
    Map<String, dynamic> data,
    List<String> requiredFields,
  ) {
    final List<String> errors = <String>[];

    for (final String field in requiredFields) {
      if (!data.containsKey(field) || data[field] == null) {
        errors.add('الحقل "$field" مطلوب');
      }
    }

    if (errors.isNotEmpty) {
      return ValidationResult.error(errors.join('; '));
    }

    return const ValidationResult.success();
  }

  /// التحقق من صحة النطاق
  static ValidationResult validateRange(
    num value,
    num min,
    num max,
    String fieldName,
  ) {
    if (value < min) {
      return ValidationResult.error(
          '$fieldName يجب أن يكون أكبر من أو يساوي $min');
    }
    if (value > max) {
      return ValidationResult.error(
          '$fieldName يجب أن يكون أصغر من أو يساوي $max');
    }
    return const ValidationResult.success();
  }

  /// التحقق من صحة النص
  static ValidationResult validateText(
    String? text,
    String fieldName, {
    int? minLength,
    int? maxLength,
    bool required = true,
  }) {
    if (text == null || text.isEmpty) {
      if (required) {
        return ValidationResult.error('$fieldName مطلوب');
      }
      return const ValidationResult.success();
    }

    if (minLength != null && text.length < minLength) {
      return ValidationResult.error(
          '$fieldName يجب أن يكون $minLength أحرف على الأقل');
    }

    if (maxLength != null && text.length > maxLength) {
      return ValidationResult.error(
          '$fieldName يجب أن يكون $maxLength أحرف على الأكثر');
    }

    return const ValidationResult.success();
  }
}
