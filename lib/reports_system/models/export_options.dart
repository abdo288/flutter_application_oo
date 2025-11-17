/// نموذج خيارات التصدير
class ExportOptions {
  const ExportOptions({
    required this.format,
    required this.fileName,
    this.includeCharts = true,
    this.includeData = true,
    this.includeSummary = true,
    this.dateRange,
    this.filters,
    this.template,
    this.quality = ExportQuality.high,
    this.orientation = PageOrientation.portrait,
    this.pageSize = PageSize.a4,
    this.margins = const PageMargins.all(20.0),
    this.header,
    this.footer,
    this.watermark,
    this.password,
    this.compression = false,
  });

  factory ExportOptions.fromMap(Map<String, dynamic> map) => ExportOptions(
      format: ExportFormat.values.firstWhere(
        (ExportFormat e) => e.name == map['format'],
        orElse: () => ExportFormat.pdf,
      ),
      fileName: (map['fileName'] as String?) ?? '',
      includeCharts: (map['includeCharts'] as bool?) ?? true,
      includeData: (map['includeData'] as bool?) ?? true,
      includeSummary: (map['includeSummary'] as bool?) ?? true,
      dateRange: map['dateRange'] != null
          ? DateRange.fromMap(map['dateRange'] as Map<String, dynamic>)
          : null,
      filters: map['filters'] != null
          ? ReportFilter.fromMap(map['filters'] as Map<String, dynamic>)
          : null,
      template: map['template'] != null
          ? ExportTemplate.fromMap(map['template'] as Map<String, dynamic>)
          : null,
      quality: ExportQuality.values.firstWhere(
        (ExportQuality e) => e.name == map['quality'],
        orElse: () => ExportQuality.high,
      ),
      orientation: PageOrientation.values.firstWhere(
        (PageOrientation e) => e.name == map['orientation'],
        orElse: () => PageOrientation.portrait,
      ),
      pageSize: PageSize.values.firstWhere(
        (PageSize e) => e.name == map['pageSize'],
        orElse: () => PageSize.a4,
      ),
      margins: PageMargins.fromMap(map['margins'] as Map<String, dynamic>),
      header: map['header'] != null
          ? ExportHeader.fromMap(map['header'] as Map<String, dynamic>)
          : null,
      footer: map['footer'] != null
          ? ExportFooter.fromMap(map['footer'] as Map<String, dynamic>)
          : null,
      watermark: map['watermark'] != null
          ? ExportWatermark.fromMap(map['watermark'] as Map<String, dynamic>)
          : null,
      password: map['password'] as String?,
      compression: (map['compression'] as bool?) ?? false,
    );

  final ExportFormat format;
  final String fileName;
  final bool includeCharts;
  final bool includeData;
  final bool includeSummary;
  final DateRange? dateRange;
  final ReportFilter? filters;
  final ExportTemplate? template;
  final ExportQuality quality;
  final PageOrientation orientation;
  final PageSize pageSize;
  final PageMargins margins;
  final ExportHeader? header;
  final ExportFooter? footer;
  final ExportWatermark? watermark;
  final String? password;
  final bool compression;

  /// التحقق من صحة الخيارات
  bool get isValid => fileName.isNotEmpty && format != ExportFormat.unknown;

  /// إنشاء نسخة من الخيارات مع تحديث القيم المحددة
  ExportOptions copyWith({
    ExportFormat? format,
    String? fileName,
    bool? includeCharts,
    bool? includeData,
    bool? includeSummary,
    DateRange? dateRange,
    ReportFilter? filters,
    ExportTemplate? template,
    ExportQuality? quality,
    PageOrientation? orientation,
    PageSize? pageSize,
    PageMargins? margins,
    ExportHeader? header,
    ExportFooter? footer,
    ExportWatermark? watermark,
    String? password,
    bool? compression,
  }) => ExportOptions(
      format: format ?? this.format,
      fileName: fileName ?? this.fileName,
      includeCharts: includeCharts ?? this.includeCharts,
      includeData: includeData ?? this.includeData,
      includeSummary: includeSummary ?? this.includeSummary,
      dateRange: dateRange ?? this.dateRange,
      filters: filters ?? this.filters,
      template: template ?? this.template,
      quality: quality ?? this.quality,
      orientation: orientation ?? this.orientation,
      pageSize: pageSize ?? this.pageSize,
      margins: margins ?? this.margins,
      header: header ?? this.header,
      footer: footer ?? this.footer,
      watermark: watermark ?? this.watermark,
      password: password ?? this.password,
      compression: compression ?? this.compression,
    );

  Map<String, dynamic> toMap() => <String, dynamic>{
      'format': format.name,
      'fileName': fileName,
      'includeCharts': includeCharts,
      'includeData': includeData,
      'includeSummary': includeSummary,
      'dateRange': dateRange?.toMap(),
      'filters': filters?.toMap(),
      'template': template?.toMap(),
      'quality': quality.name,
      'orientation': orientation.name,
      'pageSize': pageSize.name,
      'margins': margins.toMap(),
      'header': header?.toMap(),
      'footer': footer?.toMap(),
      'watermark': watermark?.toMap(),
      'password': password,
      'compression': compression,
    };
}

