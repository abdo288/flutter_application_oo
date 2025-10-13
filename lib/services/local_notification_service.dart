import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import '../models/inventory_item.dart';

/// خدمة الإشعارات المحلية
class LocalNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static bool _isInitialized = false;

  /// تهيئة خدمة الإشعارات
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // تهيئة المناطق الزمنية
      tz.initializeTimeZones();

      // طلب إذن الإشعارات (Android)
      if (Platform.isAndroid) {
        final bool? permission = await _notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
        if (permission != true) {
          debugPrint('تم رفض إذن الإشعارات');
          return;
        }
      }

      // تهيئة الإشعارات المحلية
      const InitializationSettings initializationSettings =
          InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
        windows: WindowsInitializationSettings(
          appName: 'Profit Calculator',
          appUserModelId: 'com.example.profit_calculator',
          guid: 'b1d9a0a2-8f5b-4a7f-9b4c-5a0f1a3c2d4e',
        ),
      );

      await _notifications.initialize(initializationSettings);

      _isInitialized = true;
      debugPrint('تم تهيئة خدمة الإشعارات بنجاح');
    } on Exception catch (e) {
      debugPrint('خطأ في تهيئة خدمة الإشعارات: $e');
    }
  }

  /// إرسال إشعار فوري
  static Future<void> showInstantNotification({
    required String title,
    required String body,
    String? payload,
    int id = 0,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      await _notifications.show(
        id,
        title,
        body,
        payload: payload,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'inventory_alerts',
            'تنبيهات المخزون',
            channelDescription: 'إشعارات تنبيهات المخزون والمنتجات',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
          windows: WindowsNotificationDetails(),
        ),
      );
    } on Exception catch (e) {
      debugPrint('خطأ في إرسال الإشعار الفوري: $e');
    }
  }

  /// جدولة إشعار
  static Future<void> scheduleNotification({
    required int id,
    required String title,
    required String body,
    required DateTime scheduledDate,
    String? payload,
  }) async {
    if (!_isInitialized) await initialize();

    try {
      await _notifications.zonedSchedule(
        id,
        title,
        body,
        tz.TZDateTime.from(scheduledDate, tz.local),
        payload: payload,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'scheduled_alerts',
            'التنبيهات المجدولة',
            channelDescription: 'إشعارات مجدولة للمخزون والمنتجات',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/launcher_icon',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
          windows: WindowsNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      );
    } on Exception catch (e) {
      debugPrint('خطأ في جدولة الإشعار: $e');
    }
  }

  /// إشعار نفاد المخزون
  static Future<void> showLowStockAlert(InventoryItem item) async {
    await showInstantNotification(
      title: 'تنبيه نفاد المخزون',
      body: 'المنتج "${item.name}" نفد من المخزون أو كاد ينفد',
      payload: 'low_stock:${item.id}',
      id: item.id.hashCode,
    );
  }

  /// إشعار نفاد المخزون المتعدد
  static Future<void> showMultipleLowStockAlert(
      List<InventoryItem> items) async {
    await showInstantNotification(
      title: 'تنبيه نفاد المخزون',
      body: '${items.length} منتج نفد من المخزون أو كاد ينفد',
      payload: 'multiple_low_stock',
      id: DateTime.now().millisecondsSinceEpoch,
    );
  }

  /// إشعار تذكير فحص المخزون
  static Future<void> scheduleInventoryCheckReminder({
    required DateTime reminderTime,
    String? customMessage,
  }) async {
    await scheduleNotification(
      id: 'inventory_check'.hashCode,
      title: 'تذكير فحص المخزون',
      body: customMessage ?? 'حان وقت فحص المخزون وتحديث الكميات',
      scheduledDate: reminderTime,
      payload: 'inventory_check_reminder',
    );
  }

  /// إشعار تذكير إضافة منتجات جديدة
  static Future<void> scheduleAddProductsReminder({
    required DateTime reminderTime,
    String? customMessage,
  }) async {
    await scheduleNotification(
      id: 'add_products'.hashCode,
      title: 'تذكير إضافة منتجات',
      body: customMessage ?? 'تذكير لإضافة منتجات جديدة للمخزون',
      scheduledDate: reminderTime,
      payload: 'add_products_reminder',
    );
  }

  /// إشعار تذكير مراجعة الأرباح
  static Future<void> scheduleProfitReviewReminder({
    required DateTime reminderTime,
    String? customMessage,
  }) async {
    await scheduleNotification(
      id: 'profit_review'.hashCode,
      title: 'تذكير مراجعة الأرباح',
      body: customMessage ?? 'حان وقت مراجعة الأرباح والإحصائيات',
      scheduledDate: reminderTime,
      payload: 'profit_review_reminder',
    );
  }

  /// إشعار مزامنة البيانات
  static Future<void> showSyncNotification({
    required String message,
    bool isSuccess = true,
  }) async {
    await showInstantNotification(
      title: isSuccess ? 'تمت المزامنة بنجاح' : 'خطأ في المزامنة',
      body: message,
      payload: 'sync_${isSuccess ? 'success' : 'error'}',
      id: 'sync_notification'.hashCode,
    );
  }

  /// إشعار وضع عدم الاتصال
  static Future<void> showOfflineNotification() async {
    await showInstantNotification(
      title: 'وضع عدم الاتصال',
      body: 'التطبيق يعمل في وضع عدم الاتصال. سيتم المزامنة عند العودة للاتصال',
      payload: 'offline_mode',
      id: 'offline_notification'.hashCode,
    );
  }

  /// إشعار العودة للاتصال
  static Future<void> showOnlineNotification() async {
    await showInstantNotification(
      title: 'تم استعادة الاتصال',
      body: 'تم استعادة الاتصال بالإنترنت. جاري المزامنة...',
      payload: 'online_mode',
      id: 'online_notification'.hashCode,
    );
  }

  /// إلغاء إشعار محدد
  static Future<void> cancelNotification(int id) async {
    try {
      await _notifications.cancel(id);
    } on Exception catch (e) {
      debugPrint('خطأ في إلغاء الإشعار: $e');
    }
  }

  /// إلغاء جميع الإشعارات
  static Future<void> cancelAllNotifications() async {
    try {
      await _notifications.cancelAll();
    } on Exception catch (e) {
      debugPrint('خطأ في إلغاء جميع الإشعارات: $e');
    }
  }

  /// إلغاء الإشعارات المجدولة
  static Future<void> cancelScheduledNotifications() async {
    try {
      await _notifications.cancelAll();
    } on Exception catch (e) {
      debugPrint('خطأ في إلغاء الإشعارات المجدولة: $e');
    }
  }

  /// الحصول على الإشعارات المعلقة
  static Future<List<PendingNotificationRequest>>
      getPendingNotifications() async {
    try {
      return await _notifications.pendingNotificationRequests();
    } on Exception catch (e) {
      debugPrint('خطأ في الحصول على الإشعارات المعلقة: $e');
      return <PendingNotificationRequest>[];
    }
  }

  /// إعداد تذكيرات يومية
  static Future<void> setupDailyReminders() async {
    final DateTime now = DateTime.now();

    // تذكير فحص المخزون في الساعة 9 صباحاً
    final DateTime inventoryCheckTime =
        DateTime(now.year, now.month, now.day, 9);
    if (inventoryCheckTime.isAfter(now)) {
      await scheduleInventoryCheckReminder(reminderTime: inventoryCheckTime);
    }

    // تذكير إضافة منتجات في الساعة 6 مساءً
    final DateTime addProductsTime = DateTime(now.year, now.month, now.day, 18);
    if (addProductsTime.isAfter(now)) {
      await scheduleAddProductsReminder(reminderTime: addProductsTime);
    }

    // تذكير مراجعة الأرباح في الساعة 10 مساءً
    final DateTime profitReviewTime =
        DateTime(now.year, now.month, now.day, 22);
    if (profitReviewTime.isAfter(now)) {
      await scheduleProfitReviewReminder(reminderTime: profitReviewTime);
    }
  }

  /// إعداد تذكيرات أسبوعية
  static Future<void> setupWeeklyReminders() async {
    final DateTime now = DateTime.now();
    final DateTime nextWeek = now.add(const Duration(days: 7));

    // تذكير مراجعة شاملة أسبوعياً
    final DateTime weeklyReviewTime =
        DateTime(nextWeek.year, nextWeek.month, nextWeek.day, 10);
    await scheduleNotification(
      id: 'weekly_review'.hashCode,
      title: 'مراجعة أسبوعية',
      body: 'حان وقت المراجعة الأسبوعية للمخزون والأرباح',
      scheduledDate: weeklyReviewTime,
      payload: 'weekly_review',
    );
  }

  /// معالج النقر على الإشعار
  static void handleNotificationTap(String? payload) {
    if (payload == null) return;

    debugPrint('تم النقر على إشعار: $payload');

    // يمكن إضافة منطق التنقل هنا حسب نوع الإشعار
    switch (payload.split(':')[0]) {
      case 'low_stock':
        // التنقل إلى شاشة المخزون
        break;
      case 'multiple_low_stock':
        // التنقل إلى شاشة المخزون
        break;
      case 'inventory_check_reminder':
        // التنقل إلى شاشة المخزون
        break;
      case 'add_products_reminder':
        // التنقل إلى شاشة إضافة المنتجات
        break;
      case 'profit_review_reminder':
        // التنقل إلى شاشة لوحة التحكم
        break;
      case 'sync_success':
      case 'sync_error':
        // إظهار رسالة المزامنة
        break;
      case 'offline_mode':
      case 'online_mode':
        // إظهار حالة الاتصال
        break;
    }
  }

  /// التحقق من إذن الإشعارات
  static Future<bool> checkPermission() async {
    try {
      if (Platform.isAndroid) {
        final bool? permission = await _notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission();
        return permission == true;
      }
      return true; // iOS permissions are handled during initialization
    } on Exception catch (e) {
      debugPrint('خطأ في التحقق من إذن الإشعارات: $e');
      return false;
    }
  }

  /// فتح إعدادات الإشعارات
  static Future<void> openNotificationSettings() async {
    try {
      // Note: openAppSettings is not available in this version
      // Users can manually go to app settings
      debugPrint('يرجى الذهاب إلى إعدادات التطبيق يدوياً لتفعيل الإشعارات');
    } on Exception catch (e) {
      debugPrint('خطأ في فتح إعدادات الإشعارات: $e');
    }
  }
}
