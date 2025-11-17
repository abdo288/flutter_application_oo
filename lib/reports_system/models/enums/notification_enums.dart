/// نوع الإشعار
enum NotificationType {
  info('معلومة'),
  warning('تحذير'),
  error('خطأ'),
  success('نجاح'),
  lowStock('مخزون منخفض'),
  eodReminder('تذكير نهاية اليوم'),
  syncStatus('حالة المزامنة'),
  achievement('إنجاز'),
  unknown('غير معروف');

  final String description;
  const NotificationType(this.description);
}

/// أولوية الإشعار
enum NotificationPriority {
  low('منخفضة'),
  medium('متوسطة'),
  high('عالية'),
  critical('حرجة');

  final String description;
  const NotificationPriority(this.description);
}

/// مشغل الشرط
enum ConditionOperator {
  equals('يساوي'),
  notEquals('لا يساوي'),
  greaterThan('أكبر من'),
  lessThan('أصغر من'),
  greaterThanOrEqual('أكبر من أو يساوي'),
  lessThanOrEqual('أصغر من أو يساوي'),
  contains('يحتوي على'),
  notContains('لا يحتوي على'),
  startsWith('يبدأ بـ'),
  endsWith('ينتهي بـ'),
  isEmpty('فارغ'),
  isNotEmpty('غير فارغ'),
  inList('في القائمة'),
  notInList('ليس في القائمة');

  final String description;
  const ConditionOperator(this.description);
}

/// نوع الإجراء
enum ActionType {
  showSnackbar('عرض رسالة'),
  showDialog('عرض نافذة'),
  showNotification('عرض إشعار'),
  sendEmail('إرسال بريد إلكتروني'),
  sendSms('إرسال رسالة نصية'),
  playSound('تشغيل صوت'),
  vibrate('اهتزاز'),
  logEvent('تسجيل حدث'),
  triggerAction('تشغيل إجراء');

  final String description;
  const ActionType(this.description);
}
