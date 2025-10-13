import 'package:flutter/widgets.dart';

class AppLocalizations {
  AppLocalizations(this.locale);
  final Locale locale;

  static AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static const List<String> _supportedCodes = <String>['ar', 'en', 'fr'];

  static bool isSupported(Locale locale) =>
      _supportedCodes.contains(locale.languageCode);

  static const Map<String, Map<String, String>> _localizedValues =
      <String, Map<String, String>>{
    'ar': <String, String>{
      'appTitle': 'حاسبة الأرباح',
      'dashboard': 'لوحة التحكم',
      'addProduct': 'إضافة منتج',
      'productList': 'قائمة المنتجات',
      'inventory': 'المخزون',
      'storeDisplay': 'عرض المتجر',
      'settings': 'الإعدادات',
      'notifications': 'التنبيهات',
      'settingsTitle': 'الإعدادات',
      'notificationsSection': 'الإشعارات',
      'enableNotifications': 'تفعيل الإشعارات',
      'receiveAppNotifications': 'تلقي إشعارات التطبيق',
      'lowStockAlerts': 'تنبيهات نفاد المخزون',
      'dailyReminders': 'التذكيرات اليومية',
      'weeklyReminders': 'التذكيرات الأسبوعية',
      'remindersSection': 'التذكيرات',
      'actionsSection': 'إجراءات إضافية',
      'appInfo': 'معلومات التطبيق',
      'ok': 'موافق',
      'searchInventoryHint': 'ابحث في المخزون...',
      'searchProductsHint': 'ابحث عن منتج...',
      'noResults': 'لا توجد نتائج مطابقة',
      'clearSearch': 'مسح البحث',
      'noInventoryItems': 'لا توجد عناصر في المخزون',
      'addToInventory': 'اضافة الى المخزون',
      'loadingDashboard': 'جاري تحميل لوحة التحكم...',
      'noProfitData': 'لا توجد بيانات للأرباح',
      'topProfitableProducts': 'أفضل المنتجات ربحية',
      'settingsAppBar': 'الإعدادات',
      'loadingBestProducts': 'جاري تحميل أفضل المنتجات...',
      'scanBarcodeButton': 'مسح الباركود',
      'generateBarcodeButton': 'توليد باركود',
      'barcodeLabel': 'الباركود:',
      'copyBarcode': 'تم نسخ الباركود',
      'copyBarcodeTooltip': 'نسخ الباركود',
      'addingItem': 'جاري الإضافة...',
      'addItemToInventory': 'إضافة السلعة للمخزون',
      'clearFormButton': 'مسح النموذج',
      'bulkAddButton': 'إضافة متعددة',
      'bulkAddTitle': 'إضافة متعددة للمخزون',
      'inputInstructions': 'تعليمات الإدخال:',
      'inputInstructionsText': 'أدخل كل منتج في سطر منفصل بالتنسيق التالي:',
      'inputFormat':
          'اسم المنتج | سعر الجملة | الكمية | تاريخ الانتهاء (اختياري)',
      'inputExample': 'مثال: لابتوب ديل | 50000 | 5 | 2024-12-31',
      'productDataLabel': 'بيانات المنتجات',
      'productDataHint': 'أدخل بيانات المنتجات هنا...',
      'dataPreview': 'معاينة البيانات:',
      'analyzeData': 'تحليل البيانات',
      'addItems': 'إضافة {count} عنصر',
      'profitLabel': 'ربح:',
      'noProducts': 'لا توجد منتجات',
      'sortByNameAsc': 'الاسم (أ-ي)',
      'sortByNameDesc': 'الاسم (ي-أ)',
      'sortByPriceAsc': 'السعر (منخفض)',
      'sortByPriceDesc': 'السعر (مرتفع)',
      'sortByProfitAsc': 'الربح (منخفض)',
      'sortByProfitDesc': 'الربح (مرتفع)',
      'sortByDateAsc': 'التاريخ (قديم)',
      'sortByDateDesc': 'التاريخ (جديد)',
      'filterAll': 'فلترة: الكل',
      'filterHighProfit': 'فلترة: ربح عالي',
      'filterLowProfit': 'فلترة: ربح منخفض',
      'sortTooltip': 'ترتيب: {option}',
      'filterTooltip': 'فلترة: {option}',
      'nameColumn': 'الاسم',
      'quantityColumn': 'الكمية',
      'priceColumn': 'السعر',
      'dateColumn': 'التاريخ',
      'confirmDelete': 'تأكيد الحذف',
      'confirmDeleteMessage':
          'هل أنت متأكد من أنك تريد حذف العنصر "{itemName}"؟',
      'deleteFailed': 'فشل في حذف العنصر: {error}',
      'quantityLabel': 'الكمية: {quantity}',
      'outOfStockMessage': 'نفدت الكمية (كانت: {originalQuantity})',
      'outOfStock': 'نفدت',
      'hideDetails': 'إخفاء التفاصيل',
      'showDetails': 'عرض التفاصيل',
      'barcodeColumn': 'الباركود',
      'copyBarcodeTooltipNew': 'نسخ الباركود',
      'barcodeCopiedNew': 'تم نسخ الباركود',
      'financialDetailsNew': 'التفاصيل المالية',
      'wholesalePriceLabelNew': 'سعر الجملة',
      'allSettingsAndActionsNew': 'جميع الإعدادات والإجراءات',
      'alertSettingsNew': 'إعدادات التنبيهات',
      'manageAlertsNew': 'إدارة التنبيهات',
      'filterAlertsNew': 'فلترة التنبيهات',
      'displayControlNew': 'التحكم في العرض',
      'closeAllGroupsNew': 'إغلاق جميع المجموعات',
      'openAllGroupsNew': 'فتح جميع المجموعات',
      'bulkActionsNew': 'الإجراءات الجماعية',
      'cleanOldAlertsNew': 'تنظيف التنبيهات القديمة',
      'alertStatisticsNew': 'إحصائيات التنبيهات',
      'totalNew': 'إجمالي',
      'unreadNew': 'غير مقروءة',
      'outOfStockAlertsNew': 'نفدت',
      'lowStockAlertsNew': 'حد أدنى',
      'expiringSoonAlertsNew': 'قارب الانتهاء',
      'allProductsGoodNew':
          'جميع منتجاتك في حالة جيدة!\nاضغط على زر الفحص لمراجعة المخزون',
      'checkInventoryButtonNew': 'فحص المخزون',
      'excellentNew': 'ممتاز! 🎉',
      'noUnreadAlertsNew':
          'لا توجد تنبيهات غير مقروءة\nجميع التنبيهات تم قراءتها',
      'newCheckButtonNew': 'فحص جديد',
      'advancedFilters': 'فلاتر متقدمة',
      'lowProfitFilter': 'أقل ربح',
      'editItem': 'تعديل',
      'printBarcode': 'طباعة باركود',
      'printBarcodeQuantity': 'عدد النسخ المطلوبة',
      'printBarcodeQuantityHint': 'أدخل عدد النسخ (1-100)',
      'printBarcodeQuantityError': 'الرجاء إدخال عدد صحيح بين 1 و 100',
      'printBarcodeQuantityDialogTitle': 'اختيار عدد النسخ',
      'printBarcodeQuantityDialogContent':
          'كم عدد الباركودات التي تريد طباعتها؟',
      'printBarcodeQuantityDialogConfirm': 'طباعة',
      'printBarcodeQuantityDialogCancel': 'إلغاء',
      'deleteItem': 'حذف العنصر',
      'addDate': 'تاريخ الإضافة:',
      'addTime': 'وقت الإضافة:',
      'expiryDate': 'تاريخ الانتهاء:',
      'availableQuantity': 'الكمية المتاحة',
      'totalValue': 'القيمة الإجمالية',
      'pieces': 'قطعة',
      'loadingAlertsError': 'خطأ في تحميل التنبيهات',
      'markAsReadSuccess': 'تم تحديد التنبيه كمقروء',
      'markAsReadError': 'خطأ في تحديد التنبيه كمقروء',
      'deleteAlertSuccess': 'تم حذف التنبيه',
      'deleteAlertError': 'خطأ في حذف التنبيه',
      'confirmDeleteAlert': 'تأكيد الحذف',
      'confirmDeleteAlertMessage': 'هل تريد حذف تنبيه "{productName}"؟',
      'cancel': 'إلغاء',
      'delete': 'حذف',
      'applyFilterError': 'خطأ في تطبيق الفلتر: {error}',
      'language': 'اللغة',
      'chooseLanguage': 'اختر اللغة',
      'alertsTitle': 'تنبيهات المخزون',
      'alertsSubtitle': 'مراقبة المخزون والتنبيهات',
      'alertSettings': 'إعدادات التنبيهات',
      'refreshAlerts': 'تحديث التنبيهات',
      'filterUnread': 'غير مقروءة فقط',
      'markAllRead': 'تحديد الكل كمقروء',
      'deleteRead': 'حذف المقروءة',
      'checkAlerts': 'فحص التنبيهات',
      'checkInventory': 'فحص المخزون',
      'loadingAlerts': 'جاري تحميل التنبيهات...',
      'pleaseWait': 'يرجى الانتظار قليلاً',
      'noAlerts': 'لا توجد تنبيهات',
      'scanBarcode': 'مسح',
      'retailPrice': 'سعر التجزئة',
      'addToInventoryButton': 'إضافة السلعة للمخزون',
      'clearForm': 'مسح النموذج',
      'bulkAdd': 'إضافة متعددة',
      'productName': 'اسم السلعة',
      'wholesalePrice': 'سعر الجملة',
      'quantity': 'الكمية',
      'generateBarcode': 'توليد باركود',
      'pickExpiry': 'اختر تاريخ الانتهاء',
      'selectProduct': 'اختيار المنتج',
      'chooseFromInventory': 'اختر منتج من المخزون',
      'chooseProductHint': 'اختر منتج...',
      'fastBarcodeHint': 'أدخل الباركود لبيع سريع',
      'confirm': 'تأكيد',
      'exitAppQuestion': 'هل تريد الخروج من التطبيق؟',
      'yes': 'نعم',
      'no': 'لا',
      'deleteReadConfirm': 'هل تريد حذف جميع التنبيهات المقروءة؟',
      'pleaseSelectProduct': 'يرجى اختيار منتج',
      'noInventoryAvailableTitle': 'لا توجد منتجات متاحة في المخزون',
      'noInventoryAvailableSubtitle': 'يرجى إضافة منتجات إلى المخزون أولاً',
      'selected': 'تم اختيار',
      'remainingQuantity': 'الكمية المتبقية',
      'noItemWithBarcode': 'لا يوجد عنصر بهذا الباركود',
      'addInventoryHeader': 'إضافة عنصر جديد للمخزون',
      'addInventorySubtitle': 'أدخل تفاصيل المنتج لإضافته إلى المخزون',
      'basicInfo': 'معلومات المنتج الأساسية',
      'priceQuantity': 'السعر والكمية',
      'advancedOptions': 'خيارات متقدمة',
      'barcode': 'الباركود',
      'selectedPrefix': 'تم اختيار',
      'remainingQuantityLabel': 'الكمية المتبقية',
      'barcodeGeneratedSuccess': 'تم توليد الباركود بنجاح',
      'barcodeError': 'خطأ في توليد الباركود',
      'barcodeAlreadyUsed': 'هذا الباركود مستخدم بالفعل',
      'barcodeScanSuccess': 'تم مسح الباركود بنجاح',
      'barcodeScanError': 'خطأ في مسح الباركود',
      'bulkAddResult': 'تم إضافة {ok} عنصر بنجاح، فشل {err} عنصر',
      'successAdd': 'تم الإضافة بنجاح',
      'successDelete': 'تم الحذف بنجاح',
      'generalError': 'حدث خطأ غير متوقع',
      'outOfStockWarning': 'نفذت الكمية',
      'updateInventoryError': 'خطأ في تحديث كمية المخزون',
      'productNameExists': 'اسم المنتج موجود بالفعل في المخزون',
      'enterProductName': 'يرجى إدخال اسم المنتج',
      'invalidInventoryData': 'البيانات المدخلة غير صحيحة',
      'failedToDeleteProduct': 'فشل في حذف المنتج',
      'failedToDeleteItem': 'فشل في حذف العنصر',
      'noBarcodeForItem': 'لا يوجد باركود لهذا العنصر',
      'printBarcodeError': 'تعذر إنشاء/طباعة الباركود',
      'inventoryCheckedSuccess': 'تم فحص المخزون بنجاح',
      'inventoryCheckError': 'خطأ في فحص المخزون',
      'dashboardWelcome': 'مرحباً بك في لوحة التحكم الشاملة',
      'totalProductsSold': 'إجمالي المنتجات المباعة',
      'totalProductsValue': 'القيمة الإجمالية للمنتجات',
      'todaySales': 'مبيعات اليوم',
      'monthlySales': 'مبيعات الشهر',
      'totalProfitTitle': 'إجمالي الأرباح',
      'averageProductPrice': 'متوسط سعر المنتج',
      'uniqueProductNames': 'عدد المنتجات المختلفة',
      'averageProfitPerProduct': 'متوسط الربح لكل منتج',
      'totalProfitPercentage': 'نسبة الربح الإجمالية',
      'averageDailySales': 'متوسط المبيعات اليومية',
      'averageMonthlySales': 'متوسط المبيعات الشهرية',
      'averageDailyProfit': 'متوسط الأرباح اليومية',
      'profitLast30Days': 'الأرباح خلال آخر 30 يوم',
      'dateFilter': 'فلترة التاريخ',
      'resetFilters': 'إعادة تعيين الفلاتر',
      'advancedFiltersToggle': 'فلاتر متقدمة',
      'sortByName': 'الاسم',
      'sortByQuantity': 'الكمية',
      'sortByPrice': 'السعر',
      'sortByDate': 'التاريخ',
      'ascending': 'تصاعدي',
      'descending': 'تنازلي',
      'totalItems': 'إجمالي العناصر',
      'productNameLabel': 'اسم السلعة',
      'productNameHint': 'أدخل اسم المنتج',
      'wholesalePriceLabel': 'سعر الجملة',
      'quantityUnit': 'قطعة',
      'expiryDateLabel': 'تاريخ الانتهاء (اختياري)',
      'expiryDateHint': 'اختر تاريخ الانتهاء',
      'productUnit': 'منتج',
      'currencyUnit': 'دينار جزائري',
      'recentFilter': 'حديث',
      'oldFilter': 'قديم',
      'highestProfit': 'أعلى ربح',
      'resetButton': 'إعادة تعيين',
      'closeButton': 'إغلاق',
      'totalProfit': 'إجمالي الربح',
      'averageProfit': 'متوسط الربح',
      'highProfit': 'ربح عالي',
      'unknownAction': 'إجراء غير معروف',
      'actionError': 'خطأ في تنفيذ الإجراء',
      'markAllReadSuccess': 'تم تحديد جميع التنبيهات كمقروءة',
      'markAllReadError': 'خطأ في تحديد التنبيهات كمقروءة',
      'deleteReadSuccess': 'تم حذف التنبيهات المقروءة',
      'deleteReadError': 'خطأ في حذف التنبيهات المقروءة',
      'cleanupSuccess': 'تم تنظيف التنبيهات القديمة بنجاح',
      'cleanupError': 'خطأ في تنظيف التنبيهات القديمة',
      'settingsError': 'خطأ في فتح الإعدادات',
      'outOfStockAlert': 'نفدت الكمية',
      'lowStockAlert': 'وصلت للحد الأدنى',
      'expiringAlert': 'قاربت على الانتهاء',
      'toggleGroupsError': 'خطأ في تبديل المجموعات',
      'lowProfit': 'ربح منخفض',
      'editTooltip': 'تعديل',
      'showDetailsTooltip': 'عرض التفاصيل',
      'hideDetailsTooltip': 'إخفاء التفاصيل',
      'wholesalePriceShort': 'س.ج',
      'retailPriceShort': 'س.ت',
      'dateLabel': 'التاريخ',
      'timeLabel': 'الوقت',
      'confirmDeleteProduct': 'تأكيد الحذف',
      'confirmDeleteProductMessage': 'هل أنت متأكد من أنك تريد حذف هذا المنتج؟',
      'deleteProductError': 'فشل في حذف المنتج',
      'productIdError': 'خطأ: معرف المنتج غير موجود',
      'screenInfo': 'معلومات الشاشة',
      'width': 'العرض',
      'height': 'الارتفاع',
      'deviceType': 'نوع الجهاز',
      'columnsCount': 'عدد الأعمدة',
      'spacing': 'المسافات',
      'responsiveCardsTest': 'اختبار البطاقات المتجاوبة',
      'totalProducts': 'إجمالي المنتجات',
      'profits': 'الأرباح',
      'responsiveButtonsTest': 'اختبار الأزرار المتجاوبة',
      'normalButton': 'زر عادي',
      'outlinedButton': 'زر مخطط',
      'iconButton': 'زر مع أيقونة',
      'responsiveTextTest': 'اختبار النصوص المتجاوبة',
      'largeText': 'نص كبير',
      'mediumText': 'نص متوسط',
      'normalText': 'نص عادي',
      'smallText': 'نص صغير',
      'responsiveGridTest': 'اختبار الشبكة المتجاوبة',
      'item': 'عنصر',
      'mobile': 'موبايل',
      'tablet': 'تابلت',
      'desktop': 'سطح المكتب',
      'largeDesktop': 'سطح مكتب كبير',
      'ultraWide': 'شاشة عريضة',
      'dataLoadingError': 'خطأ في تحميل البيانات',
      'quantityLabelShort': 'الكمية',
      // إعدادات محسنة
      'welcomeToSettings': 'مرحباً بك في الإعدادات',
      'customizeApp': 'قم بتخصيص التطبيق حسب احتياجاتك',
      'languageAndRegion': 'اللغة والمنطقة',
      'notificationsSettings': 'الإشعارات',
      'remindersSettings': 'التذكيرات',
      'actionsSettings': 'الإجراءات',
      'appInfoSettings': 'معلومات التطبيق',
      'enableNotificationsDesc': 'تلقي إشعارات التطبيق',
      'lowStockAlertsDesc': 'إشعارات عند نفاد أو قرب نفاد المخزون',
      'dailyRemindersDesc': 'تذكيرات يومية لفحص المخزون',
      'weeklyRemindersDesc': 'تذكيرات أسبوعية للمراجعة الشاملة',
      'cleanupData': 'تنظيف البيانات',
      'cleanupDataDesc': 'حذف التنبيهات القديمة والبيانات غير المستخدمة',
      'resetSettings': 'إعادة تعيين الإعدادات',
      'resetSettingsDesc': 'إعادة تعيين جميع الإعدادات للقيم الافتراضية',
      'appVersion': 'إصدار التطبيق',
      'developer': 'المطور',
      'lastUpdate': 'آخر تحديث',
      'availableFeatures': 'الميزات المتاحة',
      'offlineWork': 'العمل في وضع عدم الاتصال',
      'autoSync': 'مزامنة تلقائية',
      'localNotifications': 'إشعارات محلية',
      'scheduledReminders': 'تذكيرات مجدولة',
      'autoDataCleanup': 'تنظيف تلقائي للبيانات',
      'cleanupConfirm': 'تنظيف البيانات',
      'cleanupConfirmMessage':
          'هل تريد حذف التنبيهات القديمة والبيانات غير المستخدمة؟\n\nهذا الإجراء لا يمكن التراجع عنه.',
      'cleanup': 'تنظيف',
      'resetConfirm': 'إعادة تعيين الإعدادات',
      'resetConfirmMessage':
          'هل تريد إعادة تعيين جميع الإعدادات للقيم الافتراضية؟\n\nهذا الإجراء لا يمكن التراجع عنه.',
      'reset': 'إعادة تعيين',
      'cleanupSuccessMessage': 'تم تنظيف البيانات بنجاح',
      'cleanupErrorMessage': 'خطأ في تنظيف البيانات: {error}',
      'resetSuccessMessage': 'تم إعادة تعيين الإعدادات بنجاح',
      'resetErrorMessage': 'خطأ في إعادة تعيين الإعدادات: {error}',
      // نصوص شاشة اختبار التصميم المتجاوب
      'responsiveTestTitle': 'اختبار التصميم المتجاوب',
      'deviceInfo': 'معلومات الجهاز',
      'deviceInfoTooltip': 'معلومات الجهاز',
      'breakpointsInfo': 'نقاط التوقف',
      'breakpointsInfoTooltip': 'معلومات نقاط التوقف',
      'screenWidth': 'العرض',
      'screenHeight': 'الارتفاع',
      'isLargeScreen': 'شاشة كبيرة',
      'isSmallScreen': 'شاشة صغيرة',
      'isMediumScreen': 'شاشة متوسطة',
      'isDesktopScreen': 'سطح مكتب',
      'isUltraWideScreen': 'شاشة عريضة',
      'gridColumns': 'عدد الأعمدة',
      'responsiveSpacing': 'المسافات',
      'close': 'إغلاق',
      'mobileBreakpoint': 'موبايل',
      'tabletBreakpoint': 'تابلت',
      'desktopBreakpoint': 'سطح مكتب',
      'largeDesktopBreakpoint': 'سطح مكتب كبير',
      'ultraWideBreakpoint': 'شاشة عريضة',
      'currentSize': 'الحجم الحالي',
      'classification': 'التصنيف',
      'deviceTypeMobile': 'موبايل',
      'deviceTypeTablet': 'تابلت',
      'deviceTypeDesktop': 'سطح المكتب',
      'deviceTypeLargeDesktop': 'سطح مكتب كبير',
      'deviceTypeUltraWide': 'شاشة عريضة',
      // نصوص إضافية للإعدادات
      'appManagement': 'إدارة التطبيق والإعدادات المتقدمة',
      'connectionStatus': 'حالة الاتصال',
      'connectionType': 'نوع الاتصال',
      'syncStatus': 'حالة المزامنة',
      'localData': 'البيانات المحلية',
      'available': 'متاح',
      'unavailable': 'غير متاح',
      'automatic': 'تلقائية',
      'manual': 'يدوية',
      'developmentTeam': 'فريق التطوير',
      'connectedToInternet': 'متصل بالإنترنت',
      'notConnectedToInternet': 'غير متصل',
      'appConnectedMessage': 'التطبيق متصل بالإنترنت ويعمل بشكل طبيعي',
      'appOfflineMessage': 'التطبيق يعمل في الوضع غير المتصل',
      'offlineMode': 'وضع عدم الاتصال',
      'retry': 'إعادة المحاولة',

      // Card details screen translations
      'uniqueProducts': 'منتجات فريدة',
      'averageProductsPerDay': 'متوسط المنتجات يومياً',
      'averageValuePerProduct': 'متوسط القيمة للمنتج',
      'highestValueProduct': 'أعلى منتج قيمة',
      'productsSoldToday': 'المنتجات المباعة اليوم',
      'todayDate': 'تاريخ اليوم',
      'salesTrend': 'اتجاه المبيعات',
      'productsSoldThisMonth': 'المنتجات المباعة هذا الشهر',
      'currentMonth': 'الشهر الحالي',
      'profitMargin': 'هامش الربح',
      'averagePrice': 'متوسط السعر',
      'priceRange': 'نطاق السعر',
      'trendingUp': 'في ارتفاع',
      'trendingDown': 'في انخفاض',
      'stable': 'مستقر',
      'noData': 'لا توجد بيانات',

      // Alert settings dialog translations
      'alertSettingsTitle': 'إعدادات التنبيهات',
      'outOfStockAlertDesc': 'إرسال تنبيه عند نفاد كمية أي منتج',
      'lowStockAlertTitle': 'تنبيه الحد الأدنى',
      'lowStockAlertDesc': 'إرسال تنبيه عند وصول الكمية للحد الأدنى',
      'lowStockThreshold': 'الحد الأدنى للتنبيه',
      'lowStockThresholdHint': 'أدخل الحد الأدنى للكمية',
      'expiringAlertTitle': 'تنبيه قرب الانتهاء',
      'expiringAlertDesc': 'إرسال تنبيه للمنتجات القاربة على الانتهاء',
      'daysBeforeExpiry': 'أيام قبل الانتهاء',
      'daysBeforeExpiryHint': 'عدد الأيام قبل انتهاء المنتج للتنبيه',
      'additionalActions': 'إجراءات إضافية',
      'save': 'حفظ',
      'updateAlerts': 'تحديث التنبيهات',
      'updateAlertsDesc': 'تحديث قائمة التنبيهات الحالية',
      'checkAlertsAction': 'فحص التنبيهات',
      'checkAlertsDesc': 'فحص المخزون وإنشاء تنبيهات جديدة',
      'viewAllAlerts': 'عرض جميع التنبيهات',
      'viewAllAlertsDesc': 'إظهار جميع التنبيهات (مقروءة وغير مقروءة)',
      'viewUnreadAlerts': 'عرض التنبيهات غير المقروءة',
      'viewUnreadAlertsDesc': 'إظهار التنبيهات غير المقروءة فقط',
      'markAllAsReadTitle': 'تحديد الكل كمقروء',
      'markAllAsReadDesc': 'تحديد جميع التنبيهات كمقروءة',
      'deleteReadAlertsTitle': 'حذف التنبيهات المقروءة',
      'deleteReadAlertsDesc': 'حذف جميع التنبيهات المقروءة',

      // Backup and restore translations
      'backupRestore': 'النسخ الاحتياطي والاستعادة',
      'backup': 'النسخ الاحتياطي',
      'restore': 'الاستعادة',
      'lastBackupInfo': 'معلومات آخر نسخة احتياطية',
      'backupDate': 'التاريخ',
      'backupDuration': 'المدة',
      'noBackupYet': 'لم يتم إنشاء نسخة احتياطية بعد',
      'createBackupNow': 'إنشاء نسخة احتياطية الآن',
      'fullBackup': 'نسخة احتياطية شاملة',
      'productsOnlyBackup': 'نسخة احتياطية للمنتجات فقط',
      'inventoryOnlyBackup': 'نسخة احتياطية للمخزون فقط',
      'updateBackups': 'تحديث',
      'backupType': 'النوع',
      'backupSize': 'الحجم',
      'dataCount': 'عدد البيانات',
      'share': 'مشاركة',
      'restoreFromFile': 'استعادة من ملف',
      'restoreFromCloud': 'استعادة من السحابة',
      'clearHistory': 'مسح التاريخ',
      'restoreCount': 'تم استعادة',
      'skipCount': 'تم تخطي',
      'errorCount': 'أخطاء',
      'autoBackup': 'النسخ الاحتياطي التلقائي',
      'enableAutoBackup': 'تفعيل النسخ الاحتياطي التلقائي',
      'autoBackupDesc': 'إنشاء نسخة احتياطية تلقائياً حسب الجدولة',
      'backupFrequency': 'تكرار النسخ الاحتياطي:',
      'cloudBackup': 'النسخ الاحتياطي السحابي',
      'enableCloudBackup': 'تفعيل النسخ الاحتياطي السحابي',
      'cloudBackupDesc': 'رفع النسخ الاحتياطية إلى Firebase Storage',
      'createAutoBackupNow': 'إنشاء نسخة احتياطية تلقائية الآن',
      'createAutoBackupNowDesc': 'فحص الحاجة لنسخة احتياطية تلقائية',
      'clearAllLocalBackups': 'مسح جميع النسخ الاحتياطية المحلية',
      'clearAllLocalBackupsDesc': 'حذف جميع النسخ الاحتياطية المحفوظة محلياً',

      // POS screen translations
      'saleCompleted': 'تم إتمام البيع',
      'operationNumber': 'رقم العملية',
      'totalAmount': 'المبلغ الإجمالي',
      'profit': 'الربح',
      'paymentMethod': 'طريقة الدفع',
      'discount': 'الخصم',
      'pointOfSale': 'نقطة البيع',
      'subtotal': 'المجموع الفرعي',
      'processing': 'جاري المعالجة...',
      'completeSale': 'إتمام البيع',
      'cash': 'نقدي',
      'card': 'بطاقة',
      'transfer': 'تحويل',
      'total': 'الإجمالي',

      // Quick inventory translations
      'updateInventory': 'تحديث المخزون',
      'clearInventoryDialog': 'مسح الجرد',
      'clearInventoryMessage': 'هل تريد مسح جميع العناصر الممسوحة؟',
      'clear': 'مسح',
      'quickInventory': 'الجرد السريع',
      'scannedQuantity': 'الممسوح',
      'updating': 'جاري التحديث...',
      'updateInventoryAction': 'تحديث المخزون',

      // Edit dialogs
      'generate': 'توليد',
      'editProduct': 'تعديل المنتج',

      // POS Reports
      'posReports': 'تقارير نقطة البيع',
      'salesReports': 'تقارير المبيعات',
      'inventoryReports': 'تقارير المخزون',
      'original': 'الأصلي',
      'scanned': 'الممسوح',
      'quickSell': 'بيع سريع',
      'addToCart': 'إضافة للسلة',
      'resetCart': 'إعادة تعيين',

      // Barcode scanner
      'scanInstructions': 'وجه الكاميرا نحو الباركود',

      // Error messages
      'dataLoadError': 'خطأ في تحميل البيانات',
      'criticalError': 'خطأ حرج',
      'errorId': 'المعرف',
      'errorType': 'النوع',
      'severity': 'الشدة',
      'timestamp': 'الوقت',
      'message': 'الرسالة',
      'details': 'التفاصيل',
      'userAction': 'إجراء المستخدم',

      // Print settings
      'paperSize': 'مقاس الورق',
      'thermal57': 'رول حراري 57mm',
      'thermal80': 'رول حراري 80mm',
      'a4Paper': 'A4',
      'showProductName': 'إظهار اسم المنتج',
      'showStockQuantity': 'إظهار الكمية بالمخزن',

      // Inventory options
      'edit': 'تعديل',

      // Validation messages
      'outOfStockStatus': 'نفذت الكمية',
      'productDeleted': 'تم حذف المنتج بنجاح',
      'productDeleteError': 'خطأ في حذف المنتج',
      'dateSelectionError': 'Error selecting date',
    },
    'en': <String, String>{
      'appTitle': 'Profit Calculator',
      'dashboard': 'Dashboard',
      'addProduct': 'Add Product',
      'productList': 'Product List',
      'inventory': 'Inventory',
      'storeDisplay': 'Store Display',
      'settings': 'Settings',
      'notifications': 'Notifications',
      'settingsTitle': 'Settings',
      'notificationsSection': 'Notifications',
      'enableNotifications': 'Enable notifications',
      'receiveAppNotifications': 'Receive app notifications',
      'lowStockAlerts': 'Low stock alerts',
      'dailyReminders': 'Daily reminders',
      'weeklyReminders': 'Weekly reminders',
      'remindersSection': 'Reminders',
      'actionsSection': 'Additional actions',
      'appInfo': 'App Info',
      'ok': 'OK',
      'searchInventoryHint': 'Search inventory...',
      'searchProductsHint': 'Search products...',
      'noResults': 'No matching results',
      'clearSearch': 'Clear search',
      'noInventoryItems': 'No inventory items',
      'addToInventory': 'Add to inventory',
      'loadingDashboard': 'Loading dashboard...',
      'noProfitData': 'No profit data',
      'topProfitableProducts': 'Top profitable products',
      'settingsAppBar': 'Settings',
      'loadingBestProducts': 'Loading best products...',
      'scanBarcodeButton': 'Scan Barcode',
      'generateBarcodeButton': 'Generate Barcode',
      'barcodeLabel': 'Barcode:',
      'copyBarcode': 'Barcode copied',
      'copyBarcodeTooltip': 'Copy Barcode',
      'addingItem': 'Adding...',
      'addItemToInventory': 'Add Item to Inventory',
      'clearFormButton': 'Clear Form',
      'bulkAddButton': 'Bulk Add',
      'bulkAddTitle': 'Bulk Add to Inventory',
      'inputInstructions': 'Input Instructions:',
      'inputInstructionsText':
          'Enter each product on a separate line in the following format:',
      'inputFormat':
          'Product Name | Wholesale Price | Quantity | Expiry Date (optional)',
      'inputExample': 'Example: Dell Laptop | 50000 | 5 | 2024-12-31',
      'productDataLabel': 'Product Data',
      'productDataHint': 'Enter product data here...',
      'dataPreview': 'Data Preview:',
      'analyzeData': 'Analyze Data',
      'addItems': 'Add {count} items',
      'profitLabel': 'Profit:',
      'noProducts': 'No products',
      'sortByNameAsc': 'Name (A-Z)',
      'sortByNameDesc': 'Name (Z-A)',
      'sortByPriceAsc': 'Price (Low)',
      'sortByPriceDesc': 'Price (High)',
      'sortByProfitAsc': 'Profit (Low)',
      'sortByProfitDesc': 'Profit (High)',
      'sortByDateAsc': 'Date (Old)',
      'sortByDateDesc': 'Date (New)',
      'filterAll': 'Filter: All',
      'filterHighProfit': 'Filter: High Profit',
      'filterLowProfit': 'Filter: Low Profit',
      'sortTooltip': 'Sort: {option}',
      'filterTooltip': 'Filter: {option}',
      'nameColumn': 'Name',
      'quantityColumn': 'Quantity',
      'priceColumn': 'Price',
      'dateColumn': 'Date',
      'confirmDelete': 'Confirm Delete',
      'confirmDeleteMessage':
          'Are you sure you want to delete item "{itemName}"?',
      'deleteFailed': 'Failed to delete item: {error}',
      'quantityLabel': 'Quantity: {quantity}',
      'outOfStockMessage': 'Out of stock (was: {originalQuantity})',
      'outOfStock': 'Out of stock',
      'hideDetails': 'Hide Details',
      'showDetails': 'Show Details',
      'barcodeColumn': 'Barcode',
      'copyBarcodeTooltipNew': 'Copy Barcode',
      'barcodeCopiedNew': 'Barcode copied',
      'financialDetailsNew': 'Financial Details',
      'wholesalePriceLabelNew': 'Wholesale Price',
      'allSettingsAndActionsNew': 'All Settings and Actions',
      'alertSettingsNew': 'Alert Settings',
      'manageAlertsNew': 'Manage Alerts',
      'filterAlertsNew': 'Filter Alerts',
      'displayControlNew': 'Display Control',
      'closeAllGroupsNew': 'Close All Groups',
      'openAllGroupsNew': 'Open All Groups',
      'bulkActionsNew': 'Bulk Actions',
      'cleanOldAlertsNew': 'Clean Old Alerts',
      'alertStatisticsNew': 'Alert Statistics',
      'totalNew': 'Total',
      'unreadNew': 'Unread',
      'outOfStockAlertsNew': 'Out of Stock',
      'lowStockAlertsNew': 'Low Stock',
      'expiringSoonAlertsNew': 'Expiring Soon',
      'allProductsGoodNew':
          'All your products are in good condition!\nPress the check button to review inventory',
      'checkInventoryButtonNew': 'Check Inventory',
      'excellentNew': 'Excellent! 🎉',
      'noUnreadAlertsNew': 'No unread alerts\nAll alerts have been read',
      'newCheckButtonNew': 'New Check',
      'advancedFilters': 'Advanced Filters',
      'lowProfitFilter': 'Low Profit',
      'editItem': 'Edit',
      'printBarcode': 'Print Barcode',
      'printBarcodeQuantity': 'Number of Copies',
      'printBarcodeQuantityHint': 'Enter number of copies (1-100)',
      'printBarcodeQuantityError': 'Please enter a number between 1 and 100',
      'printBarcodeQuantityDialogTitle': 'Select Number of Copies',
      'printBarcodeQuantityDialogContent':
          'How many barcodes do you want to print?',
      'printBarcodeQuantityDialogConfirm': 'Print',
      'printBarcodeQuantityDialogCancel': 'Cancel',
      'deleteItem': 'Delete Item',
      'addDate': 'Add Date:',
      'addTime': 'Add Time:',
      'expiryDate': 'Expiry Date:',
      'availableQuantity': 'Available Quantity',
      'totalValue': 'Total Value',
      'pieces': 'pieces',
      'loadingAlertsError': 'Error loading alerts',
      'markAsReadSuccess': 'Alert marked as read',
      'markAsReadError': 'Error marking alert as read',
      'deleteAlertSuccess': 'Alert deleted',
      'deleteAlertError': 'Error deleting alert',
      'confirmDeleteAlert': 'Confirm Delete',
      'confirmDeleteAlertMessage':
          'Do you want to delete alert "{productName}"?',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'applyFilterError': 'Error applying filter: {error}',
      'language': 'Language',
      'chooseLanguage': 'Choose language',
      'alertsTitle': 'Inventory Alerts',
      'alertsSubtitle': 'Monitor stock and alerts',
      'alertSettings': 'Alert settings',
      'refreshAlerts': 'Refresh alerts',
      'filterUnread': 'Unread only',
      'markAllRead': 'Mark all as read',
      'deleteRead': 'Delete read',
      'checkAlerts': 'Check alerts',
      'checkInventory': 'Check inventory',
      'loadingAlerts': 'Loading alerts...',
      'pleaseWait': 'Please wait',
      'noAlerts': 'No alerts',
      'scanBarcode': 'Scan',
      'retailPrice': 'Retail price',
      'addToInventoryButton': 'Add to inventory',
      'clearForm': 'Clear form',
      'bulkAdd': 'Bulk add',
      'productName': 'Product name',
      'wholesalePrice': 'Wholesale price',
      'quantity': 'Quantity',
      'generateBarcode': 'Generate barcode',
      'pickExpiry': 'Pick expiry date',
      'selectProduct': 'Select product',
      'chooseFromInventory': 'Choose from inventory',
      'chooseProductHint': 'Choose a product...',
      'fastBarcodeHint': 'Enter barcode for quick sale',
      'confirm': 'Confirm',
      'exitAppQuestion': 'Do you want to exit the app?',
      'yes': 'Yes',
      'no': 'No',
      'deleteReadConfirm': 'Do you want to delete all read alerts?',
      'pleaseSelectProduct': 'Please select a product',
      'noInventoryAvailableTitle': 'No products available in inventory',
      'noInventoryAvailableSubtitle': 'Please add products to inventory first',
      'selected': 'Selected',
      'remainingQuantity': 'Remaining quantity',
      'noItemWithBarcode': 'No item with this barcode',
      'addInventoryHeader': 'Add new item to inventory',
      'addInventorySubtitle': 'Enter product details to add to inventory',
      'basicInfo': 'Basic product information',
      'priceQuantity': 'Price and quantity',
      'advancedOptions': 'Advanced options',
      'barcode': 'Barcode',
      'selectedPrefix': 'Selected',
      'remainingQuantityLabel': 'Remaining quantity',
      'barcodeGeneratedSuccess': 'Barcode generated successfully',
      'barcodeError': 'Error generating barcode',
      'barcodeAlreadyUsed': 'This barcode is already used',
      'barcodeScanSuccess': 'Barcode scanned successfully',
      'barcodeScanError': 'Error scanning barcode',
      'bulkAddResult': '{ok} items added successfully, {err} failed',
      'successAdd': 'Added successfully',
      'successDelete': 'Deleted successfully',
      'generalError': 'An unexpected error occurred',
      'outOfStockWarning': 'Out of stock',
      'updateInventoryError': 'Error updating inventory quantity',
      'productNameExists': 'Product name already exists in inventory',
      'enterProductName': 'Please enter the product name',
      'invalidInventoryData': 'Invalid data entered',
      'failedToDeleteProduct': 'Failed to delete product',
      'failedToDeleteItem': 'Failed to delete item',
      'noBarcodeForItem': 'No barcode for this item',
      'printBarcodeError': 'Failed to generate/print barcode',
      'inventoryCheckedSuccess': 'Inventory checked successfully',
      'inventoryCheckError': 'Error checking inventory',
      'dashboardWelcome': 'Welcome to the comprehensive dashboard',
      'totalProductsSold': 'Total products sold',
      'totalProductsValue': 'Total products value',
      'todaySales': 'Today’s sales',
      'monthlySales': 'Monthly sales',
      'totalProfitTitle': 'Total profit',
      'averageProductPrice': 'Average product price',
      'uniqueProductNames': 'Unique product names',
      'averageProfitPerProduct': 'Average profit per product',
      'totalProfitPercentage': 'Total profit percentage',
      'averageDailySales': 'Average daily sales',
      'averageMonthlySales': 'Average monthly sales',
      'averageDailyProfit': 'Average daily profit',
      'profitLast30Days': 'Profit over the last 30 days',
      'dateFilter': 'Date filter',
      'resetFilters': 'Reset filters',
      'advancedFiltersToggle': 'Advanced filters',
      'sortByName': 'Name',
      'sortByQuantity': 'Quantity',
      'sortByPrice': 'Price',
      'sortByDate': 'Date',
      'ascending': 'Ascending',
      'descending': 'Descending',
      'totalItems': 'Total items',
      'productNameLabel': 'Product name',
      'productNameHint': 'Enter product name',
      'wholesalePriceLabel': 'Wholesale price',
      'quantityUnit': 'pcs',
      'expiryDateLabel': 'Expiry date (optional)',
      'expiryDateHint': 'Pick expiry date',
      'productUnit': 'product',
      'currencyUnit': 'Algerian Dinar',
      'recentFilter': 'Recent',
      'oldFilter': 'Old',
      'highestProfit': 'Highest Profit',
      'resetButton': 'Reset',
      'closeButton': 'Close',
      'totalProfit': 'Total Profit',
      'averageProfit': 'Average Profit',
      'highProfit': 'High Profit',
      'unknownAction': 'Unknown action',
      'actionError': 'Error executing action',
      'markAllReadSuccess': 'All alerts marked as read',
      'markAllReadError': 'Error marking alerts as read',
      'deleteReadSuccess': 'Read alerts deleted',
      'deleteReadError': 'Error deleting read alerts',
      'cleanupSuccess': 'Old alerts cleaned successfully',
      'cleanupError': 'Error cleaning old alerts',
      'settingsError': 'Error opening settings',
      'outOfStockAlert': 'Out of stock',
      'lowStockAlert': 'Reached minimum',
      'expiringAlert': 'Expiring soon',
      'toggleGroupsError': 'Error toggling groups',
      'lowProfit': 'Low profit',
      'editTooltip': 'Edit',
      'showDetailsTooltip': 'Show details',
      'hideDetailsTooltip': 'Hide details',
      'wholesalePriceShort': 'W.P',
      'retailPriceShort': 'R.P',
      'dateLabel': 'Date',
      'timeLabel': 'Time',
      'confirmDeleteProduct': 'Confirm Delete',
      'confirmDeleteProductMessage':
          'Are you sure you want to delete this product?',
      'deleteProductError': 'Failed to delete product',
      'productIdError': 'Error: Product ID not found',
      'screenInfo': 'Screen Information',
      'width': 'Width',
      'height': 'Height',
      'deviceType': 'Device Type',
      'columnsCount': 'Columns Count',
      'spacing': 'Spacing',
      'responsiveCardsTest': 'Responsive Cards Test',
      'totalProducts': 'Total Products',
      'profits': 'Profits',
      'responsiveButtonsTest': 'Responsive Buttons Test',
      'normalButton': 'Normal Button',
      'outlinedButton': 'Outlined Button',
      'iconButton': 'Icon Button',
      'responsiveTextTest': 'Responsive Text Test',
      'largeText': 'Large Text',
      'mediumText': 'Medium Text',
      'normalText': 'Normal Text',
      'smallText': 'Small Text',
      'responsiveGridTest': 'Responsive Grid Test',
      'item': 'Item',
      'mobile': 'Mobile',
      'tablet': 'Tablet',
      'desktop': 'Desktop',
      'largeDesktop': 'Large Desktop',
      'ultraWide': 'Ultra Wide',
      'dataLoadingError': 'Error loading data',
      'quantityLabelShort': 'Quantity',
      // Enhanced settings
      'welcomeToSettings': 'Welcome to Settings',
      'customizeApp': 'Customize the app according to your needs',
      'languageAndRegion': 'Language and Region',
      'notificationsSettings': 'Notifications',
      'remindersSettings': 'Reminders',
      'actionsSettings': 'Actions',
      'appInfoSettings': 'App Information',
      'enableNotificationsDesc': 'Receive app notifications',
      'lowStockAlertsDesc': 'Notifications when stock is low or out',
      'dailyRemindersDesc': 'Daily reminders to check inventory',
      'weeklyRemindersDesc': 'Weekly reminders for comprehensive review',
      'cleanupData': 'Cleanup Data',
      'cleanupDataDesc': 'Delete old notifications and unused data',
      'resetSettings': 'Reset Settings',
      'resetSettingsDesc': 'Reset all settings to default values',
      'appVersion': 'App Version',
      'developer': 'Developer',
      'lastUpdate': 'Last Update',
      'availableFeatures': 'Available Features',
      'offlineWork': 'Offline Work',
      'autoSync': 'Auto Sync',
      'localNotifications': 'Local Notifications',
      'scheduledReminders': 'Scheduled Reminders',
      'autoDataCleanup': 'Auto Data Cleanup',
      'cleanupConfirm': 'Cleanup Data',
      'cleanupConfirmMessage':
          'Do you want to delete old notifications and unused data?\n\nThis action cannot be undone.',
      'cleanup': 'Cleanup',
      'resetConfirm': 'Reset Settings',
      'resetConfirmMessage':
          'Do you want to reset all settings to default values?\n\nThis action cannot be undone.',
      'reset': 'Reset',
      'cleanupSuccessMessage': 'Data cleaned successfully',
      'cleanupErrorMessage': 'Error cleaning data: {error}',
      'resetSuccessMessage': 'Settings reset successfully',
      'resetErrorMessage': 'Error resetting settings: {error}',
      // Responsive test screen texts
      'responsiveTestTitle': 'Responsive Design Test',
      'deviceInfo': 'Device Info',
      'deviceInfoTooltip': 'Device Info',
      'breakpointsInfo': 'Breakpoints',
      'breakpointsInfoTooltip': 'Breakpoints Info',
      'screenWidth': 'Width',
      'screenHeight': 'Height',
      'isLargeScreen': 'Large Screen',
      'isSmallScreen': 'Small Screen',
      'isMediumScreen': 'Medium Screen',
      'isDesktopScreen': 'Desktop',
      'isUltraWideScreen': 'Ultra Wide',
      'gridColumns': 'Grid Columns',
      'responsiveSpacing': 'Spacing',
      'close': 'Close',
      'mobileBreakpoint': 'Mobile',
      'tabletBreakpoint': 'Tablet',
      'desktopBreakpoint': 'Desktop',
      'largeDesktopBreakpoint': 'Large Desktop',
      'ultraWideBreakpoint': 'Ultra Wide',
      'currentSize': 'Current Size',
      'classification': 'Classification',
      'deviceTypeMobile': 'Mobile',
      'deviceTypeTablet': 'Tablet',
      'deviceTypeDesktop': 'Desktop',
      'deviceTypeLargeDesktop': 'Large Desktop',
      'deviceTypeUltraWide': 'Ultra Wide',
      // Additional settings texts
      'appManagement': 'App Management and Advanced Settings',
      'connectionStatus': 'Connection Status',
      'connectionType': 'Connection Type',
      'syncStatus': 'Sync Status',
      'localData': 'Local Data',
      'available': 'Available',
      'unavailable': 'Unavailable',
      'automatic': 'Automatic',
      'manual': 'Manual',
      'developmentTeam': 'Development Team',
      'connectedToInternet': 'Connected to Internet',
      'notConnectedToInternet': 'Not Connected',
      'appConnectedMessage':
          'App is connected to the internet and working normally',
      'appOfflineMessage': 'App is working in offline mode',
      'offlineMode': 'Offline Mode',
      'retry': 'Retry',

      // Card details screen translations
      'uniqueProducts': 'Unique Products',
      'averageProductsPerDay': 'Average Products Per Day',
      'averageValuePerProduct': 'Average Value Per Product',
      'highestValueProduct': 'Highest Value Product',
      'productsSoldToday': 'Products Sold Today',
      'todayDate': 'Today\'s Date',
      'salesTrend': 'Sales Trend',
      'productsSoldThisMonth': 'Products Sold This Month',
      'currentMonth': 'Current Month',
      'profitMargin': 'Profit Margin',
      'averagePrice': 'Average Price',
      'priceRange': 'Price Range',
      'trendingUp': 'Trending Up',
      'trendingDown': 'Trending Down',
      'stable': 'Stable',
      'noData': 'No Data',

      // Alert settings dialog translations
      'alertSettingsTitle': 'Alert Settings',
      'outOfStockAlertDesc': 'Send alert when any product is out of stock',
      'lowStockAlertTitle': 'Low Stock Alert',
      'lowStockAlertDesc': 'Send alert when quantity reaches minimum threshold',
      'lowStockThreshold': 'Minimum Threshold for Alert',
      'lowStockThresholdHint': 'Enter minimum quantity threshold',
      'expiringAlertTitle': 'Expiring Alert',
      'expiringAlertDesc': 'Send alert for products about to expire',
      'daysBeforeExpiry': 'Days Before Expiry',
      'daysBeforeExpiryHint': 'Number of days before product expiry for alert',
      'additionalActions': 'Additional Actions',
      'save': 'Save',
      'updateAlerts': 'Update Alerts',
      'updateAlertsDesc': 'Update current alerts list',
      'checkAlertsAction': 'Check Alerts',
      'checkAlertsDesc': 'Check inventory and create new alerts',
      'viewAllAlerts': 'View All Alerts',
      'viewAllAlertsDesc': 'Show all alerts (read and unread)',
      'viewUnreadAlerts': 'View Unread Alerts',
      'viewUnreadAlertsDesc': 'Show unread alerts only',
      'markAllAsReadTitle': 'Mark All as Read',
      'markAllAsReadDesc': 'Mark all alerts as read',
      'deleteReadAlertsTitle': 'Delete Read Alerts',
      'deleteReadAlertsDesc': 'Delete all read alerts',

      // Backup and restore translations
      'backupRestore': 'Backup and Restore',
      'backup': 'Backup',
      'restore': 'Restore',
      'lastBackupInfo': 'Last Backup Information',
      'backupDate': 'Date',
      'backupDuration': 'Duration',
      'noBackupYet': 'No backup created yet',
      'createBackupNow': 'Create Backup Now',
      'fullBackup': 'Full Backup',
      'productsOnlyBackup': 'Products Only Backup',
      'inventoryOnlyBackup': 'Inventory Only Backup',
      'updateBackups': 'Update',
      'backupType': 'Type',
      'backupSize': 'Size',
      'dataCount': 'Data Count',
      'share': 'Share',
      'restoreFromFile': 'Restore from File',
      'restoreFromCloud': 'Restore from Cloud',
      'clearHistory': 'Clear History',
      'restoreCount': 'Restored',
      'skipCount': 'Skipped',
      'errorCount': 'Errors',
      'autoBackup': 'Auto Backup',
      'enableAutoBackup': 'Enable Auto Backup',
      'autoBackupDesc': 'Create automatic backup according to schedule',
      'backupFrequency': 'Backup Frequency:',
      'cloudBackup': 'Cloud Backup',
      'enableCloudBackup': 'Enable Cloud Backup',
      'cloudBackupDesc': 'Upload backups to Firebase Storage',
      'createAutoBackupNow': 'Create Auto Backup Now',
      'createAutoBackupNowDesc': 'Check need for automatic backup',
      'clearAllLocalBackups': 'Clear All Local Backups',
      'clearAllLocalBackupsDesc': 'Delete all locally saved backups',

      // POS screen translations
      'saleCompleted': 'Sale Completed',
      'operationNumber': 'Operation Number',
      'totalAmount': 'Total Amount',
      'profit': 'Profit',
      'paymentMethod': 'Payment Method',
      'discount': 'Discount',
      'pointOfSale': 'Point of Sale',
      'subtotal': 'Subtotal',
      'processing': 'Processing...',
      'completeSale': 'Complete Sale',
      'cash': 'Cash',
      'card': 'Card',
      'transfer': 'Transfer',
      'total': 'Total',

      // Quick inventory translations
      'updateInventory': 'Update Inventory',
      'clearInventoryDialog': 'Clear Inventory',
      'clearInventoryMessage': 'Do you want to clear all scanned items?',
      'clear': 'Clear',
      'quickInventory': 'Quick Inventory',
      'scannedQuantity': 'Scanned',
      'updating': 'Updating...',
      'updateInventoryAction': 'Update Inventory',

      // Edit dialogs
      'generate': 'Generate',
      'editProduct': 'Edit Product',

      // POS Reports
      'posReports': 'POS Reports',
      'salesReports': 'Sales Reports',
      'inventoryReports': 'Inventory Reports',
      'original': 'Original',
      'scanned': 'Scanned',
      'quickSell': 'Quick Sell',
      'addToCart': 'Add to Cart',
      'resetCart': 'Reset',

      // Barcode scanner
      'scanInstructions': 'Point camera at barcode',

      // Error messages
      'dataLoadError': 'Data loading error',
      'criticalError': 'Critical Error',
      'errorId': 'ID',
      'errorType': 'Type',
      'severity': 'Severity',
      'timestamp': 'Time',
      'message': 'Message',
      'details': 'Details',
      'userAction': 'User Action',

      // Print settings
      'paperSize': 'Paper Size',
      'thermal57': '57mm Thermal Roll',
      'thermal80': '80mm Thermal Roll',
      'a4Paper': 'A4',
      'showProductName': 'Show Product Name',
      'showStockQuantity': 'Show Stock Quantity',

      // Inventory options
      'edit': 'Edit',

      // Validation messages
      'outOfStockStatus': 'Out of Stock',
      'productDeleted': 'Product deleted successfully',
      'productDeleteError': 'Product deletion error',
      'dateSelectionError': 'Error selecting date',
    },
    'fr': <String, String>{
      'appTitle': 'Calculateur de profit',
      'dashboard': 'Tableau de bord',
      'addProduct': 'Ajouter un produit',
      'productList': 'Produits',
      'inventory': 'Inventaire',
      'storeDisplay': 'Stock',
      'settings': 'Paramètres',
      'notifications': 'Notifications',
      'settingsTitle': 'Paramètres',
      'notificationsSection': 'Notifications',
      'enableNotifications': 'Activer les notifications',
      'receiveAppNotifications': "Recevoir les notifications de l'application",
      'lowStockAlerts': 'Alertes de stock faible',
      'dailyReminders': 'Rappels quotidiens',
      'weeklyReminders': 'Rappels hebdomadaires',
      'remindersSection': 'Rappels',
      'actionsSection': 'Actions supplémentaires',
      'appInfo': "Infos de l'application",
      'ok': 'OK',
      'searchInventoryHint': "Rechercher dans l'inventaire...",
      'searchProductsHint': 'Rechercher des produits...',
      'noResults': 'Aucun résultat correspondant',
      'clearSearch': 'Effacer la recherche',
      'noInventoryItems': "Aucun article d'inventaire",
      'addToInventory': "Ajouter à l'inventaire",
      'loadingDashboard': 'Chargement du tableau de bord...',
      'noProfitData': 'Aucune donnée de profit',
      'topProfitableProducts': 'Produits les plus rentables',
      'settingsAppBar': 'Paramètres',
      'loadingBestProducts': 'Chargement des meilleurs produits...',
      'scanBarcodeButton': 'Scanner le code-barres',
      'generateBarcodeButton': 'Générer un code-barres',
      'barcodeLabel': 'Code-barres :',
      'copyBarcode': 'Code-barres copié',
      'copyBarcodeTooltip': 'Copier le code-barres',
      'addingItem': 'Ajout en cours...',
      'addItemToInventory': 'Ajouter un article à l\'inventaire',
      'clearFormButton': 'Effacer le formulaire',
      'bulkAddButton': 'Ajout en masse',
      'bulkAddTitle': 'Ajout en masse à l\'inventaire',
      'inputInstructions': 'Instructions de saisie :',
      'inputInstructionsText':
          'Entrez chaque produit sur une ligne séparée au format suivant :',
      'inputFormat':
          'Nom du produit | Prix de gros | Quantité | Date d\'expiration (optionnel)',
      'inputExample':
          'Exemple : Ordinateur portable Dell | 50000 | 5 | 2024-12-31',
      'productDataLabel': 'Données des produits',
      'productDataHint': 'Entrez les données des produits ici...',
      'dataPreview': 'Aperçu des données :',
      'analyzeData': 'Analyser les données',
      'addItems': 'Ajouter {count} articles',
      'profitLabel': 'Profit :',
      'noProducts': 'Aucun produit',
      'sortByNameAsc': 'Nom (A-Z)',
      'sortByNameDesc': 'Nom (Z-A)',
      'sortByPriceAsc': 'Prix (Bas)',
      'sortByPriceDesc': 'Prix (Élevé)',
      'sortByProfitAsc': 'Profit (Bas)',
      'sortByProfitDesc': 'Profit (Élevé)',
      'sortByDateAsc': 'Date (Ancienne)',
      'sortByDateDesc': 'Date (Récente)',
      'filterAll': 'Filtrer : Tous',
      'filterHighProfit': 'Filtrer : Profit élevé',
      'filterLowProfit': 'Filtrer : Profit bas',
      'sortTooltip': 'Trier : {option}',
      'filterTooltip': 'Filtrer : {option}',
      'nameColumn': 'Nom',
      'quantityColumn': 'Quantité',
      'priceColumn': 'Prix',
      'dateColumn': 'Date',
      'confirmDelete': 'Confirmer la suppression',
      'confirmDeleteMessage':
          'Êtes-vous sûr de vouloir supprimer l\'élément "{itemName}" ?',
      'deleteFailed': 'Échec de la suppression de l\'élément : {error}',
      'quantityLabel': 'Quantité : {quantity}',
      'outOfStockMessage': 'Rupture de stock (était : {originalQuantity})',
      'outOfStock': 'Rupture de stock',
      'hideDetails': 'Masquer les détails',
      'showDetails': 'Afficher les détails',
      'barcodeColumn': 'Code-barres',
      'copyBarcodeTooltipNew': 'Copier le code-barres',
      'barcodeCopiedNew': 'Code-barres copié',
      'financialDetailsNew': 'Détails financiers',
      'wholesalePriceLabelNew': 'Prix de gros',
      'allSettingsAndActionsNew': 'Tous les paramètres et actions',
      'alertSettingsNew': 'Paramètres d\'alerte',
      'manageAlertsNew': 'Gérer les alertes',
      'filterAlertsNew': 'Filtrer les alertes',
      'displayControlNew': 'Contrôle d\'affichage',
      'closeAllGroupsNew': 'Fermer tous les groupes',
      'openAllGroupsNew': 'Ouvrir tous les groupes',
      'bulkActionsNew': 'Actions en masse',
      'cleanOldAlertsNew': 'Nettoyer les anciennes alertes',
      'alertStatisticsNew': 'Statistiques des alertes',
      'totalNew': 'Total',
      'unreadNew': 'Non lu',
      'outOfStockAlertsNew': 'Rupture de stock',
      'lowStockAlertsNew': 'Stock faible',
      'expiringSoonAlertsNew': 'Expire bientôt',
      'allProductsGoodNew':
          'Tous vos produits sont en bon état !\nAppuyez sur le bouton de vérification pour examiner l\'inventaire',
      'checkInventoryButtonNew': 'Vérifier l\'inventaire',
      'excellentNew': 'Excellent ! 🎉',
      'noUnreadAlertsNew':
          'Aucune alerte non lue\nToutes les alertes ont été lues',
      'newCheckButtonNew': 'Nouvelle vérification',
      'advancedFilters': 'Filtres avancés',
      'lowProfitFilter': 'Profit bas',
      'editItem': 'Modifier',
      'printBarcode': 'Imprimer le code-barres',
      'printBarcodeQuantity': 'Nombre de copies',
      'printBarcodeQuantityHint': 'Entrez le nombre de copies (1-100)',
      'printBarcodeQuantityError': 'Veuillez entrer un nombre entre 1 et 100',
      'printBarcodeQuantityDialogTitle': 'Sélectionner le nombre de copies',
      'printBarcodeQuantityDialogContent':
          'Combien de codes-barres voulez-vous imprimer ?',
      'printBarcodeQuantityDialogConfirm': 'Imprimer',
      'printBarcodeQuantityDialogCancel': 'Annuler',
      'deleteItem': 'Supprimer l\'élément',
      'addDate': 'Date d\'ajout :',
      'addTime': 'Heure d\'ajout :',
      'expiryDate': 'Date d\'expiration :',
      'availableQuantity': 'Quantité disponible',
      'totalValue': 'Valeur totale',
      'pieces': 'pièces',
      'loadingAlertsError': 'Erreur lors du chargement des alertes',
      'markAsReadSuccess': 'Alerte marquée comme lue',
      'markAsReadError': 'Erreur lors du marquage de l\'alerte comme lue',
      'deleteAlertSuccess': 'Alerte supprimée',
      'deleteAlertError': 'Erreur lors de la suppression de l\'alerte',
      'confirmDeleteAlert': 'Confirmer la suppression',
      'confirmDeleteAlertMessage':
          'Voulez-vous supprimer l\'alerte "{productName}" ?',
      'cancel': 'Annuler',
      'delete': 'Supprimer',
      'applyFilterError': 'Erreur lors de l\'application du filtre : {error}',
      'language': 'Langue',
      'chooseLanguage': 'Choisir la langue',
      'alertsTitle': "Alertes d'inventaire",
      'alertsSubtitle': 'Surveiller le stock et les alertes',
      'alertSettings': 'Paramètres des alertes',
      'refreshAlerts': 'Actualiser les alertes',
      'filterUnread': 'Non lues seulement',
      'markAllRead': 'Tout marquer comme lu',
      'deleteRead': 'Supprimer les lues',
      'checkAlerts': 'Vérifier les alertes',
      'checkInventory': "Vérifier l'inventaire",
      'loadingAlerts': 'Chargement des alertes...',
      'pleaseWait': 'Veuillez patienter',
      'noAlerts': 'Aucune alerte',
      'scanBarcode': 'Scanner',
      'retailPrice': 'Prix de détail',
      'addToInventoryButton': "Ajouter à l'inventaire",
      'clearForm': 'Effacer le formulaire',
      'bulkAdd': 'Ajout multiple',
      'productName': 'Nom du produit',
      'wholesalePrice': 'Prix de gros',
      'quantity': 'Quantité',
      'generateBarcode': 'Générer un code-barres',
      'pickExpiry': "Choisir la date d'expiration",
      'selectProduct': 'Sélectionner un produit',
      'chooseFromInventory': "Choisissez dans l'inventaire",
      'chooseProductHint': 'Choisissez un produit...',
      'fastBarcodeHint': 'Entrez le code-barres pour une vente rapide',
      'confirm': 'Confirmer',
      'exitAppQuestion': "Souhaitez-vous quitter l'application ?",
      'yes': 'Oui',
      'no': 'Non',
      'deleteReadConfirm': 'Supprimer toutes les alertes lues ?',
      'pleaseSelectProduct': 'Veuillez sélectionner un produit',
      'noInventoryAvailableTitle': "Aucun produit disponible dans l'inventaire",
      'noInventoryAvailableSubtitle':
          "Veuillez d'abord ajouter des produits à l'inventaire",
      'selected': 'Sélectionné',
      'remainingQuantity': 'Quantité restante',
      'noItemWithBarcode': 'Aucun article avec ce code-barres',
      'addInventoryHeader': "Ajouter un nouvel article à l'inventaire",
      'addInventorySubtitle':
          "Saisissez les détails du produit pour l'ajouter à l'inventaire",
      'basicInfo': 'Informations de base sur le produit',
      'priceQuantity': 'Prix et quantité',
      'advancedOptions': 'Options avancées',
      'barcode': 'Code-barres',
      'selectedPrefix': 'Sélectionné',
      'remainingQuantityLabel': 'Quantité restante',
      'barcodeGeneratedSuccess': 'Code-barres généré avec succès',
      'barcodeError': 'Erreur lors de la génération du code-barres',
      'barcodeAlreadyUsed': 'Ce code-barres est déjà utilisé',
      'barcodeScanSuccess': 'Code-barres scanné avec succès',
      'barcodeScanError': 'Erreur lors du scan du code-barres',
      'bulkAddResult': '{ok} éléments ajoutés avec succès, {err} ont échoué',
      'successAdd': 'Ajouté avec succès',
      'successDelete': 'Supprimé avec succès',
      'generalError': 'Une erreur inattendue est survenue',
      'outOfStockWarning': 'Rupture de stock',
      'updateInventoryError':
          "Erreur de mise à jour de la quantité d'inventaire",
      'productNameExists': "Le nom du produit existe déjà dans l'inventaire",
      'enterProductName': 'Veuillez saisir le nom du produit',
      'invalidInventoryData': 'Données saisies non valides',
      'failedToDeleteProduct': 'Échec de la suppression du produit',
      'failedToDeleteItem': "Échec de la suppression de l'article",
      'noBarcodeForItem': 'Aucun code-barres pour cet article',
      'printBarcodeError': 'Échec de la génération/impression du code-barres',
      'inventoryCheckedSuccess': 'Inventaire vérifié avec succès',
      'inventoryCheckError': "Erreur lors de la vérification de l'inventaire",
      'dashboardWelcome': 'Bienvenue sur le tableau de bord',
      'totalProductsSold': 'Produits vendus au total',
      'totalProductsValue': 'Valeur totale des produits',
      'todaySales': "Ventes d'aujourd'hui",
      'monthlySales': 'Ventes mensuelles',
      'totalProfitTitle': 'Profit total',
      'averageProductPrice': 'Prix moyen du produit',
      'uniqueProductNames': 'Produits uniques',
      'averageProfitPerProduct': 'Profit moyen par produit',
      'totalProfitPercentage': 'Pourcentage de profit total',
      'averageDailySales': 'Ventes quotidiennes moyennes',
      'averageMonthlySales': 'Ventes mensuelles moyennes',
      'averageDailyProfit': 'Profit quotidien moyen',
      'profitLast30Days': 'Profit sur les 30 derniers jours',
      'dateFilter': 'Filtre de date',
      'resetFilters': 'Réinitialiser les filtres',
      'advancedFiltersToggle': 'Filtres avancés',
      'sortByName': 'Nom',
      'sortByQuantity': 'Quantité',
      'sortByPrice': 'Prix',
      'sortByDate': 'Date',
      'ascending': 'Croissant',
      'descending': 'Décroissant',
      'totalItems': 'Articles au total',
      'productNameLabel': 'Nom du produit',
      'productNameHint': 'Saisir le nom du produit',
      'wholesalePriceLabel': 'Prix de gros',
      'quantityUnit': 'pcs',
      'expiryDateLabel': "Date d'expiration (optionnel)",
      'expiryDateHint': "Choisir la date d'expiration",
      'productUnit': 'produit',
      'currencyUnit': 'Dinar algérien',
      'recentFilter': 'Récent',
      'oldFilter': 'Ancien',
      'highestProfit': 'Profit le plus élevé',
      'resetButton': 'Réinitialiser',
      'closeButton': 'Fermer',
      'totalProfit': 'Profit total',
      'averageProfit': 'Profit moyen',
      'highProfit': 'Profit élevé',
      'unknownAction': 'Action inconnue',
      'actionError': 'Erreur lors de l\'exécution de l\'action',
      'markAllReadSuccess': 'Toutes les alertes marquées comme lues',
      'markAllReadError': 'Erreur lors du marquage des alertes comme lues',
      'deleteReadSuccess': 'Alertes lues supprimées',
      'deleteReadError': 'Erreur lors de la suppression des alertes lues',
      'cleanupSuccess': 'Anciennes alertes nettoyées avec succès',
      'cleanupError': 'Erreur lors du nettoyage des anciennes alertes',
      'settingsError': 'Erreur lors de l\'ouverture des paramètres',
      'outOfStockAlert': 'Rupture de stock',
      'lowStockAlert': 'Atteint le minimum',
      'expiringAlert': 'Expire bientôt',
      'toggleGroupsError': 'Erreur lors du basculement des groupes',
      'lowProfit': 'Profit bas',
      'editTooltip': 'Modifier',
      'showDetailsTooltip': 'Afficher les détails',
      'hideDetailsTooltip': 'Masquer les détails',
      'wholesalePriceShort': 'P.G',
      'retailPriceShort': 'P.D',
      'dateLabel': 'Date',
      'timeLabel': 'Heure',
      'confirmDeleteProduct': 'Confirmer la suppression',
      'confirmDeleteProductMessage':
          'Êtes-vous sûr de vouloir supprimer ce produit ?',
      'deleteProductError': 'Échec de la suppression du produit',
      'productIdError': 'Erreur : ID du produit introuvable',
      'screenInfo': 'Informations sur l\'écran',
      'width': 'Largeur',
      'height': 'Hauteur',
      'deviceType': 'Type d\'appareil',
      'columnsCount': 'Nombre de colonnes',
      'spacing': 'Espacement',
      'responsiveCardsTest': 'Test des cartes responsives',
      'totalProducts': 'Produits totaux',
      'profits': 'Profits',
      'responsiveButtonsTest': 'Test des boutons responsives',
      'normalButton': 'Bouton normal',
      'outlinedButton': 'Bouton contour',
      'iconButton': 'Bouton avec icône',
      'responsiveTextTest': 'Test du texte responsive',
      'largeText': 'Texte large',
      'mediumText': 'Texte moyen',
      'normalText': 'Texte normal',
      'smallText': 'Petit texte',
      'responsiveGridTest': 'Test de grille responsive',
      'item': 'Élément',
      'mobile': 'Mobile',
      'tablet': 'Tablette',
      'desktop': 'Bureau',
      'largeDesktop': 'Grand bureau',
      'ultraWide': 'Ultra large',
      'dataLoadingError': 'Erreur de chargement des données',
      'quantityLabelShort': 'Quantité',
      // Paramètres améliorés
      'welcomeToSettings': 'Bienvenue dans les Paramètres',
      'customizeApp': 'Personnalisez l\'application selon vos besoins',
      'languageAndRegion': 'Langue et Région',
      'notificationsSettings': 'Notifications',
      'remindersSettings': 'Rappels',
      'actionsSettings': 'Actions',
      'appInfoSettings': 'Informations de l\'Application',
      'enableNotificationsDesc': 'Recevoir les notifications de l\'application',
      'lowStockAlertsDesc': 'Notifications quand le stock est faible ou épuisé',
      'dailyRemindersDesc': 'Rappels quotidiens pour vérifier l\'inventaire',
      'weeklyRemindersDesc': 'Rappels hebdomadaires pour une révision complète',
      'cleanupData': 'Nettoyer les Données',
      'cleanupDataDesc':
          'Supprimer les anciennes notifications et données inutilisées',
      'resetSettings': 'Réinitialiser les Paramètres',
      'resetSettingsDesc':
          'Réinitialiser tous les paramètres aux valeurs par défaut',
      'appVersion': 'Version de l\'Application',
      'developer': 'Développeur',
      'lastUpdate': 'Dernière Mise à Jour',
      'availableFeatures': 'Fonctionnalités Disponibles',
      'offlineWork': 'Travail Hors Ligne',
      'autoSync': 'Synchronisation Automatique',
      'localNotifications': 'Notifications Locales',
      'scheduledReminders': 'Rappels Programmés',
      'autoDataCleanup': 'Nettoyage Automatique des Données',
      'cleanupConfirm': 'Nettoyer les Données',
      'cleanupConfirmMessage':
          'Voulez-vous supprimer les anciennes notifications et données inutilisées ?\n\nCette action ne peut pas être annulée.',
      'cleanup': 'Nettoyer',
      'resetConfirm': 'Réinitialiser les Paramètres',
      'resetConfirmMessage':
          'Voulez-vous réinitialiser tous les paramètres aux valeurs par défaut ?\n\nCette action ne peut pas être annulée.',
      'reset': 'Réinitialiser',
      'cleanupSuccessMessage': 'Données nettoyées avec succès',
      'cleanupErrorMessage': 'Erreur lors du nettoyage des données : {error}',
      'resetSuccessMessage': 'Paramètres réinitialisés avec succès',
      'resetErrorMessage':
          'Erreur lors de la réinitialisation des paramètres : {error}',
      // Textes de l'écran de test responsive
      'responsiveTestTitle': 'Test de Design Responsive',
      'deviceInfo': 'Informations sur l\'Appareil',
      'deviceInfoTooltip': 'Informations sur l\'Appareil',
      'breakpointsInfo': 'Points de Rupture',
      'breakpointsInfoTooltip': 'Informations sur les Points de Rupture',
      'screenWidth': 'Largeur',
      'screenHeight': 'Hauteur',
      'isLargeScreen': 'Grand Écran',
      'isSmallScreen': 'Petit Écran',
      'isMediumScreen': 'Écran Moyen',
      'isDesktopScreen': 'Bureau',
      'isUltraWideScreen': 'Ultra Large',
      'gridColumns': 'Colonnes de Grille',
      'responsiveSpacing': 'Espacement',
      'close': 'Fermer',
      'mobileBreakpoint': 'Mobile',
      'tabletBreakpoint': 'Tablette',
      'desktopBreakpoint': 'Bureau',
      'largeDesktopBreakpoint': 'Grand Bureau',
      'ultraWideBreakpoint': 'Ultra Large',
      'currentSize': 'Taille Actuelle',
      'classification': 'Classification',
      'deviceTypeMobile': 'Mobile',
      'deviceTypeTablet': 'Tablette',
      'deviceTypeDesktop': 'Bureau',
      'deviceTypeLargeDesktop': 'Grand Bureau',
      'deviceTypeUltraWide': 'Ultra Large',
      // Textes supplémentaires pour les paramètres
      'appManagement': 'Gestion de l\'App et Paramètres Avancés',
      'connectionStatus': 'Statut de Connexion',
      'connectionType': 'Type de Connexion',
      'syncStatus': 'Statut de Synchronisation',
      'localData': 'Données Locales',
      'available': 'Disponible',
      'unavailable': 'Indisponible',
      'automatic': 'Automatique',
      'manual': 'Manuel',
      'developmentTeam': 'Équipe de Développement',
      'connectedToInternet': 'Connecté à Internet',
      'notConnectedToInternet': 'Non Connecté',
      'appConnectedMessage':
          'L\'app est connectée à Internet et fonctionne normalement',
      'appOfflineMessage': 'L\'app fonctionne en mode hors ligne',
      'offlineMode': 'Mode Hors Ligne',
      'retry': 'Réessayer',

      // Card details screen translations
      'uniqueProducts': 'Produits Uniques',
      'averageProductsPerDay': 'Produits Moyens Par Jour',
      'averageValuePerProduct': 'Valeur Moyenne Par Produit',
      'highestValueProduct': 'Produit de Plus Haute Valeur',
      'productsSoldToday': 'Produits Vendus Aujourd\'hui',
      'todayDate': 'Date d\'Aujourd\'hui',
      'salesTrend': 'Tendance des Ventes',
      'productsSoldThisMonth': 'Produits Vendus Ce Mois',
      'currentMonth': 'Mois Actuel',
      'profitMargin': 'Marge de Profit',
      'averagePrice': 'Prix Moyen',
      'priceRange': 'Gamme de Prix',
      'trendingUp': 'En Hausse',
      'trendingDown': 'En Baisse',
      'stable': 'Stable',
      'noData': 'Aucune Donnée',

      // Alert settings dialog translations
      'alertSettingsTitle': 'Paramètres d\'Alerte',
      'outOfStockAlertDesc':
          'Envoyer une alerte quand un produit est en rupture',
      'lowStockAlertTitle': 'Alerte de Stock Faible',
      'lowStockAlertDesc':
          'Envoyer une alerte quand la quantité atteint le seuil minimum',
      'lowStockThreshold': 'Seuil Minimum pour Alerte',
      'lowStockThresholdHint': 'Entrer le seuil minimum de quantité',
      'expiringAlertTitle': 'Alerte d\'Expiration',
      'expiringAlertDesc':
          'Envoyer une alerte pour les produits sur le point d\'expirer',
      'daysBeforeExpiry': 'Jours Avant Expiration',
      'daysBeforeExpiryHint':
          'Nombre de jours avant l\'expiration du produit pour l\'alerte',
      'additionalActions': 'Actions Supplémentaires',
      'save': 'Sauvegarder',
      'updateAlerts': 'Mettre à Jour les Alertes',
      'updateAlertsDesc': 'Mettre à jour la liste des alertes actuelles',
      'checkAlertsAction': 'Vérifier les Alertes',
      'checkAlertsDesc': 'Vérifier l\'inventaire et créer de nouvelles alertes',
      'viewAllAlerts': 'Voir Toutes les Alertes',
      'viewAllAlertsDesc': 'Afficher toutes les alertes (lues et non lues)',
      'viewUnreadAlerts': 'Voir les Alertes Non Lues',
      'viewUnreadAlertsDesc': 'Afficher seulement les alertes non lues',
      'markAllAsReadTitle': 'Marquer Tout comme Lu',
      'markAllAsReadDesc': 'Marquer toutes les alertes comme lues',
      'deleteReadAlertsTitle': 'Supprimer les Alertes Lues',
      'deleteReadAlertsDesc': 'Supprimer toutes les alertes lues',

      // Backup and restore translations
      'backupRestore': 'Sauvegarde et Restauration',
      'backup': 'Sauvegarde',
      'restore': 'Restauration',
      'lastBackupInfo': 'Informations de la Dernière Sauvegarde',
      'backupDate': 'Date',
      'backupDuration': 'Durée',
      'noBackupYet': 'Aucune sauvegarde créée encore',
      'createBackupNow': 'Créer Sauvegarde Maintenant',
      'fullBackup': 'Sauvegarde Complète',
      'productsOnlyBackup': 'Sauvegarde Produits Seulement',
      'inventoryOnlyBackup': 'Sauvegarde Inventaire Seulement',
      'updateBackups': 'Mettre à Jour',
      'backupType': 'Type',
      'backupSize': 'Taille',
      'dataCount': 'Nombre de Données',
      'share': 'Partager',
      'restoreFromFile': 'Restaurer depuis Fichier',
      'restoreFromCloud': 'Restaurer depuis le Cloud',
      'clearHistory': 'Effacer l\'Historique',
      'restoreCount': 'Restauré',
      'skipCount': 'Ignoré',
      'errorCount': 'Erreurs',
      'autoBackup': 'Sauvegarde Automatique',
      'enableAutoBackup': 'Activer la Sauvegarde Automatique',
      'autoBackupDesc':
          'Créer une sauvegarde automatique selon la planification',
      'backupFrequency': 'Fréquence de Sauvegarde:',
      'cloudBackup': 'Sauvegarde Cloud',
      'enableCloudBackup': 'Activer la Sauvegarde Cloud',
      'cloudBackupDesc': 'Uploader les sauvegardes vers Firebase Storage',
      'createAutoBackupNow': 'Créer Sauvegarde Auto Maintenant',
      'createAutoBackupNowDesc':
          'Vérifier le besoin d\'une sauvegarde automatique',
      'clearAllLocalBackups': 'Effacer Toutes les Sauvegardes Locales',
      'clearAllLocalBackupsDesc': 'Supprimer toutes les sauvegardes locales',

      // POS screen translations
      'saleCompleted': 'Vente Terminée',
      'operationNumber': 'Numéro d\'Opération',
      'totalAmount': 'Montant Total',
      'profit': 'Profit',
      'paymentMethod': 'Méthode de Paiement',
      'discount': 'Remise',
      'pointOfSale': 'Point de Vente',
      'subtotal': 'Sous-total',
      'processing': 'Traitement...',
      'completeSale': 'Finaliser la Vente',
      'cash': 'Espèces',
      'card': 'Carte',
      'transfer': 'Virement',
      'total': 'Total',

      // Quick inventory translations
      'updateInventory': 'Mettre à Jour l\'Inventaire',
      'clearInventoryDialog': 'Effacer l\'Inventaire',
      'clearInventoryMessage': 'Voulez-vous effacer tous les articles scannés?',
      'clear': 'Effacer',
      'quickInventory': 'Inventaire Rapide',
      'scannedQuantity': 'Scanné',
      'updating': 'Mise à jour...',
      'updateInventoryAction': 'Mettre à Jour l\'Inventaire',

      // Edit dialogs
      'generate': 'Générer',
      'editProduct': 'Modifier le Produit',

      // POS Reports
      'posReports': 'Rapports POS',
      'salesReports': 'Rapports de Ventes',
      'inventoryReports': 'Rapports d\'Inventaire',
      'original': 'Original',
      'scanned': 'Scanné',
      'quickSell': 'Vente Rapide',
      'addToCart': 'Ajouter au Panier',
      'resetCart': 'Réinitialiser',

      // Barcode scanner
      'scanInstructions': 'Pointer la caméra vers le code-barres',

      // Error messages
      'dataLoadError': 'Erreur de chargement des données',
      'criticalError': 'Erreur Critique',
      'errorId': 'ID',
      'errorType': 'Type',
      'severity': 'Sévérité',
      'timestamp': 'Heure',
      'message': 'Message',
      'details': 'Détails',
      'userAction': 'Action Utilisateur',

      // Print settings
      'paperSize': 'Taille du Papier',
      'thermal57': 'Rouleau Thermique 57mm',
      'thermal80': 'Rouleau Thermique 80mm',
      'a4Paper': 'A4',
      'showProductName': 'Afficher le Nom du Produit',
      'showStockQuantity': 'Afficher la Quantité en Stock',

      // Inventory options
      'edit': 'Modifier',

      // Validation messages
      'outOfStockStatus': 'En Rupture',
      'productDeleted': 'Produit supprimé avec succès',
      'productDeleteError': 'Erreur de suppression du produit',
      'dateSelectionError': 'Erreur de sélection de date',
    },
  };

