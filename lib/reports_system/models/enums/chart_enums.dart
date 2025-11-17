/// نوع الرسم البياني
enum ChartType {
  line('خطي'),
  bar('عمودي'),
  pie('دائري'),
  area('منطقة'),
  scatter('نقاط'),
  donut('دونات'),
  gauge('مقياس'),
  heatmap('خريطة حرارية');

  final String description;
  const ChartType(this.description);
}

/// اتجاه الرسم البياني
enum ChartOrientation {
  horizontal('أفقي'),
  vertical('عمودي');

  final String description;
  const ChartOrientation(this.description);
}

/// نوع البيانات
enum DataType {
  sales('مبيعات'),
  revenue('إيرادات'),
  profit('أرباح'),
  quantity('كمية'),
  percentage('نسبة مئوية'),
  count('عدد'),
  average('متوسط'),
  total('إجمالي');

  final String description;
  const DataType(this.description);
}

/// فترة البيانات
enum DataPeriod {
  hourly('ساعي'),
  daily('يومي'),
  weekly('أسبوعي'),
  monthly('شهري'),
  quarterly('ربعي'),
  yearly('سنوي');

  final String description;
  const DataPeriod(this.description);
}

/// لون الرسم البياني
enum ChartColor {
  primary('أساسي'),
  secondary('ثانوي'),
  success('نجاح'),
  warning('تحذير'),
  error('خطأ'),
  info('معلومة'),
  light('فاتح'),
  dark('داكن');

  final String description;
  const ChartColor(this.description);
}
