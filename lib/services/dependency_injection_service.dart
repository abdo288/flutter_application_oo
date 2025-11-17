import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'delta_sync_service.dart';
import 'unified_sync_manager.dart';

/// خدمة حقن التبعيات المركزية
/// تتعامل مع إدارة جميع التبعيات بطريقة منظمة وآمنة
class DependencyInjectionService {
  factory DependencyInjectionService() => _instance;
  DependencyInjectionService._internal();
  static final DependencyInjectionService _instance =
      DependencyInjectionService._internal();

  // التبعيات المحقونة
  WidgetRef? _ref;
  DeltaSyncService? _deltaSyncService;
  UnifiedSyncManager? _unifiedSyncManager;

  // الحالة
  bool _isInitialized = false;
  String? _currentUserId;

  // ========== التهيئة ==========

  /// تهيئة خدمة حقن التبعيات
  Future<void> initialize(String userId, WidgetRef ref) async {
    if (_isInitialized && _currentUserId == userId) {
      debugPrint('خدمة حقن التبعيات مهيأة بالفعل للمستخدم: $userId');
      return;
    }

    try {
      debugPrint('🚀 بدء تهيئة خدمة حقن التبعيات للمستخدم: $userId');

      // التحقق من صحة المعاملات
      if (userId.isEmpty) {
        throw ArgumentError('User ID cannot be empty');
      }

      _currentUserId = userId;
      _ref = ref;

      // تهيئة الخدمات مع حقن التبعيات
      await _initializeServices();

      _isInitialized = true;
      debugPrint('✅ تم تهيئة خدمة حقن التبعيات بنجاح');
    } catch (e, stackTrace) {
      debugPrint('❌ خطأ في تهيئة خدمة حقن التبعيات: $e');
      debugPrint('Stack trace: $stackTrace');

      // إعادة تعيين الحالة في حالة الخطأ
      _isInitialized = false;
      _currentUserId = null;
      _ref = null;

      rethrow;
    }
  }

  /// تهيئة الخدمات مع حقن التبعيات
  Future<void> _initializeServices() async {
    try {
      // تهيئة DeltaSyncService مع حقن Riverpod ref
      _deltaSyncService = DeltaSyncService();
      _deltaSyncService!.initialize(_ref!);
      debugPrint('✅ تم تهيئة DeltaSyncService مع حقن التبعيات');

      // تهيئة UnifiedSyncManager مع حقن التبعيات
      _unifiedSyncManager = UnifiedSyncManager();
      await _unifiedSyncManager!.initialize(_currentUserId!);
      debugPrint('✅ تم تهيئة UnifiedSyncManager مع حقن التبعيات');

      // المزامنة الأولية ستتم تلقائياً بعد تأخير قصير في UnifiedSyncManager
      debugPrint('✅ سيتم بدء المزامنة الأولية تلقائياً خلال ثانيتين');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة الخدمات: $e');
      rethrow;
    }
  }

  /// إيقاف خدمة حقن التبعيات
  Future<void> shutdown() async {
    if (!_isInitialized) return;

    try {
      debugPrint('🛑 إيقاف خدمة حقن التبعيات...');

      // إيقاف الخدمات
      if (_unifiedSyncManager != null) {
        await _unifiedSyncManager!.shutdown();
        debugPrint('✅ تم إيقاف UnifiedSyncManager');
      }

      // تنظيف التبعيات
      _deltaSyncService = null;
      _unifiedSyncManager = null;
      _ref = null;
      _currentUserId = null;
      _isInitialized = false;

      debugPrint('✅ تم إيقاف خدمة حقن التبعيات بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في إيقاف خدمة حقن التبعيات: $e');
    }
  }

  // ========== Getters للتبعيات ==========

  /// الحصول على WidgetRef
  WidgetRef? get ref => _ref;

  /// الحصول على DeltaSyncService
  DeltaSyncService? get deltaSyncService => _deltaSyncService;

  /// الحصول على UnifiedSyncManager
  UnifiedSyncManager? get unifiedSyncManager => _unifiedSyncManager;

  // ========== معلومات الحالة ==========

  /// التحقق من حالة التهيئة
  bool get isInitialized => _isInitialized;

  /// الحصول على معرف المستخدم الحالي
  String? get currentUserId => _currentUserId;

  /// التحقق من توفر التبعية
  bool hasDependency<T>() {
    if (T == WidgetRef) return _ref != null;
    if (T == DeltaSyncService) return _deltaSyncService != null;
    if (T == UnifiedSyncManager) return _unifiedSyncManager != null;
    return false;
  }

  /// الحصول على التبعية مع التحقق من التوفر
  T? getDependency<T>() {
    if (T == WidgetRef) return _ref as T?;
    if (T == DeltaSyncService) return _deltaSyncService as T?;
    if (T == UnifiedSyncManager) return _unifiedSyncManager as T?;
    return null;
  }

  /// الحصول على التبعية مع إلقاء خطأ إذا لم تكن متوفرة
  T getRequiredDependency<T>() {
    final T? dependency = getDependency<T>();
    if (dependency == null) {
      throw StateError(
          'Required dependency $T is not available. Make sure to call initialize() first.');
    }
    return dependency;
  }
}