  String _t(String key) =>
      _localizedValues[locale.languageCode]?[key] ??
      _localizedValues['en']![key] ??
      key;

  String get appTitle => _t('appTitle');
  String get dashboard => _t('dashboard');
  String get addProduct => _t('addProduct');
  String get productList => _t('productList');
  String get inventory => _t('inventory');
  String get storeDisplay => _t('storeDisplay');
  String get settings => _t('settings');
  String get notifications => _t('notifications');
  String get settingsTitle => _t('settingsTitle');
  String get notificationsSection => _t('notificationsSection');
  String get enableNotifications => _t('enableNotifications');
  String get receiveAppNotifications => _t('receiveAppNotifications');
  String get lowStockAlerts => _t('lowStockAlerts');
  String get dailyReminders => _t('dailyReminders');
  String get weeklyReminders => _t('weeklyReminders');
  String get remindersSection => _t('remindersSection');
  String get actionsSection => _t('actionsSection');
  String get appInfo => _t('appInfo');
  String get ok => _t('ok');
  String get searchInventoryHint => _t('searchInventoryHint');
  String get searchProductsHint => _t('searchProductsHint');
  String get noResults => _t('noResults');
  String get clearSearch => _t('clearSearch');
  String get noInventoryItems => _t('noInventoryItems');
  String get addToInventory => _t('addToInventory');
  String get loadingDashboard => _t('loadingDashboard');
  String get noProfitData => _t('noProfitData');
  String get topProfitableProducts => _t('topProfitableProducts');
  String get settingsAppBar => _t('settingsAppBar');
  String get language => _t('language');
  String get chooseLanguage => _t('chooseLanguage');
  String get alertsTitle => _t('alertsTitle');
  String get alertsSubtitle => _t('alertsSubtitle');
  String get alertSettings => _t('alertSettings');
  String get refreshAlerts => _t('refreshAlerts');
  String get filterAll => _t('filterAll');
  String get filterUnread => _t('filterUnread');
  String get markAllRead => _t('markAllRead');
  String get deleteRead => _t('deleteRead');
  String get checkAlerts => _t('checkAlerts');
  String get checkInventory => _t('checkInventory');
  String get loadingAlerts => _t('loadingAlerts');
  String get pleaseWait => _t('pleaseWait');
  String get noAlerts => _t('noAlerts');
  String get scanBarcode => _t('scanBarcode');
  String get retailPrice => _t('retailPrice');
  String get addToInventoryButton => _t('addToInventoryButton');
  String get clearForm => _t('clearForm');
  String get bulkAdd => _t('bulkAdd');
  String get productName => _t('productName');
  String get wholesalePrice => _t('wholesalePrice');
  String get quantity => _t('quantity');
  String get expiryDate => _t('expiryDate');
  String get generateBarcode => _t('generateBarcode');
  String get pickExpiry => _t('pickExpiry');
  String get selectProduct => _t('selectProduct');
  String get chooseFromInventory => _t('chooseFromInventory');
  String get chooseProductHint => _t('chooseProductHint');
  String get fastBarcodeHint => _t('fastBarcodeHint');
  String get confirm => _t('confirm');
  String get exitAppQuestion => _t('exitAppQuestion');
  String get yes => _t('yes');
  String get no => _t('no');
  String get deleteReadConfirm => _t('deleteReadConfirm');
  String get pleaseSelectProduct => _t('pleaseSelectProduct');
  String get noInventoryAvailableTitle => _t('noInventoryAvailableTitle');
  String get noInventoryAvailableSubtitle => _t('noInventoryAvailableSubtitle');
  String get selected => _t('selected');
  String get remainingQuantity => _t('remainingQuantity');
  String get noItemWithBarcode => _t('noItemWithBarcode');
  String get addInventoryHeader => _t('addInventoryHeader');
  String get addInventorySubtitle => _t('addInventorySubtitle');
  String get basicInfo => _t('basicInfo');
  String get priceQuantity => _t('priceQuantity');
  String get advancedOptions => _t('advancedOptions');
  String get barcode => _t('barcode');
  String get selectedPrefix => _t('selectedPrefix');
  String get remainingQuantityLabel => _t('remainingQuantityLabel');
  String get barcodeGeneratedSuccess => _t('barcodeGeneratedSuccess');
  String get barcodeError => _t('barcodeError');
  String get barcodeAlreadyUsed => _t('barcodeAlreadyUsed');
  String get barcodeScanSuccess => _t('barcodeScanSuccess');
  String get barcodeScanError => _t('barcodeScanError');
  String bulkAddResult(int ok, int err) => _t('bulkAddResult')
      .replaceAll('{ok}', ok.toString())
      .replaceAll('{err}', err.toString());
  String get successAdd => _t('successAdd');
  String get successDelete => _t('successDelete');
  String get generalError => _t('generalError');
  String get outOfStockWarning => _t('outOfStockWarning');

