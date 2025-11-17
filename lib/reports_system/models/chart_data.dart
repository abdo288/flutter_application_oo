import 'package:flutter/material.dart';

/// نموذج بيانات الرسم البياني
class ChartData {
  const ChartData({
    required this.title,
    required this.dataPoints,
    required this.chartType,
    required this.xAxisLabel,
    required this.yAxisLabel,
    required this.colors,
    this.animationDuration,
    this.showGrid,
    this.showLegend,
    this.showTooltips,
  });

  factory ChartData.fromMap(Map<String, dynamic> map) => ChartData(
      title: (map['title'] as String?) ?? '',
      dataPoints: List<DataPoint>.from(
        (map['dataPoints'] as List<dynamic>?)
                ?.map((x) => DataPoint.fromMap(x as Map<String, dynamic>)) ??
            <dynamic>[],
      ),
      chartType: ChartType.values.firstWhere(
        (ChartType e) => e.name == map['chartType'],
        orElse: () => ChartType.line,
      ),
      xAxisLabel: (map['xAxisLabel'] as String?) ?? '',
      yAxisLabel: (map['yAxisLabel'] as String?) ?? '',
      colors: List<ChartColor>.from(
        (map['colors'] as List<dynamic>?)
                ?.map((x) => ChartColor.fromMap(x as Map<String, dynamic>)) ??
            <dynamic>[],
      ),
      animationDuration: map['animationDuration'] != null
          ? Duration(milliseconds: map['animationDuration'] as int)
          : null,
      showGrid: map['showGrid'] as bool?,
      showLegend: map['showLegend'] as bool?,
      showTooltips: map['showTooltips'] as bool?,
    );

  final String title;
  final List<DataPoint> dataPoints;
  final ChartType chartType;
  final String xAxisLabel;
  final String yAxisLabel;
  final List<ChartColor> colors;
  final Duration? animationDuration;
  final bool? showGrid;
  final bool? showLegend;
  final bool? showTooltips;

  /// حساب القيمة القصوى
  double get maxValue {
    if (dataPoints.isEmpty) return 0.0;
    return dataPoints
        .map((DataPoint point) => point.value)
        .reduce((double a, double b) => a > b ? a : b);
  }

  /// حساب القيمة الدنيا
  double get minValue {
    if (dataPoints.isEmpty) return 0.0;
    return dataPoints
        .map((DataPoint point) => point.value)
        .reduce((double a, double b) => a < b ? a : b);
  }

  /// حساب إجمالي القيم
  double get totalValue => dataPoints.fold(0.0, (double sum, DataPoint point) => sum + point.value);

  /// حساب متوسط القيم
  double get averageValue {
    if (dataPoints.isEmpty) return 0.0;
    return totalValue / dataPoints.length;
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
      'title': title,
      'dataPoints': dataPoints.map((DataPoint x) => x.toMap()).toList(),
      'chartType': chartType.name,
      'xAxisLabel': xAxisLabel,
      'yAxisLabel': yAxisLabel,
      'colors': colors.map((ChartColor x) => x.toMap()).toList(),
      'animationDuration': animationDuration?.inMilliseconds,
      'showGrid': showGrid,
      'showLegend': showLegend,
      'showTooltips': showTooltips,
    };
}

/// نقطة بيانات
class DataPoint {
  const DataPoint({
    required this.label,
    required this.value,
    this.color,
    this.tooltip,
    this.metadata,
  });

  factory DataPoint.fromMap(Map<String, dynamic> map) => DataPoint(
      label: (map['label'] as String?) ?? '',
      value: (map['value'] as num?)?.toDouble() ?? 0.0,
      color: map['color'] != null
          ? ChartColor.fromMap(map['color'] as Map<String, dynamic>)
          : null,
      tooltip: map['tooltip'] as String?,
      metadata: map['metadata'] as Map<String, dynamic>?,
    );

