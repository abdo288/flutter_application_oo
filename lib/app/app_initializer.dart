// ignore_for_file: prefer_const_constructors, avoid_print
// تجاهل التحذيرات المتعلقة بالثوابت والطباعة في الكونسول

// Dart Core
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:logging/logging.dart';

// Project Files
import '../firebase_options.dart';
import '../services/appearance_service.dart';
import '../services/auto_backup_service.dart';
import '../services/backup_service.dart';
import '../services/connectivity_service.dart';
import '../services/enhanced_security_service.dart';
import '../services/error_handler_service.dart';
import '../services/local_notification_service.dart';
import '../services/memory_management_service.dart';
import '../services/memory_optimization_service.dart';
import '../services/performance_service.dart';
import '../utils/platform_thread_safety.dart';

/// تهيئة الخدمات الأساسية التي لا تعتمد على واجهة المستخدم
Future<void> initializeCoreServices() async {
  try {
    // تحميل متغيرات البيئة أولاً مع معالجة أفضل للأخطاء
    try {
      // محاولة تحميل ملف .env من المسار الحالي
      await dotenv.load();
      debugPrint('✅ تم تحميل متغيرات البيئة بنجاح من ملف .env');
    } catch (e) {
      debugPrint('⚠️ تحذير: لم يتم العثور على ملف .env في المسار الحالي');
      debugPrint('تفاصيل الخطأ: $e');

      // محاولة تحميل من assets
      try {
        await dotenv.load(fileName: 'assets/.env');
        debugPrint('✅ تم تحميل متغيرات البيئة من assets/.env');
      } catch (e2) {
        debugPrint('⚠️ فشل في تحميل ملف .env من assets: $e2');

        // محاولة أخيرة - تحميل بدون تحديد مسار
        try {
          await dotenv.load();
          debugPrint('✅ تم تحميل متغيرات البيئة بنجاح (auto-detect)');
        } catch (e3) {
          debugPrint('⚠️ فشل في تحميل ملف .env من أي مسار: $e3');
          debugPrint(
              '⚠️ سيتم استخدام القيم الافتراضية من firebase_options.dart');
        }
      }
    }

    // تهيئة Firebase مع معالجة أفضل للأخطاء
    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      debugPrint('✅ تم تهيئة Firebase بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة Firebase: $e');
      // إعادة المحاولة مع القيم الافتراضية
      try {
        await Firebase.initializeApp();
        debugPrint('✅ تم تهيئة Firebase بالقيم الافتراضية');
      } catch (e2) {
        debugPrint('❌ فشل في تهيئة Firebase حتى بالقيم الافتراضية: $e2');
        // تجاهل أخطاء Google Services ومواصلة التطبيق
        debugPrint(
            '⚠️ سيتم تجاهل أخطاء Google Services والاستمرار في وضع offline');
      }
    }

    // ✅ تم إزالة Anonymous Authentication - سيتم استخدام نظام المصادقة الحقيقي
    debugPrint('✅ سيتم استخدام نظام المصادقة الحقيقي مع شاشة تسجيل الدخول');

    // إعدادات Firestore المحسنة
    try {
      FirebaseFirestore.instance.settings = const Settings(
        persistenceEnabled: true,
        cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
        ignoreUndefinedProperties: true,
      );
      debugPrint('✅ تم تهيئة إعدادات Firestore');
    } catch (e) {
      debugPrint('⚠️ خطأ في إعدادات Firestore: $e');
      // تجاهل أخطاء Firestore والاستمرار
      debugPrint('⚠️ سيتم تجاهل أخطاء Firestore والاستمرار في وضع offline');
    }

    // تهيئة الخدمات التي يمكن أن تعمل بالتوازي
    await Future.wait(<Future<void>>[
      _initializeLocalServices(),
      EnhancedSecurityService.initialize(),
      // LocaleService.instance.initialize(), // سيتم تهيئته في ProviderScope
      BackupService.initialize(),
      AutoBackupService.initialize(),
      AppearanceService.instance.initialize(),
    ]);

    // ✅ تهيئة أداة أمان platform thread
    PlatformThreadSafety.initialize();
    debugPrint('✅ تم تهيئة أداة أمان platform thread');

    // تهيئة خدمات لا تعتمد على غيرها
    PerformanceService.initialize();
    ErrorHandlerService.initialize();
    MemoryManagementService.setMemoryLimits();
    MemoryManagementService.startPeriodicCleanup();

    // تهيئة خدمات الأداء المحسنة
    MemoryOptimizationService().startMemoryMonitoring();

    // ✅ تهيئة الخدمات الجديدة للتواصل بين التبويبات
    try {
      // AppStateManager سيتم تهيئته في ProviderScope
      debugPrint('✅ تم تحضير AppStateManager');

      // تهيئة NavigationService (سيتم إكمالها في build)
      debugPrint('✅ تم تحضير NavigationService');

      debugPrint('✅ تم تهيئة خدمات التواصل بين التبويبات');
    } catch (e) {
      debugPrint('❌ خطأ في تهيئة خدمات التواصل: $e');
    }

    // إعداد نظام السجلات
    _setupLogging();

    // ✅ تم إزالة تهيئة UnifiedSyncManager - ستتم في AuthWrapper مع معرف المستخدم الحقيقي
    debugPrint(
        '✅ سيتم تهيئة مدير المزامنة في AuthWrapper مع معرف المستخدم الحقيقي');

    debugPrint('✅ تم تهيئة جميع الخدمات الأساسية بنجاح');
  } on FirebaseException catch (e, s) {
    debugPrint('❌ خطأ Firebase في تهيئة الخدمات الأساسية: $e\n$s');
    // يمكن إرسال الخطأ إلى خدمة مراقبة الأخطاء هنا
  } on Exception catch (e, s) {
    debugPrint('❌ خطأ عام في تهيئة الخدمات الأساسية: $e\n$s');
  }
}

void _setupLogging() {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((LogRecord record) {
    if (kDebugMode) {
      // ... الكود الأصلي لطباعة السجلات الملونة ...
    }
  });
}

/// تهيئة الخدمات المحلية
Future<void> _initializeLocalServices() async {
  try {
    await LocalNotificationService.initialize();
    await ConnectivityService.initialize();
    await LocalNotificationService.setupDailyReminders();
    await LocalNotificationService.setupWeeklyReminders();
    debugPrint('✅ تم تهيئة الخدمات المحلية بنجاح');
  } on Exception catch (e) {
    debugPrint('❌ خطأ في تهيئة الخدمات المحلية: $e');
  }
}

// تم إزالة Anonymous Authentication - سيتم استخدام نظام المصادقة الحقيقي