  // New translations
  String get loadingBestProducts => _t('loadingBestProducts');
  String get scanBarcodeButton => _t('scanBarcodeButton');
  String get generateBarcodeButton => _t('generateBarcodeButton');
  String get barcodeLabel => _t('barcodeLabel');
  String get copyBarcode => _t('copyBarcode');
  String get copyBarcodeTooltip => _t('copyBarcodeTooltip');
  String get addingItem => _t('addingItem');
  String get addItemToInventory => _t('addItemToInventory');
  String get clearFormButton => _t('clearFormButton');
  String get bulkAddButton => _t('bulkAddButton');
  String get bulkAddTitle => _t('bulkAddTitle');
  String get inputInstructions => _t('inputInstructions');
  String get inputInstructionsText => _t('inputInstructionsText');
  String get inputFormat => _t('inputFormat');
  String get inputExample => _t('inputExample');
  String get productDataLabel => _t('productDataLabel');
  String get productDataHint => _t('productDataHint');
  String get dataPreview => _t('dataPreview');
  String get analyzeData => _t('analyzeData');
  String addItems(int count) =>
      _t('addItems').replaceAll('{count}', count.toString());
  String get profitLabel => _t('profitLabel');

  // Additional translations for all tabs
  String get noProducts => _t('noProducts');
  String get sortByNameAsc => _t('sortByNameAsc');
  String get sortByNameDesc => _t('sortByNameDesc');
  String get sortByPriceAsc => _t('sortByPriceAsc');
  String get sortByPriceDesc => _t('sortByPriceDesc');
  String get sortByProfitAsc => _t('sortByProfitAsc');
  String get sortByProfitDesc => _t('sortByProfitDesc');
  String get sortByDateAsc => _t('sortByDateAsc');
  String get sortByDateDesc => _t('sortByDateDesc');
  String get filterHighProfit => _t('filterHighProfit');
  String get filterLowProfit => _t('filterLowProfit');
  String sortTooltip(String option) =>
      _t('sortTooltip').replaceAll('{option}', option);
  String filterTooltip(String option) =>
      _t('filterTooltip').replaceAll('{option}', option);
  String get nameColumn => _t('nameColumn');
  String get quantityColumn => _t('quantityColumn');
  String get priceColumn => _t('priceColumn');
  String get dateColumn => _t('dateColumn');
  String get confirmDelete => _t('confirmDelete');
  String confirmDeleteMessage(String itemName) =>
      _t('confirmDeleteMessage').replaceAll('{itemName}', itemName);
  String deleteFailed(String error) =>
      _t('deleteFailed').replaceAll('{error}', error);
  String quantityLabel(int quantity) =>
      _t('quantityLabel').replaceAll('{quantity}', quantity.toString());
  String outOfStockMessage(int originalQuantity) => _t('outOfStockMessage')
      .replaceAll('{originalQuantity}', originalQuantity.toString());
  String get outOfStock => _t('outOfStock');
  String get hideDetails => _t('hideDetails');
  String get showDetails => _t('showDetails');
  String get barcodeColumn => _t('barcodeColumn');
  String get copyBarcodeTooltipNew => _t('copyBarcodeTooltipNew');
  String get barcodeCopiedNew => _t('barcodeCopiedNew');
  String get financialDetailsNew => _t('financialDetailsNew');
  String get wholesalePriceLabelNew => _t('wholesalePriceLabelNew');
  String get allSettingsAndActionsNew => _t('allSettingsAndActionsNew');
  String get alertSettingsNew => _t('alertSettingsNew');
  String get manageAlertsNew => _t('manageAlertsNew');
  String get filterAlertsNew => _t('filterAlertsNew');
  String get displayControlNew => _t('displayControlNew');
  String get closeAllGroupsNew => _t('closeAllGroupsNew');
  String get openAllGroupsNew => _t('openAllGroupsNew');
  String get bulkActionsNew => _t('bulkActionsNew');
  String get cleanOldAlertsNew => _t('cleanOldAlertsNew');
  String get alertStatisticsNew => _t('alertStatisticsNew');
  String get totalNew => _t('totalNew');
  String get unreadNew => _t('unreadNew');
  String get outOfStockAlertsNew => _t('outOfStockAlertsNew');
  String get lowStockAlertsNew => _t('lowStockAlertsNew');
  String get expiringSoonAlertsNew => _t('expiringSoonAlertsNew');
  String get allProductsGoodNew => _t('allProductsGoodNew');
  String get checkInventoryButtonNew => _t('checkInventoryButtonNew');
  String get excellentNew => _t('excellentNew');
  String get noUnreadAlertsNew => _t('noUnreadAlertsNew');
  String get newCheckButtonNew => _t('newCheckButtonNew');
  String get advancedFilters => _t('advancedFilters');
  String get lowProfitFilter => _t('lowProfitFilter');
  String get editItem => _t('editItem');
  String get printBarcode => _t('printBarcode');
  String get printBarcodeQuantity => _t('printBarcodeQuantity');
  String get printBarcodeQuantityHint => _t('printBarcodeQuantityHint');
  String get printBarcodeQuantityError => _t('printBarcodeQuantityError');
  String get printBarcodeQuantityDialogTitle =>
      _t('printBarcodeQuantityDialogTitle');
  String get printBarcodeQuantityDialogContent =>
      _t('printBarcodeQuantityDialogContent');
  String get printBarcodeQuantityDialogConfirm =>
      _t('printBarcodeQuantityDialogConfirm');
  String get printBarcodeQuantityDialogCancel =>
      _t('printBarcodeQuantityDialogCancel');
  String get deleteItem => _t('deleteItem');
  String get addDate => _t('addDate');
  String get addTime => _t('addTime');
  String get availableQuantity => _t('availableQuantity');
  String get totalValue => _t('totalValue');
  String get pieces => _t('pieces');
  String get loadingAlertsError => _t('loadingAlertsError');
  String get markAsReadSuccess => _t('markAsReadSuccess');
  String get markAsReadError => _t('markAsReadError');
  String get deleteAlertSuccess => _t('deleteAlertSuccess');
  String get deleteAlertError => _t('deleteAlertError');
  String get confirmDeleteAlert => _t('confirmDeleteAlert');
  String confirmDeleteAlertMessage(String productName) =>
      _t('confirmDeleteAlertMessage').replaceAll('{productName}', productName);
  String get cancel => _t('cancel');
  String get delete => _t('delete');
  String applyFilterError(String error) =>
      _t('applyFilterError').replaceAll('{error}', error);
  String get updateInventoryError => _t('updateInventoryError');
  String get productNameExists => _t('productNameExists');
  String get enterProductName => _t('enterProductName');
  String get invalidInventoryData => _t('invalidInventoryData');
  String get failedToDeleteProduct => _t('failedToDeleteProduct');
  String get failedToDeleteItem => _t('failedToDeleteItem');
  String get noBarcodeForItem => _t('noBarcodeForItem');
  String get printBarcodeError => _t('printBarcodeError');
  String get inventoryCheckedSuccess => _t('inventoryCheckedSuccess');
  String get inventoryCheckError => _t('inventoryCheckError');
  String get dashboardWelcome => _t('dashboardWelcome');
  String get totalProductsSold => _t('totalProductsSold');
  String get totalProductsValue => _t('totalProductsValue');
  String get todaySales => _t('todaySales');
  String get monthlySales => _t('monthlySales');
  String get totalProfitTitle => _t('totalProfitTitle');
  String get averageProductPrice => _t('averageProductPrice');
  String get uniqueProductNames => _t('uniqueProductNames');
  String get averageProfitPerProduct => _t('averageProfitPerProduct');
  String get totalProfitPercentageTitle => _t('totalProfitPercentage');
  String get averageDailySales => _t('averageDailySales');
  String get averageMonthlySales => _t('averageMonthlySales');
  String get averageDailyProfit => _t('averageDailyProfit');
  String get profitLast30Days => _t('profitLast30Days');
  String get dateFilter => _t('dateFilter');
  String get resetFilters => _t('resetFilters');
  String get advancedFiltersToggle => _t('advancedFiltersToggle');
  String get sortByName => _t('sortByName');
  String get sortByQuantity => _t('sortByQuantity');
  String get sortByPrice => _t('sortByPrice');
  String get sortByDate => _t('sortByDate');
  String get ascending => _t('ascending');
  String get descending => _t('descending');
  String get totalItems => _t('totalItems');
  String get productNameLabel => _t('productNameLabel');
  String get productNameHint => _t('productNameHint');
  String get wholesalePriceLabel => _t('wholesalePriceLabel');
  String get quantityUnit => _t('quantityUnit');
  String get expiryDateLabel => _t('expiryDateLabel');
  String get expiryDateHint => _t('expiryDateHint');
  String get productUnit => _t('productUnit');
  String get currencyUnit => _t('currencyUnit');
  String get recentFilter => _t('recentFilter');
  String get oldFilter => _t('oldFilter');
  String get highestProfit => _t('highestProfit');
  String get resetButton => _t('resetButton');
  String get closeButton => _t('closeButton');
  String get totalProfit => _t('totalProfit');
  String get averageProfit => _t('averageProfit');
  String get highProfit => _t('highProfit');
  String get unknownAction => _t('unknownAction');
  String actionError(String error) =>
      _t('actionError').replaceAll('{error}', error);
  String get markAllReadSuccess => _t('markAllReadSuccess');
  String get markAllReadError => _t('markAllReadError');
  String get deleteReadSuccess => _t('deleteReadSuccess');
  String get deleteReadError => _t('deleteReadError');
  String get cleanupSuccess => _t('cleanupSuccess');
  String get cleanupError => _t('cleanupError');
  String settingsError(String error) =>
      _t('settingsError').replaceAll('{error}', error);
  String get outOfStockAlert => _t('outOfStockAlert');
  String get lowStockAlert => _t('lowStockAlert');
  String get expiringAlert => _t('expiringAlert');
  String toggleGroupsError(String error) =>
      _t('toggleGroupsError').replaceAll('{error}', error);
  String get lowProfit => _t('lowProfit');
  String get editTooltip => _t('editTooltip');
  String get showDetailsTooltip => _t('showDetailsTooltip');
  String get hideDetailsTooltip => _t('hideDetailsTooltip');
  String get wholesalePriceShort => _t('wholesalePriceShort');
  String get retailPriceShort => _t('retailPriceShort');
  String get dateLabel => _t('dateLabel');
  String get timeLabel => _t('timeLabel');
  String get confirmDeleteProduct => _t('confirmDeleteProduct');
  String get confirmDeleteProductMessage => _t('confirmDeleteProductMessage');
  String deleteProductError(String error) =>
      _t('deleteProductError').replaceAll('{error}', error);
  String get productIdError => _t('productIdError');
  String get screenInfo => _t('screenInfo');
  String get width => _t('width');
  String get height => _t('height');
  String get deviceType => _t('deviceType');
  String get columnsCount => _t('columnsCount');
  String get spacing => _t('spacing');
  String get responsiveCardsTest => _t('responsiveCardsTest');
  String get totalProducts => _t('totalProducts');
  String get profits => _t('profits');
  String get responsiveButtonsTest => _t('responsiveButtonsTest');
  String get normalButton => _t('normalButton');
  String get outlinedButton => _t('outlinedButton');
  String get iconButton => _t('iconButton');
  String get responsiveTextTest => _t('responsiveTextTest');
  String get largeText => _t('largeText');
  String get mediumText => _t('mediumText');
  String get normalText => _t('normalText');
  String get smallText => _t('smallText');
  String get responsiveGridTest => _t('responsiveGridTest');
  String get item => _t('item');
  String get mobile => _t('mobile');
  String get tablet => _t('tablet');
  String get desktop => _t('desktop');
  String get largeDesktop => _t('largeDesktop');
  String get ultraWide => _t('ultraWide');
  String dataLoadingError(String error) =>
      _t('dataLoadingError').replaceAll('{error}', error);
  String get quantityLabelShort => _t('quantityLabelShort');