  final String label;
  final double value;
  final ChartColor? color;
  final String? tooltip;
  final Map<String, dynamic>? metadata;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'label': label,
      'value': value,
      'color': color?.toMap(),
      'tooltip': tooltip,
      'metadata': metadata,
    };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is DataPoint &&
        other.label == label &&
        other.value == value &&
        other.color == color &&
        other.tooltip == tooltip;
  }

  @override
  int get hashCode => label.hashCode ^ value.hashCode ^ color.hashCode ^ tooltip.hashCode;
}

/// لون الرسم البياني
class ChartColor {
  const ChartColor({
    required this.red,
    required this.green,
    required this.blue,
    this.alpha = 1.0,
  });

  /// إنشاء لون من hex
  factory ChartColor.fromHex(String hex) {
    final String cleanHex = hex.replaceAll('#', '');
    final int r = int.parse(cleanHex.substring(0, 2), radix: 16);
    final int g = int.parse(cleanHex.substring(2, 4), radix: 16);
    final int b = int.parse(cleanHex.substring(4, 6), radix: 16);
    return ChartColor(red: r, green: g, blue: b);
  }

  /// إنشاء لون من RGB
  factory ChartColor.fromRgb(int red, int green, int blue,
      {double alpha = 1.0}) => ChartColor(
      red: red.clamp(0, 255),
      green: green.clamp(0, 255),
      blue: blue.clamp(0, 255),
      alpha: alpha.clamp(0.0, 1.0),
    );

  factory ChartColor.fromMap(Map<String, dynamic> map) => ChartColor(
      red: (map['red'] as int?) ?? 0,
      green: (map['green'] as int?) ?? 0,
      blue: (map['blue'] as int?) ?? 0,
      alpha: (map['alpha'] as num?)?.toDouble() ?? 1.0,
    );

  final int red;
  final int green;
  final int blue;
  final double alpha;

  /// تحويل إلى hex
  String toHex() {
    final String r = red.toRadixString(16).padLeft(2, '0');
    final String g = green.toRadixString(16).padLeft(2, '0');
    final String b = blue.toRadixString(16).padLeft(2, '0');
    return '#$r$g$b';
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
      'red': red,
      'green': green,
      'blue': blue,
      'alpha': alpha,
    };

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ChartColor &&
        other.red == red &&
        other.green == green &&
        other.blue == blue &&
        other.alpha == alpha;
  }

  @override
  int get hashCode => red.hashCode ^ green.hashCode ^ blue.hashCode ^ alpha.hashCode;
}

/// نوع الرسم البياني
enum ChartType {
  line,
  bar,
  pie,
  doughnut,
  area,
  scatter,
  radar,
}

/// ألوان مسبقة للرسوم البيانية
class ChartColors {
  static const ChartColor primary = ChartColor(red: 33, green: 150, blue: 243);
  static const ChartColor secondary = ChartColor(red: 76, green: 175, blue: 80);
  static const ChartColor accent = ChartColor(red: 255, green: 152, blue: 0);
  static const ChartColor error = ChartColor(red: 244, green: 67, blue: 54);
  static const ChartColor warning = ChartColor(red: 255, green: 193, blue: 7);
  static const ChartColor success = ChartColor(red: 76, green: 175, blue: 80);
  static const ChartColor info = ChartColor(red: 33, green: 150, blue: 243);

  static const List<ChartColor> defaultPalette = <ChartColor>[
    ChartColor(red: 33, green: 150, blue: 243), // Blue
    ChartColor(red: 76, green: 175, blue: 80), // Green
    ChartColor(red: 255, green: 152, blue: 0), // Orange
    ChartColor(red: 156, green: 39, blue: 176), // Purple
    ChartColor(red: 244, green: 67, blue: 54), // Red
    ChartColor(red: 0, green: 188, blue: 212), // Cyan
    ChartColor(red: 255, green: 193, blue: 7), // Amber
    ChartColor(red: 96, green: 125, blue: 139), // Blue Grey
  ];