/// تنسيق التصدير
enum ExportFormat {
  pdf,
  excel,
  csv,
  json,
  xml,
  html,
  unknown,
}

/// جودة التصدير
enum ExportQuality {
  low,
  medium,
  high,
  ultra,
}

/// اتجاه الصفحة
enum PageOrientation {
  portrait,
  landscape,
}

/// حجم الصفحة
enum PageSize {
  a4,
  a3,
  letter,
  legal,
  tabloid,
}

/// هوامش الصفحة
class PageMargins {
  const PageMargins({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  factory PageMargins.fromMap(Map<String, dynamic> map) => PageMargins(
      left: (map['left'] as num?)?.toDouble() ?? 0.0,
      top: (map['top'] as num?)?.toDouble() ?? 0.0,
      right: (map['right'] as num?)?.toDouble() ?? 0.0,
      bottom: (map['bottom'] as num?)?.toDouble() ?? 0.0,
    );

  const PageMargins.all(double value)
      : left = value,
        top = value,
        right = value,
        bottom = value;

  const PageMargins.symmetric({
    required double horizontal,
    required double vertical,
  })  : left = horizontal,
        top = vertical,
        right = horizontal,
        bottom = vertical;

  final double left;
  final double top;
  final double right;
  final double bottom;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'left': left,
      'top': top,
      'right': right,
      'bottom': bottom,
    };
}

/// قالب التصدير
class ExportTemplate {
  const ExportTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.templateData,
    this.isDefault = false,
    this.createdAt,
    this.updatedAt,
  });

  factory ExportTemplate.fromMap(Map<String, dynamic> map) => ExportTemplate(
      id: (map['id'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      description: (map['description'] as String?) ?? '',
      templateData: (map['templateData'] as Map<String, dynamic>?) ?? <String, dynamic>{},
      isDefault: (map['isDefault'] as bool?) ?? false,
      createdAt: map['createdAt'] != null
          ? DateTime.parse(map['createdAt'] as String)
          : null,
      updatedAt: map['updatedAt'] != null
          ? DateTime.parse(map['updatedAt'] as String)
          : null,
    );

  final String id;
  final String name;
  final String description;
  final Map<String, dynamic> templateData;
  final bool isDefault;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'id': id,
      'name': name,
      'description': description,
      'templateData': templateData,
      'isDefault': isDefault,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
}

/// رأس التصدير
class ExportHeader {
  const ExportHeader({
    this.title,
    this.subtitle,
    this.logo,
    this.companyName,
    this.companyAddress,
    this.phone,
    this.email,
    this.website,
    this.showDate = true,
    this.showPageNumber = true,
  });

  factory ExportHeader.fromMap(Map<String, dynamic> map) => ExportHeader(
      title: map['title'] as String?,
      subtitle: map['subtitle'] as String?,
      logo: map['logo'] as String?,
      companyName: map['companyName'] as String?,
      companyAddress: map['companyAddress'] as String?,
      phone: map['phone'] as String?,
      email: map['email'] as String?,
      website: map['website'] as String?,
      showDate: (map['showDate'] as bool?) ?? true,
      showPageNumber: (map['showPageNumber'] as bool?) ?? true,
    );

  final String? title;
  final String? subtitle;
  final String? logo;
  final String? companyName;
  final String? companyAddress;
  final String? phone;
  final String? email;
  final String? website;
  final bool showDate;
  final bool showPageNumber;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'title': title,
      'subtitle': subtitle,
      'logo': logo,
      'companyName': companyName,
      'companyAddress': companyAddress,
      'phone': phone,
      'email': email,
      'website': website,
      'showDate': showDate,
      'showPageNumber': showPageNumber,
    };
}

/// تذييل التصدير
class ExportFooter {
  const ExportFooter({
    this.text,
    this.showDate = true,
    this.showPageNumber = true,
    this.showTotalPages = true,
  });

  factory ExportFooter.fromMap(Map<String, dynamic> map) => ExportFooter(
      text: map['text'] as String?,
      showDate: (map['showDate'] as bool?) ?? true,
      showPageNumber: (map['showPageNumber'] as bool?) ?? true,
      showTotalPages: (map['showTotalPages'] as bool?) ?? true,
    );

  final String? text;
  final bool showDate;
  final bool showPageNumber;
  final bool showTotalPages;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'text': text,
      'showDate': showDate,
      'showPageNumber': showPageNumber,
      'showTotalPages': showTotalPages,
    };
}

/// علامة مائية
class ExportWatermark {
  const ExportWatermark({
    required this.text,
    this.opacity = 0.3,
    this.angle = 45.0,
    this.fontSize = 48.0,
    this.color = '#CCCCCC',
  });

