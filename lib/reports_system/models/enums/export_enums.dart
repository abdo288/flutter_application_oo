/// تنسيق التصدير
enum ExportFormat {
  pdf('PDF'),
  excel('Excel'),
  csv('CSV'),
  json('JSON'),
  xml('XML'),
  html('HTML'),
  unknown('غير معروف');

  final String description;
  const ExportFormat(this.description);
}

/// جودة التصدير
enum ExportQuality {
  low('منخفضة'),
  medium('متوسطة'),
  high('عالية'),
  ultra('فائقة');

  final String description;
  const ExportQuality(this.description);
}

/// اتجاه الصفحة
enum PageOrientation {
  portrait('عمودي'),
  landscape('أفقي');

  final String description;
  const PageOrientation(this.description);
}

/// حجم الصفحة
enum PageSize {
  a4('A4'),
  a3('A3'),
  letter('Letter'),
  legal('Legal'),
  tabloid('Tabloid');

  final String description;
  const PageSize(this.description);
}