  // Enhanced settings translations
  String get welcomeToSettings => _t('welcomeToSettings');
  String get customizeApp => _t('customizeApp');
  String get languageAndRegion => _t('languageAndRegion');
  String get notificationsSettings => _t('notificationsSettings');
  String get remindersSettings => _t('remindersSettings');
  String get actionsSettings => _t('actionsSettings');
  String get appInfoSettings => _t('appInfoSettings');
  String get enableNotificationsDesc => _t('enableNotificationsDesc');
  String get lowStockAlertsDesc => _t('lowStockAlertsDesc');
  String get dailyRemindersDesc => _t('dailyRemindersDesc');
  String get weeklyRemindersDesc => _t('weeklyRemindersDesc');
  String get cleanupData => _t('cleanupData');
  String get cleanupDataDesc => _t('cleanupDataDesc');
  String get resetSettings => _t('resetSettings');
  String get resetSettingsDesc => _t('resetSettingsDesc');
  String get appVersion => _t('appVersion');
  String get developer => _t('developer');
  String get lastUpdate => _t('lastUpdate');
  String get availableFeatures => _t('availableFeatures');
  String get offlineWork => _t('offlineWork');
  String get autoSync => _t('autoSync');
  String get localNotifications => _t('localNotifications');
  String get scheduledReminders => _t('scheduledReminders');
  String get autoDataCleanup => _t('autoDataCleanup');
  String get cleanupConfirm => _t('cleanupConfirm');
  String get cleanupConfirmMessage => _t('cleanupConfirmMessage');
  String get cleanup => _t('cleanup');
  String get resetConfirm => _t('resetConfirm');
  String get resetConfirmMessage => _t('resetConfirmMessage');
  String get reset => _t('reset');
  String get cleanupSuccessMessage => _t('cleanupSuccessMessage');
  String cleanupErrorMessage(String error) =>
      _t('cleanupErrorMessage').replaceAll('{error}', error);
  String get resetSuccessMessage => _t('resetSuccessMessage');
  String resetErrorMessage(String error) =>
      _t('resetErrorMessage').replaceAll('{error}', error);