  factory ExportWatermark.fromMap(Map<String, dynamic> map) => ExportWatermark(
      text: (map['text'] as String?) ?? '',
      opacity: (map['opacity'] as num?)?.toDouble() ?? 0.3,
      angle: (map['angle'] as num?)?.toDouble() ?? 45.0,
      fontSize: (map['fontSize'] as num?)?.toDouble() ?? 48.0,
      color: (map['color'] as String?) ?? '#CCCCCC',
    );

  final String text;
  final double opacity;
  final double angle;
  final double fontSize;
  final String color;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'text': text,
      'opacity': opacity,
      'angle': angle,
      'fontSize': fontSize,
      'color': color,
    };
}

/// نطاق التاريخ
class DateRange {
  const DateRange({
    required this.startDate,
    required this.endDate,
  });

  factory DateRange.fromMap(Map<String, dynamic> map) => DateRange(
      startDate: DateTime.parse(map['startDate'] as String),
      endDate: DateTime.parse(map['endDate'] as String),
    );

  final DateTime startDate;
  final DateTime endDate;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'startDate': startDate.toIso8601String(),
      'endDate': endDate.toIso8601String(),
    };
}

/// فلتر التقارير
class ReportFilter {
  const ReportFilter({
    this.dateRange,
    this.paymentMethods,
    this.employees,
    this.priceRange,
    this.categories,
    this.suppliers,
    this.syncStatus,
    this.searchQuery,
    this.sortBy,
    this.sortOrder,
    this.limit,
    this.offset,
  });

  factory ReportFilter.fromMap(Map<String, dynamic> map) => ReportFilter(
      dateRange: map['dateRange'] != null
          ? DateRange.fromMap(map['dateRange'] as Map<String, dynamic>)
          : null,
      paymentMethods: (map['paymentMethods'] as List<dynamic>?)?.cast<String>(),
      employees: (map['employees'] as List<dynamic>?)?.cast<String>(),
      priceRange: map['priceRange'] != null
          ? PriceRange.fromMap(map['priceRange'] as Map<String, dynamic>)
          : null,
      categories: (map['categories'] as List<dynamic>?)?.cast<String>(),
      suppliers: (map['suppliers'] as List<dynamic>?)?.cast<String>(),
      syncStatus: map['syncStatus'] as String?,
      searchQuery: map['searchQuery'] as String?,
      sortBy: map['sortBy'] as String?,
      sortOrder: map['sortOrder'] as String?,
      limit: map['limit'] as int?,
      offset: map['offset'] as int?,
    );

  final DateRange? dateRange;
  final List<String>? paymentMethods;
  final List<String>? employees;
  final PriceRange? priceRange;
  final List<String>? categories;
  final List<String>? suppliers;
  final String? syncStatus;
  final String? searchQuery;
  final String? sortBy;
  final String? sortOrder;
  final int? limit;
  final int? offset;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'dateRange': dateRange?.toMap(),
      'paymentMethods': paymentMethods,
      'employees': employees,
      'priceRange': priceRange?.toMap(),
      'categories': categories,
      'suppliers': suppliers,
      'syncStatus': syncStatus,
      'searchQuery': searchQuery,
      'sortBy': sortBy,
      'sortOrder': sortOrder,
      'limit': limit,
      'offset': offset,
    };
}

/// نطاق السعر
class PriceRange {
  const PriceRange({
    required this.minPrice,
    required this.maxPrice,
  });

  factory PriceRange.fromMap(Map<String, dynamic> map) => PriceRange(
      minPrice: (map['minPrice'] as num?)?.toDouble() ?? 0.0,
      maxPrice: (map['maxPrice'] as num?)?.toDouble() ?? 0.0,
    );

  final double minPrice;
  final double maxPrice;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'minPrice': minPrice,
      'maxPrice': maxPrice,
    };
}

/// قوالب التصدير المسبقة
class ExportTemplates {
  static const ExportTemplate salesReport = ExportTemplate(
    id: 'sales_report',
    name: 'تقرير المبيعات',
    description: 'قالب تقرير المبيعات الأساسي',
    templateData: <String, dynamic>{
      'includeCharts': true,
      'includeSummary': true,
      'orientation': 'portrait',
      'pageSize': 'a4',
    },
    isDefault: true,
  );

  static const ExportTemplate inventoryReport = ExportTemplate(
    id: 'inventory_report',
    name: 'تقرير المخزون',
    description: 'قالب تقرير المخزون الأساسي',
    templateData: <String, dynamic>{
      'includeCharts': true,
      'includeSummary': true,
      'orientation': 'landscape',
      'pageSize': 'a4',
    },
  );

  static const ExportTemplate eodReport = ExportTemplate(
    id: 'eod_report',
    name: 'تقرير نهاية اليوم',
    description: 'قالب تقرير نهاية اليوم',
    templateData: <String, dynamic>{
      'includeCharts': true,
      'includeSummary': true,
      'orientation': 'portrait',
      'pageSize': 'a4',
    },
  );

  static const List<ExportTemplate> allTemplates = <ExportTemplate>[
    salesReport,
    inventoryReport,
    eodReport,
  ];
}