  static const List<ChartColor> salesPalette = <ChartColor>[
    ChartColor(red: 33, green: 150, blue: 243), // Blue
    ChartColor(red: 76, green: 175, blue: 80), // Green
    ChartColor(red: 255, green: 152, blue: 0), // Orange
    ChartColor(red: 156, green: 39, blue: 176), // Purple
  ];

  static const List<ChartColor> paymentPalette = <ChartColor>[
    ChartColor(red: 76, green: 175, blue: 80), // Green (Cash)
    ChartColor(red: 33, green: 150, blue: 243), // Blue (Card)
    ChartColor(red: 255, green: 152, blue: 0), // Orange (Other)
  ];

  static const List<ChartColor> inventoryPalette = <ChartColor>[
    ChartColor(red: 76, green: 175, blue: 80), // Green (In Stock)
    ChartColor(red: 255, green: 152, blue: 0), // Orange (Low Stock)
    ChartColor(red: 244, green: 67, blue: 54), // Red (Out of Stock)
  ];
}

/// إعدادات الرسم البياني
class ChartSettings {
  const ChartSettings({
    this.showGrid = true,
    this.showLegend = true,
    this.showTooltips = true,
    this.animationDuration = const Duration(milliseconds: 300),
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 1.0,
    this.cornerRadius = 4.0,
    this.padding = const EdgeInsets.all(16.0),
  });

  factory ChartSettings.fromMap(Map<String, dynamic> map) => ChartSettings(
      showGrid: (map['showGrid'] as bool?) ?? true,
      showLegend: (map['showLegend'] as bool?) ?? true,
      showTooltips: (map['showTooltips'] as bool?) ?? true,
      animationDuration: Duration(
        milliseconds: (map['animationDuration'] as int?) ?? 300,
      ),
      backgroundColor: map['backgroundColor'] != null
          ? ChartColor.fromMap(map['backgroundColor'] as Map<String, dynamic>)
          : null,
      borderColor: map['borderColor'] != null
          ? ChartColor.fromMap(map['borderColor'] as Map<String, dynamic>)
          : null,
      borderWidth: (map['borderWidth'] as num?)?.toDouble() ?? 1.0,
      cornerRadius: (map['cornerRadius'] as num?)?.toDouble() ?? 4.0,
      padding: map['padding'] != null
          ? EdgeInsets.fromLTRB(
              (map['padding']['left'] as num?)?.toDouble() ?? 0.0,
              (map['padding']['top'] as num?)?.toDouble() ?? 0.0,
              (map['padding']['right'] as num?)?.toDouble() ?? 0.0,
              (map['padding']['bottom'] as num?)?.toDouble() ?? 0.0,
            )
          : const EdgeInsets.all(16.0),
    );

  final bool showGrid;
  final bool showLegend;
  final bool showTooltips;
  final Duration animationDuration;
  final ChartColor? backgroundColor;
  final ChartColor? borderColor;
  final double borderWidth;
  final double cornerRadius;
  final EdgeInsets padding;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'showGrid': showGrid,
      'showLegend': showLegend,
      'showTooltips': showTooltips,
      'animationDuration': animationDuration.inMilliseconds,
      'backgroundColor': backgroundColor?.toMap(),
      'borderColor': borderColor?.toMap(),
      'borderWidth': borderWidth,
      'cornerRadius': cornerRadius,
      'padding': <String, double>{
        'left': padding.left,
        'top': padding.top,
        'right': padding.right,
        'bottom': padding.bottom,
      },
    };
}

/// إعدادات المحور
class AxisSettings {
  const AxisSettings({
    this.showLabels = true,
    this.showTicks = true,
    this.labelRotation = 0.0,
    this.minValue,
    this.maxValue,
    this.tickCount,
    this.format,
  });

