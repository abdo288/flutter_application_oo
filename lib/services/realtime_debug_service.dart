import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import 'connectivity_service.dart';
import 'realtime_update_service.dart';

/// خدمة تشخيص التحديثات الفورية
class RealtimeDebugService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// فحص شامل لحالة التحديثات الفورية
  static Future<Map<String, dynamic>> performFullDiagnosis() async {
    final Map<String, dynamic> diagnosis = <String, dynamic>{};

    try {
      debugPrint('🔍 بدء التشخيص الشامل للتحديثات الفورية...');

      // 1. فحص حالة الاتصال
      diagnosis['connection'] = await _checkConnection();

      // 2. فحص إعدادات Firestore
      diagnosis['firestore'] = await _checkFirestoreSettings();

      // 3. فحص خدمة التحديثات الفورية
      diagnosis['realtime_service'] = _checkRealtimeService();

      // 4. فحص المجموعات
      diagnosis['collections'] = await _checkCollections();

      // 5. فحص المستمعين
      diagnosis['listeners'] = _checkListeners();

      // 6. فحص Callbacks
      diagnosis['callbacks'] = _checkCallbacks();

      debugPrint('✅ تم إكمال التشخيص الشامل');
      return diagnosis;
    } catch (e) {
      debugPrint('❌ خطأ في التشخيص: $e');
      diagnosis['error'] = e.toString();
      return diagnosis;
    }
  }

  /// فحص حالة الاتصال
  static Future<Map<String, dynamic>> _checkConnection() async {
    try {
      final bool isOnline = ConnectivityService.isConnected;
      return <String, dynamic>{
        'is_online': isOnline,
        'status': isOnline ? 'متصل' : 'غير متصل',
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return <String, dynamic>{
        'is_online': false,
        'status': 'خطأ في فحص الاتصال',
        'error': e.toString(),
      };
    }
  }

  /// فحص إعدادات Firestore
  static Future<Map<String, dynamic>> _checkFirestoreSettings() async {
    try {
      final Settings settings = _db.settings;
      return <String, dynamic>{
        'persistence_enabled': settings.persistenceEnabled,
        'cache_size': settings.cacheSizeBytes,
        'host': _db.app.options.projectId,
        'status': 'تم تهيئة Firestore بنجاح',
      };
    } catch (e) {
      return <String, dynamic>{
        'status': 'خطأ في إعدادات Firestore',
        'error': e.toString(),
      };
    }
  }

  /// فحص خدمة التحديثات الفورية
  static Map<String, dynamic> _checkRealtimeService() {
    try {
      final RealtimeUpdateService service = RealtimeUpdateService.instance;
      return <String, dynamic>{
        'is_listening': service.isListening,
        'is_online': service.isOnline,
        'last_update_time': service.lastUpdateTime?.toIso8601String(),
        'product_callbacks': service.productCallbackCount,
        'inventory_callbacks': service.inventoryCallbackCount,
        'connection_callbacks': service.connectionCallbackCount,
        'status': service.isListening ? 'نشط' : 'غير نشط',
      };
    } catch (e) {
      return <String, dynamic>{
        'status': 'خطأ في خدمة التحديثات الفورية',
        'error': e.toString(),
      };
    }
  }

  /// فحص المجموعات
  static Future<Map<String, dynamic>> _checkCollections() async {
    try {
      // فحص مجموعة المنتجات
      final QuerySnapshot productsSnapshot =
          await _db.collection('products').limit(1).get();

      // فحص مجموعة المخزون
      final QuerySnapshot inventorySnapshot =
          await _db.collection('quantities').limit(1).get();

      return <String, dynamic>{
        'products': <String, Object?>{
          'count': productsSnapshot.docs.length,
          'accessible': true,
          'last_document': productsSnapshot.docs.isNotEmpty
              ? productsSnapshot.docs.first.id
              : null,
        },
        'inventory': <String, Object?>{
          'count': inventorySnapshot.docs.length,
          'accessible': true,
          'last_document': inventorySnapshot.docs.isNotEmpty
              ? inventorySnapshot.docs.first.id
              : null,
        },
        'status': 'تم الوصول للمجموعات بنجاح',
      };
    } catch (e) {
      return <String, dynamic>{
        'status': 'خطأ في الوصول للمجموعات',
        'error': e.toString(),
      };
    }
  }

  /// فحص المستمعين
  static Map<String, dynamic> _checkListeners() {
    try {
      // هذا يتطلب الوصول المباشر للمستمعين من RealtimeUpdateService
      // يمكن تحسينه لاحقاً بإضافة getters للمستمعين
      return <String, dynamic>{
        'status': 'المستمعين يتم فحصهم من خلال خدمة التحديثات الفورية',
        'note': 'تحقق من سجلات التطبيق لرؤية حالة المستمعين',
      };
    } catch (e) {
      return <String, dynamic>{
        'status': 'خطأ في فحص المستمعين',
        'error': e.toString(),
      };
    }
  }

  /// فحص Callbacks
  static Map<String, dynamic> _checkCallbacks() {
    try {
      final RealtimeUpdateService service = RealtimeUpdateService.instance;
      return <String, dynamic>{
        'product_callbacks': service.productCallbackCount,
        'inventory_callbacks': service.inventoryCallbackCount,
        'connection_callbacks': service.connectionCallbackCount,
        'total_callbacks': service.productCallbackCount +
            service.inventoryCallbackCount +
            service.connectionCallbackCount,
        'status': 'تم فحص Callbacks بنجاح',
      };
    } catch (e) {
      return <String, dynamic>{
        'status': 'خطأ في فحص Callbacks',
        'error': e.toString(),
      };
    }
  }

  /// اختبار إرسال تحديث تجريبي
  static Future<bool> testRealtimeUpdate() async {
    try {
      debugPrint('🧪 بدء اختبار التحديث الفوري...');

      // إضافة مستند تجريبي
      await _db.collection('test_realtime').add(<String, dynamic>{
        'message': 'اختبار التحديث الفوري',
        'timestamp': DateTime.now().toIso8601String(),
        'platform': defaultTargetPlatform.toString(),
      });

      debugPrint('✅ تم إرسال تحديث تجريبي');
      return true;
    } catch (e) {
      debugPrint('❌ فشل في اختبار التحديث الفوري: $e');
      return false;
    }
  }

  /// تنظيف المستندات التجريبية
  static Future<void> cleanupTestData() async {
    try {
      final QuerySnapshot testDocs =
          await _db.collection('test_realtime').get();
      for (final QueryDocumentSnapshot doc in testDocs.docs) {
        await doc.reference.delete();
      }
      debugPrint('🧹 تم تنظيف البيانات التجريبية');
    } catch (e) {
      debugPrint('❌ خطأ في تنظيف البيانات التجريبية: $e');
    }
  }

  /// طباعة تقرير التشخيص
  static void printDiagnosisReport(Map<String, dynamic> diagnosis) {
    debugPrint('\n${'=' * 50}');
    debugPrint('📊 تقرير تشخيص التحديثات الفورية');
    debugPrint('=' * 50);

    // حالة الاتصال
    final Map<String, dynamic> connection =
        diagnosis['connection'] as Map<String, dynamic>;
    debugPrint('🌐 الاتصال: ${connection['status']}');

    // إعدادات Firestore
    final Map<String, dynamic> firestore =
        diagnosis['firestore'] as Map<String, dynamic>;
    debugPrint('🔥 Firestore: ${firestore['status']}');

    // خدمة التحديثات الفورية
    final Map<String, dynamic> realtime =
        diagnosis['realtime_service'] as Map<String, dynamic>;
    debugPrint('⚡ التحديثات الفورية: ${realtime['status']}');

    // المجموعات
    final Map<String, dynamic> collections =
        diagnosis['collections'] as Map<String, dynamic>;
    debugPrint('📁 المجموعات: ${collections['status']}');

    // Callbacks
    final Map<String, dynamic> callbacks =
        diagnosis['callbacks'] as Map<String, dynamic>;
    debugPrint('🔄 Callbacks: ${callbacks['total_callbacks']} إجمالي');

    debugPrint('=' * 50 + '\n');
  }
}