  // Responsive test screen translations
  String get responsiveTestTitle => _t('responsiveTestTitle');
  String get deviceInfo => _t('deviceInfo');
  String get deviceInfoTooltip => _t('deviceInfoTooltip');
  String get breakpointsInfo => _t('breakpointsInfo');
  String get breakpointsInfoTooltip => _t('breakpointsInfoTooltip');
  String get screenWidth => _t('screenWidth');
  String get screenHeight => _t('screenHeight');
  String get isLargeScreen => _t('isLargeScreen');
  String get isSmallScreen => _t('isSmallScreen');
  String get isMediumScreen => _t('isMediumScreen');
  String get isDesktopScreen => _t('isDesktopScreen');
  String get isUltraWideScreen => _t('isUltraWideScreen');
  String get gridColumns => _t('gridColumns');
  String get responsiveSpacing => _t('responsiveSpacing');
  String get close => _t('close');
  String get mobileBreakpoint => _t('mobileBreakpoint');
  String get tabletBreakpoint => _t('tabletBreakpoint');
  String get desktopBreakpoint => _t('desktopBreakpoint');
  String get largeDesktopBreakpoint => _t('largeDesktopBreakpoint');
  String get ultraWideBreakpoint => _t('ultraWideBreakpoint');
  String get currentSize => _t('currentSize');
  String get classification => _t('classification');
  String get deviceTypeMobile => _t('deviceTypeMobile');
  String get deviceTypeTablet => _t('deviceTypeTablet');
  String get deviceTypeDesktop => _t('deviceTypeDesktop');
  String get deviceTypeLargeDesktop => _t('deviceTypeLargeDesktop');
  String get deviceTypeUltraWide => _t('deviceTypeUltraWide');

