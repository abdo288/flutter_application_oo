/// طريقة الدفع
enum PaymentMethod {
  cash('نقدي'),
  card('بطاقة'),
  bankTransfer('تحويل بنكي'),
  check('شيك'),
  other('أخرى');

  final String description;
  const PaymentMethod(this.description);
}

/// حالة المبلغ المسترد
enum RefundStatus {
  pending('في الانتظار'),
  approved('موافق عليه'),
  rejected('مرفوض'),
  processed('تم المعالجة');

  final String description;
  const RefundStatus(this.description);
}

/// حالة الدين
enum DebtStatus {
  pending('في الانتظار'),
  partiallyPaid('مدفوع جزئياً'),
  paid('مدفوع'),
  overdue('متأخر'),
  cancelled('ملغي');

  final String description;
  const DebtStatus(this.description);
}

/// نوع الفترة
enum PeriodType {
  daily('يومي'),
  weekly('أسبوعي'),
  monthly('شهري'),
  quarterly('ربعي'),
  yearly('سنوي'),
  custom('مخصص');

  final String description;
  const PeriodType(this.description);
}

/// حالة المزامنة
enum SyncStatus {
  synced('مزامن'),
  syncing('جاري المزامنة'),
  failed('فشل'),
  unknown('غير معروف');

  final String description;
  const SyncStatus(this.description);
}

/// حقل الترتيب
enum SortField {
  date('التاريخ'),
  amount('المبلغ'),
  customer('العميل'),
  employee('الموظف'),
  product('المنتج'),
  category('الفئة'),
  status('الحالة');

  final String description;
  const SortField(this.description);
}

/// ترتيب
enum SortOrder {
  ascending('تصاعدي'),
  descending('تنازلي');

  final String description;
  const SortOrder(this.description);
}
