import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../models/update_log.dart';

/// خدمة الإشعارات المحسّنة للتحديثات الفورية
class RealtimeNotificationService {
  RealtimeNotificationService._();
  static RealtimeNotificationService? _instance;
  static RealtimeNotificationService get instance =>
      _instance ??= RealtimeNotificationService._();

  // ========== إعدادات الإشعارات ==========

  bool _enableNotifications = true;
  bool _enableSounds = true;
  bool _enableVibration = false;
  String _priority = 'medium'; // 'high', 'medium', 'low'
  int _maxNotifications = 10;

  // ========== سجل الإشعارات ==========

  final List<NotificationLog> _notificationLog = <NotificationLog>[];
  final StreamController<NotificationLog> _notificationController =
      StreamController<NotificationLog>.broadcast();

  /// Stream للإشعارات
  Stream<NotificationLog> get notificationStream =>
      _notificationController.stream;

  /// سجل الإشعارات
  List<NotificationLog> get notificationLog =>
      List.unmodifiable(_notificationLog);

  // ========== إدارة الإشعارات ==========

  /// تمكين/تعطيل الإشعارات
  void setNotificationsEnabled(bool enabled) {
    _enableNotifications = enabled;
    debugPrint('🔔 الإشعارات ${enabled ? "مفعلة" : "معطلة"}');
  }

  /// تمكين/تعطيل الأصوات
  void setSoundsEnabled(bool enabled) {
    _enableSounds = enabled;
    debugPrint('🔊 الأصوات ${enabled ? "مفعلة" : "معطلة"}');
  }

  /// تمكين/تعطيل الاهتزاز
  void setVibrationEnabled(bool enabled) {
    _enableVibration = enabled;
    debugPrint('📳 الاهتزاز ${enabled ? "مفعل" : "معطل"}');
  }

  /// تعيين أولوية الإشعارات
  void setPriority(String priority) {
    if (<String>['high', 'medium', 'low'].contains(priority)) {
      _priority = priority;
      debugPrint('⚡ أولوية الإشعارات: $priority');
    }
  }

  /// تعيين الحد الأقصى للإشعارات
  void setMaxNotifications(int max) {
    _maxNotifications = max;
    debugPrint('📊 الحد الأقصى للإشعارات: $max');
  }

  // ========== إرسال الإشعارات ==========

