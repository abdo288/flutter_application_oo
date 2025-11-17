/// ثوابت نظام التقارير
class ReportsConstants {
  // ألوان النظام
  static const int primaryColor = 0xFF2196F3;
  static const int secondaryColor = 0xFF03DAC6;
  static const int successColor = 0xFF4CAF50;
  static const int warningColor = 0xFFFF9800;
  static const int errorColor = 0xFFF44336;
  static const int infoColor = 0xFF2196F3;

  // ألوان الرسوم البيانية
  static const List<int> chartColors = <int>[
    0xFF2196F3, // أزرق
    0xFF4CAF50, // أخضر
    0xFFFF9800, // برتقالي
    0xFF9C27B0, // بنفسجي
    0xFFF44336, // أحمر
    0xFF00BCD4, // تركوازي
    0xFFFFC107, // أصفر
    0xFF795548, // بني
  ];

  // أحجام الصفحات
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;
  static const int chartHeight = 300;
  static const int cardHeight = 120;

  // فترات زمنية افتراضية
  static const int defaultDaysRange = 30;
  static const int weeklyRange = 7;
  static const int monthlyRange = 30;
  static const int yearlyRange = 365;

  // حدود البيانات
  static const int maxTopProducts = 10;
  static const int maxLowStockAlerts = 20;
  static const int maxRecentSales = 50;

  // رسائل النظام
  static const String loadingMessage = 'جاري التحميل...';
  static const String errorMessage = 'حدث خطأ في تحميل البيانات';
  static const String noDataMessage = 'لا توجد بيانات للعرض';
  static const String syncSuccessMessage = 'تمت المزامنة بنجاح';
  static const String syncErrorMessage = 'فشل في المزامنة';

  // تنسيقات التصدير
  static const List<String> exportFormats = <String>['PDF', 'Excel', 'CSV', 'JSON'];
  static const String defaultExportFormat = 'PDF';

  // إعدادات التخزين المؤقت
  static const int cacheExpirationMinutes = 30;
  static const int maxCacheSize = 100; // عدد العناصر

  // إعدادات الإشعارات
  static const int lowStockThreshold = 10;
  static const int syncRetryAttempts = 3;
  static const int syncRetryDelaySeconds = 5;

  // أسماء المفاتيح للتخزين المحلي
  static const String cacheKeyPrefix = 'reports_cache_';
  static const String settingsKey = 'reports_settings';
  static const String filtersKey = 'reports_filters';
  static const String lastSyncKey = 'last_sync_time';

  // أنواع التقارير
  static const String dashboardReport = 'dashboard';
  static const String eodReport = 'eod';
  static const String salesReport = 'sales';
  static const String analyticsReport = 'analytics';
  static const String inventoryReport = 'inventory';
  static const String paymentReport = 'payment';

  // حالات المزامنة
  static const String syncStatusSynced = 'synced';
  static const String syncStatusSyncing = 'syncing';
  static const String syncStatusFailed = 'failed';
  static const String syncStatusPending = 'pending';

  // أنواع الرسوم البيانية
  static const String chartTypeLine = 'line';
  static const String chartTypeBar = 'bar';
  static const String chartTypePie = 'pie';
  static const String chartTypeArea = 'area';

  // فترات التحليل
  static const String periodDaily = 'daily';
  static const String periodWeekly = 'weekly';
  static const String periodMonthly = 'monthly';
  static const String periodYearly = 'yearly';

  // أنواع الفلاتر
  static const String filterDateRange = 'date_range';
  static const String filterPaymentMethod = 'payment_method';
  static const String filterEmployee = 'employee';
  static const String filterProduct = 'product';
  static const String filterCategory = 'category';
  static const String filterPriceRange = 'price_range';

  // اتجاهات الترتيب
  static const String sortAscending = 'asc';
  static const String sortDescending = 'desc';

  // حقول الترتيب
  static const String sortByDate = 'date';
  static const String sortByAmount = 'amount';
  static const String sortByCustomer = 'customer';
  static const String sortByEmployee = 'employee';
  static const String sortByProduct = 'product';

  // طرق الدفع
  static const String paymentCash = 'cash';
  static const String paymentCard = 'card';
  static const String paymentBankTransfer = 'bank_transfer';
  static const String paymentCheck = 'check';
  static const String paymentOther = 'other';

