import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// خدمة الإشعارات الذكية بين المنصات
/// تستخدم نظام "الإعلام ثم السحب" لتوفير التحديثات المستهدفة
class SmartNotificationService {
  factory SmartNotificationService() => _instance;
  SmartNotificationService._internal();
  static final SmartNotificationService _instance =
      SmartNotificationService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'user_notifications';

  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _notificationListener;
  String? _currentUserId;
  bool _isListening = false;

  // Callbacks للتحديثات
  final List<void Function(String notificationType)> _notificationCallbacks =
      <void Function(String)>[];

  // ========== بدء وإيقاف الخدمة ==========

  /// بدء خدمة الإشعارات الذكية
  Future<void> startSmartNotifications(String userId) async {
    if (_isListening && _currentUserId == userId) {
      debugPrint('خدمة الإشعارات الذكية تعمل بالفعل للمستخدم: $userId');
      return;
    }

    try {
      // إيقاف الخدمة السابقة إن وجدت
      await stopSmartNotifications();

      _currentUserId = userId;
      debugPrint('🚀 بدء خدمة الإشعارات الذكية للمستخدم: $userId');

      // بدء الاستماع لإشعارات المستخدم
      await _setupNotificationListener();

      _isListening = true;
      debugPrint('✅ تم بدء خدمة الإشعارات الذكية بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في بدء خدمة الإشعارات الذكية: $e');
      rethrow;
    }
  }

  /// إيقاف خدمة الإشعارات الذكية
  Future<void> stopSmartNotifications() async {
    if (!_isListening) return;

    try {
      debugPrint('🛑 إيقاف خدمة الإشعارات الذكية...');

      await _notificationListener?.cancel();
      _notificationListener = null;
      _currentUserId = null;
      _isListening = false;

      debugPrint('✅ تم إيقاف خدمة الإشعارات الذكية بنجاح');
    } on Exception catch (e) {
      debugPrint('❌ خطأ في إيقاف خدمة الإشعارات الذكية: $e');
    }
  }

  // ========== إعداد المستمع ==========

  /// إعداد مستمع الإشعارات
  Future<void> _setupNotificationListener() async {
    if (_currentUserId == null) return;

    try {
      _notificationListener = _firestore
          .collection(_collectionName)
          .doc(_currentUserId!)
          .snapshots()
          .listen(
        _onNotificationReceived,
        onError: (Object error) {
          debugPrint('❌ خطأ في مستمع الإشعارات: $error');
          _handleListenerError(error);
        },
      );

      debugPrint('✅ تم إعداد مستمع الإشعارات للمستخدم: $_currentUserId');
    } catch (e) {
      debugPrint('❌ خطأ في إعداد مستمع الإشعارات: $e');
      rethrow;
    }
  }

  // ========== معالجة الإشعارات ==========

  /// معالجة الإشعارات المستلمة
  void _onNotificationReceived(
      DocumentSnapshot<Map<String, dynamic>> snapshot) {
    try {
      if (!snapshot.exists) {
        debugPrint('📭 لا توجد إشعارات للمستخدم');
        return;
      }

      final Map<String, dynamic> data = snapshot.data()!;
      final String notificationType = data['type']?.toString() ?? '';
      final DateTime timestamp =
          (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now();

      debugPrint('📨 تم استلام إشعار: $notificationType في $timestamp');

      // معالجة الإشعار حسب النوع
      _processNotification(notificationType, data);

      // إشعار callbacks
      for (final void Function(String) callback in _notificationCallbacks) {
        try {
          callback(notificationType);
        } on Exception catch (e) {
          debugPrint('❌ خطأ في callback الإشعار: $e');
        }
      }
    } on Exception catch (e) {
      debugPrint('❌ خطأ في معالجة الإشعار: $e');
    }
  }

  /// معالجة الإشعار حسب النوع
  void _processNotification(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'products_updated':
        _handleProductsUpdateNotification(data);
        break;
      case 'inventory_updated':
        _handleInventoryUpdateNotification(data);
        break;
      case 'sync_required':
        _handleSyncRequiredNotification(data);
        break;
      default:
        debugPrint('⚠️ نوع إشعار غير معروف: $type');
    }
  }