  factory AxisSettings.fromMap(Map<String, dynamic> map) => AxisSettings(
      showLabels: (map['showLabels'] as bool?) ?? true,
      showTicks: (map['showTicks'] as bool?) ?? true,
      labelRotation: (map['labelRotation'] as num?)?.toDouble() ?? 0.0,
      minValue: (map['minValue'] as num?)?.toDouble(),
      maxValue: (map['maxValue'] as num?)?.toDouble(),
      tickCount: map['tickCount'] as int?,
      format: map['format'] as String?,
    );

  final bool showLabels;
  final bool showTicks;
  final double labelRotation;
  final double? minValue;
  final double? maxValue;
  final int? tickCount;
  final String? format;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'showLabels': showLabels,
      'showTicks': showTicks,
      'labelRotation': labelRotation,
      'minValue': minValue,
      'maxValue': maxValue,
      'tickCount': tickCount,
      'format': format,
    };
}

/// إعدادات الأداة المساعدة
class TooltipSettings {
  const TooltipSettings({
    this.show = true,
    this.format,
    this.backgroundColor,
    this.textColor,
    this.borderRadius = 4.0,
    this.padding = const EdgeInsets.all(8.0),
  });

  factory TooltipSettings.fromMap(Map<String, dynamic> map) => TooltipSettings(
      show: (map['show'] as bool?) ?? true,
      format: map['format'] as String?,
      backgroundColor: map['backgroundColor'] != null
          ? ChartColor.fromMap(map['backgroundColor'] as Map<String, dynamic>)
          : null,
      textColor: map['textColor'] != null
          ? ChartColor.fromMap(map['textColor'] as Map<String, dynamic>)
          : null,
      borderRadius: (map['borderRadius'] as num?)?.toDouble() ?? 4.0,
      padding: map['padding'] != null
          ? EdgeInsets.fromLTRB(
              (map['padding']['left'] as num?)?.toDouble() ?? 0.0,
              (map['padding']['top'] as num?)?.toDouble() ?? 0.0,
              (map['padding']['right'] as num?)?.toDouble() ?? 0.0,
              (map['padding']['bottom'] as num?)?.toDouble() ?? 0.0,
            )
          : const EdgeInsets.all(8.0),
    );

  final bool show;
  final String? format;
  final ChartColor? backgroundColor;
  final ChartColor? textColor;
  final double borderRadius;
  final EdgeInsets padding;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'show': show,
      'format': format,
      'backgroundColor': backgroundColor?.toMap(),
      'textColor': textColor?.toMap(),
      'borderRadius': borderRadius,
      'padding': <String, double>{
        'left': padding.left,
        'top': padding.top,
        'right': padding.right,
        'bottom': padding.bottom,
      },
    };
}

/// إعدادات الرسم البياني الكاملة
class CompleteChartSettings {
  const CompleteChartSettings({
    this.chart = const ChartSettings(),
    this.xAxis = const AxisSettings(),
    this.yAxis = const AxisSettings(),
    this.tooltip = const TooltipSettings(),
  });

  factory CompleteChartSettings.fromMap(Map<String, dynamic> map) => CompleteChartSettings(
      chart: ChartSettings.fromMap(map['chart'] as Map<String, dynamic>),
      xAxis: AxisSettings.fromMap(map['xAxis'] as Map<String, dynamic>),
      yAxis: AxisSettings.fromMap(map['yAxis'] as Map<String, dynamic>),
      tooltip: TooltipSettings.fromMap(map['tooltip'] as Map<String, dynamic>),
    );

  final ChartSettings chart;
  final AxisSettings xAxis;
  final AxisSettings yAxis;
  final TooltipSettings tooltip;

  Map<String, dynamic> toMap() => <String, dynamic>{
      'chart': chart.toMap(),
      'xAxis': xAxis.toMap(),
      'yAxis': yAxis.toMap(),
      'tooltip': tooltip.toMap(),
    };
}