  // Additional settings translations
  String get appManagement => _t('appManagement');
  String get connectionStatus => _t('connectionStatus');
  String get connectionType => _t('connectionType');
  String get syncStatus => _t('syncStatus');
  String get localData => _t('localData');
  String get available => _t('available');
  String get unavailable => _t('unavailable');
  String get automatic => _t('automatic');
  String get manual => _t('manual');
  String get developmentTeam => _t('developmentTeam');
  String get connectedToInternet => _t('connectedToInternet');
  String get notConnectedToInternet => _t('notConnectedToInternet');
  String get appConnectedMessage => _t('appConnectedMessage');
  String get appOfflineMessage => _t('appOfflineMessage');
  String get offlineMode => _t('offlineMode');
  String get retry => _t('retry');

  // Card details screen getters
  String get uniqueProducts => _t('uniqueProducts');
  String get averageProductsPerDay => _t('averageProductsPerDay');
  String get averageValuePerProduct => _t('averageValuePerProduct');
  String get highestValueProduct => _t('highestValueProduct');
  String get productsSoldToday => _t('productsSoldToday');
  String get todayDate => _t('todayDate');
  String get salesTrend => _t('salesTrend');
  String get productsSoldThisMonth => _t('productsSoldThisMonth');
  String get currentMonth => _t('currentMonth');
  String get profitMargin => _t('profitMargin');
  String get averagePrice => _t('averagePrice');
  String get priceRange => _t('priceRange');
  String get trendingUp => _t('trendingUp');
  String get trendingDown => _t('trendingDown');
  String get stable => _t('stable');
  String get noData => _t('noData');

