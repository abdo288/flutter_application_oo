import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/dashboard_summary.dart';
import '../models/notification_config.dart';
// import '../../models/eod_report.dart'; // تم تعطيله مؤقتاً

/// خدمة إشعارات التقارير
class ReportsNotificationService {
  factory ReportsNotificationService() => _instance;
  ReportsNotificationService._internal();
  static final ReportsNotificationService _instance =
      ReportsNotificationService._internal();

  final List<NotificationConfig> _activeNotifications = <NotificationConfig>[];
  Timer? _notificationTimer;
  final Map<String, DateTime> _lastNotificationTimes = <String, DateTime>{};

  /// تهيئة خدمة الإشعارات
  Future<void> initialize() async {
    try {
      await _loadNotificationConfigs();
      await _startNotificationTimer();
      debugPrint('✅ تم تهيئة خدمة الإشعارات');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة خدمة الإشعارات: $e');
    }
  }

  /// تحميل إعدادات الإشعارات
  Future<void> _loadNotificationConfigs() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? configsJson = prefs.getString('notification_configs');

      if (configsJson != null) {
        // تحليل JSON وإضافة الإشعارات
        // تنفيذ مبسط - يمكن تحسينه
        _activeNotifications.addAll(NotificationPresets.allPresets);
      } else {
        // استخدام الإعدادات الافتراضية
        _activeNotifications.addAll(NotificationPresets.allPresets);
        await _saveNotificationConfigs();
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحميل إعدادات الإشعارات: $e');
      _activeNotifications.addAll(NotificationPresets.allPresets);
    }
  }

  /// حفظ إعدادات الإشعارات
  Future<void> _saveNotificationConfigs() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String configsJson =
          _activeNotifications.map((NotificationConfig config) => config.toMap()).toString();
      await prefs.setString('notification_configs', configsJson);
    } catch (e) {
      debugPrint('❌ خطأ في حفظ إعدادات الإشعارات: $e');
    }
  }

  /// بدء مؤقت الإشعارات
  Future<void> _startNotificationTimer() async {
    _notificationTimer?.cancel();
    _notificationTimer = Timer.periodic(const Duration(minutes: 1), (Timer timer) {
      _checkNotifications();
    });
  }

  /// فحص الإشعارات
  Future<void> _checkNotifications() async {
    try {
      for (final NotificationConfig config in _activeNotifications) {
        if (config.isActive && _shouldSendNotification(config)) {
          await _sendNotification(config);
        }
      }
    } catch (e) {
      debugPrint('❌ خطأ في فحص الإشعارات: $e');
    }
  }

  /// التحقق من إرسال الإشعار
  bool _shouldSendNotification(NotificationConfig config) {
    final String notificationKey = config.id;
    final DateTime? lastSent = _lastNotificationTimes[notificationKey];

    if (lastSent == null) return true;

    // منع الإشعارات المتكررة في أقل من 5 دقائق
    final Duration timeSinceLastSent = DateTime.now().difference(lastSent);
    return timeSinceLastSent.inMinutes >= 5;
  }

  /// إرسال الإشعار
  Future<void> _sendNotification(NotificationConfig config) async {
    try {
      // تنفيذ مبسط - في التطبيق الحقيقي ستحتاج إلى استخدام مكتبة الإشعارات
      debugPrint('🔔 إشعار: ${config.name}');

      // تسجيل وقت الإرسال
      _lastNotificationTimes[config.id] = DateTime.now();

      // تنفيذ الإجراءات
      for (final NotificationAction action in config.actions) {
        if (action.enabled) {
          await _executeAction(action);
        }
      }
    } catch (e) {
      debugPrint('❌ خطأ في إرسال الإشعار: $e');
    }
  }

  /// تنفيذ إجراء الإشعار
  Future<void> _executeAction(NotificationAction action) async {
    try {
      switch (action.type) {
        case ActionType.showSnackbar:
          debugPrint('📱 عرض Snackbar: ${action.config['message']}');
          break;
        case ActionType.showDialog:
          debugPrint(
              '💬 عرض Dialog: ${action.config['title']} - ${action.config['message']}');
          break;
        case ActionType.showNotification:
          debugPrint(
              '🔔 إشعار: ${action.config['title']} - ${action.config['message']}');
          break;
        case ActionType.sendEmail:
          debugPrint('📧 إرسال بريد إلكتروني: ${action.config['to']}');
          break;
        case ActionType.sendSms:
          debugPrint('📱 إرسال SMS: ${action.config['to']}');
          break;
        case ActionType.playSound:
          debugPrint('🔊 تشغيل صوت');
          break;
        case ActionType.vibrate:
          debugPrint('📳 اهتزاز');
          break;
        case ActionType.logEvent:
          debugPrint('📝 تسجيل حدث: ${action.config['event']}');
          break;
        case ActionType.triggerAction:
          debugPrint('⚡ تنفيذ إجراء: ${action.config['action']}');
          break;
      }
    } catch (e) {
      debugPrint('❌ خطأ في تنفيذ إجراء الإشعار: $e');
    }
  }

  /// إشعار تنبيه المخزون المنخفض
  Future<void> notifyLowStock(DashboardSummary summary) async {
    try {
      if (summary.hasLowStockAlerts) {
        const NotificationConfig config = NotificationPresets.lowStockAlert;
        await _sendNotification(config);
      }
    } catch (e) {
      debugPrint('❌ خطأ في إشعار المخزون المنخفض: $e');
    }
  }

  /// إشعار تذكير إنهاء اليوم
  Future<void> notifyEODReminder() async {
    try {
      final DateTime now = DateTime.now();
      final int hour = now.hour;

      // تذكير في الساعة 6 مساءً
      if (hour == 18) {
        const NotificationConfig config = NotificationPresets.eodReminder;
        await _sendNotification(config);
      }
    } catch (e) {
      debugPrint('❌ خطأ في إشعار تذكير إنهاء اليوم: $e');
    }
  }

  /// إشعار حالة المزامنة
  Future<void> notifySyncStatus(String status) async {
    try {
      if (status == 'failed') {
        const NotificationConfig config = NotificationPresets.syncStatus;
        await _sendNotification(config);
      }
    } catch (e) {
      debugPrint('❌ خطأ في إشعار حالة المزامنة: $e');
    }
  }

  /// إشعار إنجاز
  Future<void> notifyAchievement(String achievement) async {
    try {
      final NotificationConfig config = NotificationConfig(
        id: 'achievement_${DateTime.now().millisecondsSinceEpoch}',
        name: 'إنجاز جديد',
        description: achievement,
        type: NotificationType.achievement,
        enabled: true,
        conditions: const <NotificationCondition>[],
        actions: <NotificationAction>[
          const NotificationAction(
            type: ActionType.showNotification,
            config: <String, dynamic>{
              'title': 'إنجاز جديد!',
              'message': 'تهانينا! لقد حققت إنجازاً جديداً',
            },
            enabled: true,
          ),
        ],
      );

      await _sendNotification(config);
    } catch (e) {
      debugPrint('❌ خطأ في إشعار الإنجاز: $e');
    }
  }

  /// إضافة إشعار مخصص
  Future<void> addCustomNotification(NotificationConfig config) async {
    try {
      _activeNotifications.add(config);
      await _saveNotificationConfigs();
      debugPrint('✅ تم إضافة إشعار مخصص: ${config.name}');
    } catch (e) {
      debugPrint('❌ خطأ في إضافة إشعار مخصص: $e');
    }
  }

  /// إزالة إشعار
  Future<void> removeNotification(String notificationId) async {
    try {
      _activeNotifications.removeWhere((NotificationConfig config) => config.id == notificationId);
      await _saveNotificationConfigs();
      debugPrint('✅ تم إزالة الإشعار: $notificationId');
    } catch (e) {
      debugPrint('❌ خطأ في إزالة الإشعار: $e');
    }
  }

  /// تحديث إشعار
  Future<void> updateNotification(NotificationConfig updatedConfig) async {
    try {
      final int index = _activeNotifications
          .indexWhere((NotificationConfig config) => config.id == updatedConfig.id);
      if (index != -1) {
        _activeNotifications[index] = updatedConfig;
        await _saveNotificationConfigs();
        debugPrint('✅ تم تحديث الإشعار: ${updatedConfig.name}');
      }
    } catch (e) {
      debugPrint('❌ خطأ في تحديث الإشعار: $e');
    }
  }

  /// الحصول على جميع الإشعارات النشطة
  List<NotificationConfig> getActiveNotifications() => List.unmodifiable(_activeNotifications);

  /// الحصول على إشعار بالمعرف
  NotificationConfig? getNotificationById(String id) {
    try {
      return _activeNotifications.firstWhere((NotificationConfig config) => config.id == id);
    } catch (e) {
      return null;
    }
  }

  /// تفعيل/إلغاء تفعيل إشعار
  Future<void> toggleNotification(String notificationId, bool enabled) async {
    try {
      final int index = _activeNotifications
          .indexWhere((NotificationConfig config) => config.id == notificationId);
      if (index != -1) {
        final NotificationConfig config = _activeNotifications[index];
        final NotificationConfig updatedConfig = NotificationConfig(
          id: config.id,
          name: config.name,
          type: config.type,
          enabled: enabled,
          conditions: config.conditions,
          actions: config.actions,
          priority: config.priority,
          schedule: config.schedule,
          recipients: config.recipients,
          createdAt: config.createdAt,
          updatedAt: config.updatedAt,
        );
        _activeNotifications[index] = updatedConfig;
        await _saveNotificationConfigs();
        debugPrint(
            '✅ تم ${enabled ? 'تفعيل' : 'إلغاء تفعيل'} الإشعار: $notificationId');
      }
    } catch (e) {
      debugPrint('❌ خطأ في تبديل حالة الإشعار: $e');
    }
  }

  /// إحصائيات الإشعارات
  Map<String, dynamic> getNotificationStats() {
    try {
      final int totalNotifications = _activeNotifications.length;
      final int enabledNotifications =
          _activeNotifications.where((NotificationConfig config) => config.enabled).length;
      final int disabledNotifications =
          totalNotifications - enabledNotifications;

      final Map<NotificationType, int> typeCount = <NotificationType, int>{};
      for (final NotificationConfig config in _activeNotifications) {
        typeCount[config.type] = (typeCount[config.type] ?? 0) + 1;
      }

      return <String, dynamic>{
        'totalNotifications': totalNotifications,
        'enabledNotifications': enabledNotifications,
        'disabledNotifications': disabledNotifications,
        'typeCount': typeCount,
        'lastNotificationTimes': _lastNotificationTimes.length,
      };
    } catch (e) {
      debugPrint('❌ خطأ في جلب إحصائيات الإشعارات: $e');
      return <String, dynamic>{
        'totalNotifications': 0,
        'enabledNotifications': 0,
        'disabledNotifications': 0,
        'typeCount': <NotificationType, int>{},
        'lastNotificationTimes': 0,
      };
    }
  }

  /// مسح تاريخ الإشعارات
  Future<void> clearNotificationHistory() async {
    try {
      _lastNotificationTimes.clear();
      debugPrint('✅ تم مسح تاريخ الإشعارات');
    } catch (e) {
      debugPrint('❌ خطأ في مسح تاريخ الإشعارات: $e');
    }
  }

  /// إيقاف خدمة الإشعارات
  Future<void> dispose() async {
    try {
      _notificationTimer?.cancel();
      _notificationTimer = null;
      debugPrint('✅ تم إيقاف خدمة الإشعارات');
    } catch (e) {
      debugPrint('❌ خطأ في إيقاف خدمة الإشعارات: $e');
    }
  }
}