  /// معالجة إشعار تحديث المنتجات
  void _handleProductsUpdateNotification(Map<String, dynamic> data) {
    debugPrint('📦 معالجة إشعار تحديث المنتجات...');
    // يمكن إضافة منطق إضافي هنا إذا لزم الأمر
  }

  /// معالجة إشعار تحديث المخزون
  void _handleInventoryUpdateNotification(Map<String, dynamic> data) {
    debugPrint('📦 معالجة إشعار تحديث المخزون...');
    // يمكن إضافة منطق إضافي هنا إذا لزم الأمر
  }

  /// معالجة إشعار مطلوب مزامنة
  void _handleSyncRequiredNotification(Map<String, dynamic> data) {
    debugPrint('🔄 معالجة إشعار مطلوب مزامنة...');
    // يمكن إضافة منطق إضافي هنا إذا لزم الأمر
  }

  // ========== إرسال الإشعارات ==========

  /// إرسال إشعار تحديث المنتجات
  static Future<void> notifyProductsUpdated(String userId) async {
    try {
      await _sendNotification(userId, 'products_updated', <String, dynamic>{
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'تم تحديث المنتجات',
      });
      debugPrint('📤 تم إرسال إشعار تحديث المنتجات للمستخدم: $userId');
    } catch (e) {
      debugPrint('❌ خطأ في إرسال إشعار تحديث المنتجات: $e');
    }
  }

  /// إرسال إشعار تحديث المخزون
  static Future<void> notifyInventoryUpdated(String userId) async {
    try {
      await _sendNotification(userId, 'inventory_updated', <String, dynamic>{
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'تم تحديث المخزون',
      });
      debugPrint('📤 تم إرسال إشعار تحديث المخزون للمستخدم: $userId');
    } catch (e) {
      debugPrint('❌ خطأ في إرسال إشعار تحديث المخزون: $e');
    }
  }

  /// إرسال إشعار مطلوب مزامنة
  static Future<void> notifySyncRequired(String userId) async {
    try {
      await _sendNotification(userId, 'sync_required', <String, dynamic>{
        'timestamp': FieldValue.serverTimestamp(),
        'message': 'مطلوب مزامنة البيانات',
      });
      debugPrint('📤 تم إرسال إشعار مطلوب مزامنة للمستخدم: $userId');
    } catch (e) {
      debugPrint('❌ خطأ في إرسال إشعار مطلوب مزامنة: $e');
    }
  }

  /// إرسال إشعار عام
  static Future<void> _sendNotification(
      String userId, String type, Map<String, dynamic> data) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    await firestore
        .collection('user_notifications')
        .doc(userId)
        .set(<String, dynamic>{
      'type': type,
      'timestamp': FieldValue.serverTimestamp(),
      ...data,
    });
  }

  // ========== إدارة Callbacks ==========

  /// إضافة callback للإشعارات
  void addNotificationCallback(void Function(String) callback) {
    _notificationCallbacks.add(callback);
  }

  /// إزالة callback للإشعارات
  void removeNotificationCallback(void Function(String) callback) {
    _notificationCallbacks.remove(callback);
  }

  // ========== معالجة الأخطاء ==========

  /// معالجة أخطاء المستمع
  void _handleListenerError(Object error) {
    debugPrint('❌ خطأ في مستمع الإشعارات: $error');

    // إعادة تشغيل المستمع بعد 5 ثوانٍ
    Timer(const Duration(seconds: 5), () {
      if (_isListening && _currentUserId != null) {
        debugPrint('🔄 إعادة تشغيل مستمع الإشعارات...');
        _setupNotificationListener();
      }
    });
  }

  // ========== معلومات الحالة ==========

  /// الحصول على حالة الخدمة
  bool get isListening => _isListening;

  /// الحصول على معرف المستخدم الحالي
  String? get currentUserId => _currentUserId;

  /// الحصول على عدد callbacks
  int get callbackCount => _notificationCallbacks.length;

  // ========== تنظيف الموارد ==========

  /// تنظيف الموارد
  Future<void> dispose() async {
    await stopSmartNotifications();
    _notificationCallbacks.clear();
    debugPrint('تم تنظيف خدمة الإشعارات الذكية');
  }
}