  // New getters for added translations
  String get alertSettingsTitle => _t('alertSettingsTitle');
  String get outOfStockAlertDesc => _t('outOfStockAlertDesc');
  String get lowStockAlertTitle => _t('lowStockAlertTitle');
  String get lowStockAlertDesc => _t('lowStockAlertDesc');
  String get lowStockThreshold => _t('lowStockThreshold');
  String get lowStockThresholdHint => _t('lowStockThresholdHint');
  String get expiringAlertTitle => _t('expiringAlertTitle');
  String get expiringAlertDesc => _t('expiringAlertDesc');
  String get daysBeforeExpiry => _t('daysBeforeExpiry');
  String get daysBeforeExpiryHint => _t('daysBeforeExpiryHint');
  String get additionalActions => _t('additionalActions');
  String get save => _t('save');
  String get updateAlerts => _t('updateAlerts');
  String get updateAlertsDesc => _t('updateAlertsDesc');
  String get checkAlertsAction => _t('checkAlertsAction');
  String get checkAlertsDesc => _t('checkAlertsDesc');
  String get viewAllAlerts => _t('viewAllAlerts');
  String get viewAllAlertsDesc => _t('viewAllAlertsDesc');
  String get viewUnreadAlerts => _t('viewUnreadAlerts');
  String get viewUnreadAlertsDesc => _t('viewUnreadAlertsDesc');
  String get markAllAsReadTitle => _t('markAllAsReadTitle');
  String get markAllAsReadDesc => _t('markAllAsReadDesc');
  String get deleteReadAlertsTitle => _t('deleteReadAlertsTitle');
  String get deleteReadAlertsDesc => _t('deleteReadAlertsDesc');