  /// إرسال إشعار تحديث
  Future<void> notifyUpdate(UpdateLog updateLog) async {
    if (!_enableNotifications) return;

    try {
      final NotificationLog notification = NotificationLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'update',
        title: _getUpdateTitle(updateLog),
        body: _getUpdateBody(updateLog),
        priority: _priority,
        timestamp: DateTime.now(),
        data: updateLog.toMap(),
      );

      await _addNotification(notification);
      await _showSystemNotification(notification);

      debugPrint('📢 تم إرسال إشعار التحديث: ${notification.title}');
    } catch (e) {
      debugPrint('❌ خطأ في إرسال إشعار التحديث: $e');
    }
  }

  /// إرسال إشعار خطأ
  Future<void> notifyError(String title, String message,
      {Map<String, dynamic>? data}) async {
    if (!_enableNotifications) return;

    try {
      final NotificationLog notification = NotificationLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'error',
        title: title,
        body: message,
        priority: 'high',
        timestamp: DateTime.now(),
        data: data,
      );

      await _addNotification(notification);
      await _showSystemNotification(notification);

      debugPrint('🚨 تم إرسال إشعار الخطأ: $title');
    } catch (e) {
      debugPrint('❌ خطأ في إرسال إشعار الخطأ: $e');
    }
  }

  /// إرسال إشعار نجاح
  Future<void> notifySuccess(String title, String message,
      {Map<String, dynamic>? data}) async {
    if (!_enableNotifications) return;

    try {
      final NotificationLog notification = NotificationLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'success',
        title: title,
        body: message,
        priority: 'medium',
        timestamp: DateTime.now(),
        data: data,
      );

      await _addNotification(notification);
      await _showSystemNotification(notification);

      debugPrint('✅ تم إرسال إشعار النجاح: $title');
    } catch (e) {
      debugPrint('❌ خطأ في إرسال إشعار النجاح: $e');
    }
  }

  /// إرسال إشعار معلومات
  Future<void> notifyInfo(String title, String message,
      {Map<String, dynamic>? data}) async {
    if (!_enableNotifications) return;

    try {
      final NotificationLog notification = NotificationLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        type: 'info',
        title: title,
        body: message,
        priority: 'low',
        timestamp: DateTime.now(),
        data: data,
      );

      await _addNotification(notification);
      await _showSystemNotification(notification);

      debugPrint('ℹ️ تم إرسال إشعار المعلومات: $title');
    } catch (e) {
      debugPrint('❌ خطأ في إرسال إشعار المعلومات: $e');
    }
  }

  // ========== إدارة السجل ==========

  /// إضافة إشعار للسجل
  Future<void> _addNotification(NotificationLog notification) async {
    _notificationLog.insert(0, notification);

    // الحفاظ على الحد الأقصى للإشعارات
    if (_notificationLog.length > _maxNotifications) {
      _notificationLog.removeRange(_maxNotifications, _notificationLog.length);
    }

    _notificationController.add(notification);
  }

  /// إظهار إشعار النظام
  Future<void> _showSystemNotification(NotificationLog notification) async {
    // في التطبيق الحقيقي، يمكن استخدام flutter_local_notifications
    debugPrint('🔔 إشعار: ${notification.title} - ${notification.body}');

    if (_enableSounds) {
      debugPrint('🔊 تشغيل الصوت');
    }

    if (_enableVibration) {
      debugPrint('📳 اهتزاز');
    }
  }

  // ========== مساعدة في إنشاء الإشعارات ==========

  String _getUpdateTitle(UpdateLog updateLog) {
    switch (updateLog.type) {
      case 'product':
        return 'تحديث المنتجات';
      case 'inventory':
        return 'تحديث المخزون';
      case 'sale':
        return 'تحديث المبيعات';
      default:
        return 'تحديث البيانات';
    }
  }

  String _getUpdateBody(UpdateLog updateLog) {
    final String action = _getActionText(updateLog.action);
    final String type = _getTypeText(updateLog.type);

    if (updateLog.isSuccessful) {
      return '$action $type بنجاح';
    } else {
      return 'فشل في $action $type: ${updateLog.errorMessage ?? "خطأ غير معروف"}';
    }
  }

  String _getActionText(String action) {
    switch (action) {
      case 'create':
        return 'إنشاء';
      case 'update':
        return 'تحديث';
      case 'delete':
        return 'حذف';
      case 'sync':
        return 'مزامنة';
      default:
        return action;
    }
  }

  String _getTypeText(String type) {
    switch (type) {
      case 'product':
        return 'المنتج';
      case 'inventory':
        return 'عنصر المخزون';
      case 'sale':
        return 'المبيعات';
      default:
        return type;
    }
  }

  // ========== إدارة السجل ==========

  /// تمييز إشعار كمقروء
  void markAsRead(String notificationId) {
    final int index =
        _notificationLog.indexWhere((NotificationLog n) => n.id == notificationId);
    if (index != -1) {
      _notificationLog[index] = _notificationLog[index].copyWith(isRead: true);
      debugPrint('📖 تم تمييز الإشعار كمقروء: $notificationId');
    }
  }

  /// تمييز جميع الإشعارات كمقروءة
  void markAllAsRead() {
    for (int i = 0; i < _notificationLog.length; i++) {
      _notificationLog[i] = _notificationLog[i].copyWith(isRead: true);
    }
    debugPrint('📖 تم تمييز جميع الإشعارات كمقروءة');
  }

  /// حذف إشعار
  void removeNotification(String notificationId) {
    _notificationLog.removeWhere((NotificationLog n) => n.id == notificationId);
    debugPrint('🗑️ تم حذف الإشعار: $notificationId');
  }

  /// مسح جميع الإشعارات
  void clearAllNotifications() {
    _notificationLog.clear();
    debugPrint('🗑️ تم مسح جميع الإشعارات');
  }

  /// الحصول على عدد الإشعارات غير المقروءة
  int get unreadCount => _notificationLog.where((n) => !n.isRead).length;

  /// الحصول على إحصائيات الإشعارات
  Map<String, dynamic> getNotificationStats() {
    final int total = _notificationLog.length;
    final int unread = unreadCount;
    final int read = total - unread;

    final Map<String, int> byType = <String, int>{};
    final Map<String, int> byPriority = <String, int>{};

    for (final NotificationLog notification in _notificationLog) {
      byType[notification.type] = (byType[notification.type] ?? 0) + 1;
      byPriority[notification.priority] =
          (byPriority[notification.priority] ?? 0) + 1;
    }

    return <String, dynamic>{
      'total': total,
      'unread': unread,
      'read': read,
      'byType': byType,
      'byPriority': byPriority,
    };
  }

  /// تنظيف الموارد
  Future<void> dispose() async {
    await _notificationController.close();
    debugPrint('🧹 تم تنظيف خدمة الإشعارات');
  }
}

/// نموذج سجل الإشعارات
class NotificationLog {

  const NotificationLog({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.priority,
    required this.timestamp,
    this.data,
    this.isRead = false,
  });
  final String id;
  final String type; // 'update', 'error', 'success', 'info'
  final String title;
  final String body;
  final String priority; // 'high', 'medium', 'low'
  final DateTime timestamp;
  final Map<String, dynamic>? data;
  final bool isRead;

  /// نسخ مع تعديلات
  NotificationLog copyWith({
    String? id,
    String? type,
    String? title,
    String? body,
    String? priority,
    DateTime? timestamp,
    Map<String, dynamic>? data,
    bool? isRead,
  }) => NotificationLog(
      id: id ?? this.id,
      type: type ?? this.type,
      title: title ?? this.title,
      body: body ?? this.body,
      priority: priority ?? this.priority,
      timestamp: timestamp ?? this.timestamp,
      data: data ?? this.data,
      isRead: isRead ?? this.isRead,
    );

  /// تنسيق الوقت
  String get formattedTime {
    final DateTime now = DateTime.now();
    final Duration difference = now.difference(timestamp);

    if (difference.inSeconds < 60) {
      return 'منذ ${difference.inSeconds} ثانية';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return 'منذ ${difference.inDays} يوم';
    }
  }

  @override
  String toString() => 'NotificationLog(id: $id, type: $type, title: $title, body: $body, priority: $priority, timestamp: $timestamp, isRead: $isRead)';
}
