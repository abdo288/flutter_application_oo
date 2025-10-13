import 'dart:async';

import 'package:flutter/foundation.dart';

import '../providers/stream_inventory_provider.dart';
import '../providers/stream_product_provider.dart';
import 'backup_service.dart';
import 'connectivity_service.dart';

/// خدمة النسخ الاحتياطي التلقائي
class AutoBackupService {
  static Timer? _backupTimer;
  static Timer? _checkTimer;
  static bool _isInitialized = false;

  /// تهيئة خدمة النسخ الاحتياطي التلقائي
  static Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      await BackupService.initialize();
      _startPeriodicCheck();
      _isInitialized = true;
      debugPrint('تم تهيئة خدمة النسخ الاحتياطي التلقائي');
    } catch (e) {
      debugPrint('خطأ في تهيئة خدمة النسخ الاحتياطي التلقائي: $e');
    }
  }

  /// بدء الفحص الدوري للنسخ الاحتياطي
  static void _startPeriodicCheck() {
    // فحص كل ساعة
    _checkTimer = Timer.periodic(const Duration(hours: 1), (Timer timer) {
      _checkAndCreateBackup();
    });

    // فحص فوري عند بدء التطبيق
    _checkAndCreateBackup();
  }

  /// فحص الحاجة لإنشاء نسخة احتياطية وإنشاؤها
  static Future<void> _checkAndCreateBackup({
    StreamProductProvider? productProvider,
    StreamInventoryProvider? inventoryProvider,
  }) async {
    try {
      // التحقق من تفعيل النسخ الاحتياطي التلقائي
      if (!BackupService.autoBackupEnabled) {
        return;
      }

      // التحقق من الاتصال بالإنترنت
      final bool isOnline = ConnectivityService.isOnline;
      if (!isOnline) {
        debugPrint('لا يوجد اتصال بالإنترنت - تأجيل النسخ الاحتياطي التلقائي');
        return;
      }

      // التحقق من الحاجة للنسخ الاحتياطي
      final bool shouldBackup = await BackupService.shouldCreateAutoBackup();
      if (!shouldBackup) {
        return;
      }

      debugPrint('بدء النسخ الاحتياطي التلقائي...');

      // إنشاء النسخة الاحتياطية (تخطي إذا لم يكن هناك providers)
      if (productProvider != null && inventoryProvider != null) {
        await BackupService.createAutoBackupStatic(
          productProvider: productProvider,
          inventoryProvider: inventoryProvider,
        );
        debugPrint('تم إنشاء النسخة الاحتياطية التلقائية بنجاح');
      } else {
        debugPrint('تخطي النسخ الاحتياطي التلقائي - لا يوجد providers');
      }
    } catch (e) {
      debugPrint('خطأ في النسخ الاحتياطي التلقائي: $e');
    }
  }

  /// إنشاء نسخة احتياطية فورية
  static Future<bool> createImmediateBackup({
    required StreamProductProvider productProvider,
    required StreamInventoryProvider inventoryProvider,
  }) async {
    try {
      final BackupResult result = await BackupService.createFullBackupStatic(
        productProvider: productProvider,
        inventoryProvider: inventoryProvider,
        includeCloud: BackupService.cloudBackupEnabled,
      );

      if (result.success) {
        debugPrint('تم إنشاء النسخة الاحتياطية الفورية بنجاح');
        return true;
      } else {
        debugPrint('فشل في إنشاء النسخة الاحتياطية الفورية: ${result.error}');
        return false;
      }
    } catch (e) {
      debugPrint('خطأ في النسخة الاحتياطية الفورية: $e');
      return false;
    }
  }

  /// إيقاف خدمة النسخ الاحتياطي التلقائي
  static void stop() {
    _backupTimer?.cancel();
    _checkTimer?.cancel();
    _backupTimer = null;
    _checkTimer = null;
    _isInitialized = false;
    debugPrint('تم إيقاف خدمة النسخ الاحتياطي التلقائي');
  }

  /// إعادة تشغيل خدمة النسخ الاحتياطي التلقائي
  static void restart() {
    stop();
    initialize();
  }

  /// التحقق من حالة الخدمة
  static bool get isRunning => _isInitialized && _checkTimer?.isActive == true;

  // ========== دوال مساعدة للتهيئة ==========

  /// تهيئة خدمة النسخ الاحتياطي التلقائي مع providers
  static Future<void> initializeWithProviders({
    required StreamProductProvider productProvider,
    required StreamInventoryProvider inventoryProvider,
  }) async {
    if (_isInitialized) return;

    try {
      await BackupService.initialize();
      _startPeriodicCheckWithProviders(
        productProvider: productProvider,
        inventoryProvider: inventoryProvider,
      );
      _isInitialized = true;
      debugPrint('تم تهيئة خدمة النسخ الاحتياطي التلقائي مع providers');
    } catch (e) {
      debugPrint('خطأ في تهيئة خدمة النسخ الاحتياطي التلقائي: $e');
    }
  }

  /// بدء الفحص الدوري للنسخ الاحتياطي مع providers
  static void _startPeriodicCheckWithProviders({
    required StreamProductProvider productProvider,
    required StreamInventoryProvider inventoryProvider,
  }) {
    // فحص كل ساعة
    _checkTimer = Timer.periodic(const Duration(hours: 1), (Timer timer) {
      _checkAndCreateBackup(
        productProvider: productProvider,
        inventoryProvider: inventoryProvider,
      );
    });

    // فحص فوري عند بدء التطبيق
    _checkAndCreateBackup(
      productProvider: productProvider,
      inventoryProvider: inventoryProvider,
    );
  }
}