  // Backup and restore getters
  String get backupRestore => _t('backupRestore');
  String get backup => _t('backup');
  String get restore => _t('restore');
  String get lastBackupInfo => _t('lastBackupInfo');
  String get backupDate => _t('backupDate');
  String get backupDuration => _t('backupDuration');
  String get noBackupYet => _t('noBackupYet');
  String get createBackupNow => _t('createBackupNow');
  String get fullBackup => _t('fullBackup');
  String get productsOnlyBackup => _t('productsOnlyBackup');
  String get inventoryOnlyBackup => _t('inventoryOnlyBackup');
  String get updateBackups => _t('updateBackups');
  String get backupType => _t('backupType');
  String get backupSize => _t('backupSize');
  String get dataCount => _t('dataCount');
  String get share => _t('share');
  String get restoreFromFile => _t('restoreFromFile');
  String get restoreFromCloud => _t('restoreFromCloud');
  String get clearHistory => _t('clearHistory');
  String get restoreCount => _t('restoreCount');
  String get skipCount => _t('skipCount');
  String get errorCount => _t('errorCount');
  String get autoBackup => _t('autoBackup');
  String get enableAutoBackup => _t('enableAutoBackup');
  String get autoBackupDesc => _t('autoBackupDesc');
  String get backupFrequency => _t('backupFrequency');
  String get cloudBackup => _t('cloudBackup');
  String get enableCloudBackup => _t('enableCloudBackup');
  String get cloudBackupDesc => _t('cloudBackupDesc');
  String get createAutoBackupNow => _t('createAutoBackupNow');
  String get createAutoBackupNowDesc => _t('createAutoBackupNowDesc');
  String get clearAllLocalBackups => _t('clearAllLocalBackups');
  String get clearAllLocalBackupsDesc => _t('clearAllLocalBackupsDesc');

  // POS screen getters
  String get saleCompleted => _t('saleCompleted');
  String get operationNumber => _t('operationNumber');
  String get totalAmount => _t('totalAmount');
  String get paymentMethod => _t('paymentMethod');
  String get discount => _t('discount');
  String get pointOfSale => _t('pointOfSale');
  String get subtotal => _t('subtotal');
  String get processing => _t('processing');
  String get completeSale => _t('completeSale');
  String get cash => _t('cash');
  String get card => _t('card');
  String get transfer => _t('transfer');
  String get total => _t('total');

  // Quick inventory getters
  String get updateInventory => _t('updateInventory');
  String get clearInventoryDialog => _t('clearInventoryDialog');
  String get clearInventoryMessage => _t('clearInventoryMessage');
  String get clear => _t('clear');
  String get quickInventory => _t('quickInventory');
  String get scannedQuantity => _t('scannedQuantity');
  String get updating => _t('updating');
  String get updateInventoryAction => _t('updateInventoryAction');

  // Edit dialogs getters
  String get generate => _t('generate');
  String get editProduct => _t('editProduct');

  // POS Reports getters
  String get posReports => _t('posReports');
  String get salesReports => _t('salesReports');
  String get inventoryReports => _t('inventoryReports');
  String get original => _t('original');
  String get scanned => _t('scanned');
  String get quickSell => _t('quickSell');
  String get addToCart => _t('addToCart');
  String get resetCart => _t('resetCart');

  // Barcode scanner getters
  String get scanInstructions => _t('scanInstructions');

  // Error messages getters
  String get dataLoadError => _t('dataLoadError');
  String get criticalError => _t('criticalError');
  String get errorId => _t('errorId');
  String get errorType => _t('errorType');
  String get severity => _t('severity');
  String get timestamp => _t('timestamp');
  String get message => _t('message');
  String get details => _t('details');
  String get userAction => _t('userAction');

  // Print settings getters
  String get paperSize => _t('paperSize');
  String get thermal57 => _t('thermal57');
  String get thermal80 => _t('thermal80');
  String get a4Paper => _t('a4Paper');
  String get showProductName => _t('showProductName');
  String get showStockQuantity => _t('showStockQuantity');

  // Inventory options getters
  String get edit => _t('edit');

  // Validation messages getters
  String get outOfStockStatus => _t('outOfStockStatus');
  String get productDeleted => _t('productDeleted');
  String get productDeleteError => _t('productDeleteError');
  String get dateSelectionError => _t('dateSelectionError');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => AppLocalizations.isSupported(locale);

  @override
  Future<AppLocalizations> load(Locale locale) async =>
      AppLocalizations(locale);

  @override
  bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) =>
      false;
}