  // حالات البيع
  static const String saleStatusCompleted = 'completed';
  static const String saleStatusPending = 'pending';
  static const String saleStatusCancelled = 'cancelled';
  static const String saleStatusRefunded = 'refunded';

  // أنواع التنبيهات
  static const String notificationLowStock = 'low_stock';
  static const String notificationEODReminder = 'eod_reminder';
  static const String notificationSyncStatus = 'sync_status';
  static const String notificationAchievement = 'achievement';

  // مستويات الأولوية
  static const String priorityLow = 'low';
  static const String priorityMedium = 'medium';
  static const String priorityHigh = 'high';
  static const String priorityCritical = 'critical';

  // أنواع الإحصائيات
  static const String statTotalSales = 'total_sales';
  static const String statTotalProfit = 'total_profit';
  static const String statTotalItems = 'total_items';
  static const String statTotalCustomers = 'total_customers';
  static const String statAverageSale = 'average_sale';
  static const String statTopProducts = 'top_products';
  static const String statLowStock = 'low_stock';

  // وحدات القياس
  static const String unitCurrency = 'ر.س';
  static const String unitQuantity = 'وحدة';
  static const String unitPercentage = '%';
  static const String unitDays = 'يوم';
  static const String unitHours = 'ساعة';

  // أنماط التصميم
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
  static const double buttonElevation = 1.0;
  static const double iconSize = 24.0;
  static const double smallIconSize = 16.0;
  static const double largeIconSize = 32.0;

  // أحجام النصوص
  static const double smallTextSize = 12.0;
  static const double normalTextSize = 14.0;
  static const double largeTextSize = 16.0;
  static const double titleTextSize = 18.0;
  static const double headerTextSize = 20.0;

  // المسافات
  static const double smallPadding = 8.0;
  static const double normalPadding = 16.0;
  static const double largePadding = 24.0;
  static const double extraLargePadding = 32.0;

  // أحجام الشاشات
  static const double mobileBreakpoint = 600.0;
  static const double tabletBreakpoint = 900.0;
  static const double desktopBreakpoint = 1200.0;

  // إعدادات الأداء
  static const int debounceDelay = 500; // milliseconds
  static const int animationDuration = 300; // milliseconds
  static const int refreshInterval = 30000; // milliseconds

  // حدود الأمان
  static const int maxRetryAttempts = 3;
  static const int maxConcurrentRequests = 5;
  static const int requestTimeout = 30000; // milliseconds

  // إعدادات التصدير
  static const int pdfPageWidth = 595; // A4 width in points
  static const int pdfPageHeight = 842; // A4 height in points
  static const int pdfMargin = 40;
  static const String pdfFontFamily = 'Arial';
  static const int pdfFontSize = 12;

  // إعدادات Excel
  static const String excelSheetName = 'التقارير';
  static const int excelMaxRows = 1000000;
  static const int excelMaxColumns = 16384;

  // إعدادات CSV
  static const String csvDelimiter = ',';
  static const String csvQuote = '"';
  static const String csvEncoding = 'utf-8';

  // رسائل الخطأ
  static const String errorNetworkConnection = 'خطأ في الاتصال بالشبكة';
  static const String errorDataNotFound = 'البيانات غير موجودة';
  static const String errorPermissionDenied = 'ليس لديك صلاحية للوصول';
  static const String errorInvalidData = 'البيانات غير صحيحة';
  static const String errorExportFailed = 'فشل في التصدير';
  static const String errorSyncFailed = 'فشل في المزامنة';
  static const String errorPrintFailed = 'فشل في الطباعة';

  // رسائل النجاح
  static const String successDataLoaded = 'تم تحميل البيانات بنجاح';
  static const String successDataExported = 'تم تصدير البيانات بنجاح';
  static const String successDataSynced = 'تم مزامنة البيانات بنجاح';
  static const String successReportGenerated = 'تم إنشاء التقرير بنجاح';
  static const String successSettingsSaved = 'تم حفظ الإعدادات بنجاح';

  // رسائل المعلومات
  static const String infoNoDataAvailable = 'لا توجد بيانات متاحة';
  static const String infoLoadingData = 'جاري تحميل البيانات...';
  static const String infoProcessingData = 'جاري معالجة البيانات...';
  static const String infoSyncingData = 'جاري مزامنة البيانات...';
  static const String infoExportingData = 'جاري تصدير البيانات...';
}
