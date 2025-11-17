import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'delta_sync_service.dart';
import 'dependency_injection_service.dart';
import 'unified_sync_manager.dart';

// ❌ إزالة: import stream_sync_service - لم تعد مطلوبة (تم دمجها في UnifiedRepository)

/// خدمة تهيئة الخدمات مع حقن التبعيات المحسن
/// تتعامل مع تهيئة جميع الخدمات بطريقة منظمة وآمنة
class ServiceInitializer {
  factory ServiceInitializer() => _instance;
  ServiceInitializer._internal();
  static final ServiceInitializer _instance = ServiceInitializer._internal();

  // خدمة حقن التبعيات المركزية
  final DependencyInjectionService _dependencyInjection =
      DependencyInjectionService();

  // الحالة
  bool _isInitialized = false;
  bool _isInitializing = false;
  String? _currentUserId;
  WidgetRef? _ref;

  // ========== التهيئة ==========

  /// تهيئة جميع الخدمات
  Future<void> initializeServices(String userId, WidgetRef ref) async {
    if (_isInitialized && _currentUserId == userId) {
      debugPrint('الخدمات مهيأة بالفعل للمستخدم: $userId');
      return;
    }

    // منع التهيئة المتعددة المتزامنة
    if (_isInitializing) {
      debugPrint('⚠️ تهيئة الخدمات قيد التشغيل بالفعل - تخطي');
      return;
    }

    _isInitializing = true;

    try {
      debugPrint('🚀 بدء تهيئة جميع الخدمات للمستخدم: $userId');

      // التحقق من صحة المعاملات
      if (userId.isEmpty) {
        throw ArgumentError('User ID cannot be empty');
      }

      _currentUserId = userId;
      _ref = ref;

      // استخدام خدمة حقن التبعيات المركزية
      await _dependencyInjection.initialize(userId, ref);
      debugPrint('✅ تم تهيئة جميع الخدمات مع حقن التبعيات');

      // ✅ إضافة إعادة تهيئة UnifiedSyncManager مع معرف المستخدم الحقيقي
      try {
        final UnifiedSyncManager syncManager = UnifiedSyncManager();
        final Map<String, dynamic> syncInfo = syncManager.getSyncInfo();

        // التحقق من أن المدير مهيأ مع معرف المستخدم الحقيقي
        if (syncInfo['currentUserId'] != userId ||
            syncInfo['isInitialized'] != true) {
          debugPrint(
              '🔄 إعادة تهيئة UnifiedSyncManager مع معرف المستخدم الحقيقي: $userId');
          await syncManager.shutdown();
          await syncManager.initialize(userId);
          debugPrint(
              '✅ تم إعادة تهيئة UnifiedSyncManager مع معرف المستخدم الحقيقي');
        } else {
          debugPrint(
              '✅ UnifiedSyncManager مهيأ بالفعل مع معرف المستخدم الصحيح');
        }
      } catch (e) {
        debugPrint('⚠️ خطأ في إعادة تهيئة UnifiedSyncManager: $e');
        // لا نريد إيقاف العملية الأساسية بسبب فشل إعادة التهيئة
      }

      // ❌ تم إزالة: StreamSyncService - تم دمج وظائفه في UnifiedRepository
      // الآن Firestore listeners موجودة مباشرة في repository.productsStream و repository.inventoryStream
      debugPrint(
          '✅ المزامنة الفورية فعّالة عبر UnifiedRepository (Firestore → Local DB → UI)');

      _isInitialized = true;
      debugPrint('🎉 تم تهيئة جميع الخدمات بنجاح');
    } catch (e, stackTrace) {
      debugPrint('❌ خطأ في تهيئة الخدمات: $e');
      debugPrint('Stack trace: $stackTrace');

      // إعادة تعيين الحالة في حالة الخطأ
      _isInitialized = false;
      _currentUserId = null;
      _ref = null;

      rethrow;
    } finally {
      _isInitializing = false;
    }
  }

  /// إيقاف جميع الخدمات
  Future<void> shutdownServices() async {
    if (!_isInitialized) {
      return;
    }

    try {
      debugPrint('🛑 إيقاف جميع الخدمات...');

      await _dependencyInjection.shutdown();
      debugPrint('✅ تم إيقاف جميع الخدمات');

      _isInitialized = false;
      _currentUserId = null;
      _ref = null;

      debugPrint('✅ تم إيقاف جميع الخدمات بنجاح');
    } on Exception catch (e) {
      debugPrint('❌ خطأ في إيقاف الخدمات: $e');
    }
  }

  /// إعادة تهيئة الخدمات (مفيد عند تغيير المستخدم)
  Future<void> reinitializeServices(String userId, WidgetRef ref) async {
    await shutdownServices();
    await initializeServices(userId, ref);
  }

  // ========== Getters ==========

  /// الحصول على مدير المزامنة الموحد
  UnifiedSyncManager? get syncManager =>
      _dependencyInjection.unifiedSyncManager;

  /// الحصول على خدمة المزامنة التفاضلية
  DeltaSyncService? get deltaSyncService =>
      _dependencyInjection.deltaSyncService;

  /// التحقق من حالة التهيئة
  bool get isInitialized => _isInitialized;

  /// الحصول على معرف المستخدم الحالي
  String? get currentUserId => _currentUserId;

  /// الحصول على WidgetRef
  WidgetRef? get ref => _ref;

  /// الحصول على خدمة حقن التبعيات
  DependencyInjectionService get dependencyInjection => _dependencyInjection;
}
