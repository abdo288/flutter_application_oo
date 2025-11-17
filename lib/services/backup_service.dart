import 'dart:convert';
import 'dart:io';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/inventory_item.dart';
import '../models/product.dart';
import '../providers/riverpod/stream_inventory_riverpod_provider.dart';
import '../providers/riverpod/stream_product_riverpod_provider.dart';
import '../repositories/unified_repository.dart';

/// خدمة النسخ الاحتياطي الشاملة للبيانات
class BackupService {
  BackupService({
    required WidgetRef ref,
  }) : _ref = ref;
  final WidgetRef _ref;
  static const String _lastBackupKey = 'last_backup_time';
  static const String _autoBackupKey = 'auto_backup_enabled';
  static const String _backupFrequencyKey = 'backup_frequency';
  static const String _cloudBackupKey = 'cloud_backup_enabled';

  // إعدادات النسخ الاحتياطي
  static bool _autoBackupEnabled = false;
  static int _backupFrequency = 7; // أيام
  static bool _cloudBackupEnabled = false;
  static DateTime? _lastBackupTime;

  /// تهيئة خدمة النسخ الاحتياطي
  static Future<void> initialize() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      _autoBackupEnabled = prefs.getBool(_autoBackupKey) ?? false;
      _backupFrequency = prefs.getInt(_backupFrequencyKey) ?? 7;
      _cloudBackupEnabled = prefs.getBool(_cloudBackupKey) ?? false;

      final String? lastBackupString = prefs.getString(_lastBackupKey);
      if (lastBackupString != null) {
        _lastBackupTime = DateTime.parse(lastBackupString);
      }

      debugPrint('تم تهيئة خدمة النسخ الاحتياطي');
    } on Exception catch (_) {
      debugPrint('خطأ في تهيئة خدمة النسخ الاحتياطي: خطأ غير محدد');
    }
  }

  /// إنشاء نسخة احتياطية شاملة
  Future<BackupResult> createFullBackup({
    bool includeCloud = false,
    String? customFileName,
  }) async {
    try {
      debugPrint('بدء إنشاء النسخة الاحتياطية...');

      // جمع جميع البيانات
      final Map<String, dynamic> backupData = await _collectAllData();

      // إنشاء ملف النسخة الاحتياطية
      final File backupFile =
          await _createBackupFile(backupData, customFileName);

      // رفع النسخة الاحتياطية إلى السحابة إذا طُلب ذلك
      String? cloudUrl;
      if (includeCloud && _cloudBackupEnabled) {
        cloudUrl = await _uploadToCloud(backupFile);
      }

      // تحديث وقت آخر نسخة احتياطية
      await _updateLastBackupTime();

      debugPrint('تم إنشاء النسخة الاحتياطية بنجاح');

      return BackupResult(
        success: true,
        filePath: backupFile.path,
        cloudUrl: cloudUrl,
        fileSize: await backupFile.length(),
        timestamp: DateTime.now(),
        dataCount: _getDataCount(backupData),
      );
    } on Exception catch (_) {
      debugPrint('خطأ في إنشاء النسخة الاحتياطية: خطأ غير محدد');
      return BackupResult(
        success: false,
        error: _.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  /// إنشاء نسخة احتياطية للمنتجات فقط
  static Future<BackupResult> createProductsBackup() async {
    try {
      final UnifiedRepository repository = UnifiedRepository();
      final List<Product> products = await repository.productsStream.first;
      final Map<String, dynamic> backupData = <String, dynamic>{
        'type': 'products_only',
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'data': <String, List<Map<String, dynamic>>>{
          'products': products.map((Product p) => p.toMap()).toList(),
        },
      };

      final File backupFile =
          await _createBackupFile(backupData, 'products_backup');

      return BackupResult(
        success: true,
        filePath: backupFile.path,
        fileSize: await backupFile.length(),
        timestamp: DateTime.now(),
        dataCount: products.length,
      );
    } on Exception catch (_) {
      debugPrint('خطأ في إنشاء نسخة احتياطية للمنتجات: خطأ غير محدد');
      return BackupResult(
        success: false,
        error: _.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  /// إنشاء نسخة احتياطية للمخزون فقط
  Future<BackupResult> createInventoryBackup() async {
    try {
      final List<InventoryItem> inventory =
          _ref.read(inventoryControllerProvider).inventoryItems;
      final Map<String, dynamic> backupData = <String, dynamic>{
        'type': 'inventory_only',
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'data': <String, List<Map<String, dynamic>>>{
          'inventory': inventory.map((InventoryItem i) => i.toMap()).toList(),
        },
      };

      final File backupFile =
          await _createBackupFile(backupData, 'inventory_backup');

      return BackupResult(
        success: true,
        filePath: backupFile.path,
        fileSize: await backupFile.length(),
        timestamp: DateTime.now(),
        dataCount: inventory.length,
      );
    } on Exception catch (_) {
      debugPrint('خطأ في إنشاء نسخة احتياطية للمخزون: خطأ غير محدد');
      return BackupResult(
        success: false,
        error: _.toString(),
        timestamp: DateTime.now(),
      );
    }
  }

  /// مشاركة النسخة الاحتياطية
  static Future<bool> shareBackup(String filePath) async {
    try {
      final File file = File(filePath);
      if (!await file.exists()) {
        debugPrint('ملف النسخة الاحتياطية غير موجود');
        return false;
      }

      await Share.shareXFiles(
        <XFile>[XFile(filePath)],
        text:
            'نسخة احتياطية من تطبيق حاسبة الأرباح - ${DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now())}',
      );

      return true;
    } on Exception catch (_) {
      debugPrint('خطأ في مشاركة النسخة الاحتياطية: خطأ غير محدد');
      return false;
    }
  }

  /// رفع النسخة الاحتياطية إلى السحابة
  static Future<String?> uploadToCloud(String filePath) async {
    try {
      if (!_cloudBackupEnabled) {
        debugPrint('النسخ الاحتياطي السحابي غير مفعل');
        return null;
      }

      final File file = File(filePath);
      if (!await file.exists()) {
        debugPrint('ملف النسخة الاحتياطية غير موجود');
        return null;
      }

      final String fileName =
          'backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final Reference ref =
          FirebaseStorage.instance.ref().child('backups/$fileName');

      final UploadTask uploadTask = ref.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      debugPrint('تم رفع النسخة الاحتياطية إلى السحابة: $downloadUrl');
      return downloadUrl;
    } on Exception catch (_) {
      debugPrint('خطأ في رفع النسخة الاحتياطية إلى السحابة: خطأ غير محدد');
      return null;
    }
  }

  /// تحميل النسخة الاحتياطية من السحابة
  static Future<File?> downloadFromCloud(String url) async {
    try {
      final Reference ref = FirebaseStorage.instance.refFromURL(url);
      final Directory tempDir = await getTemporaryDirectory();
      final String fileName =
          'cloud_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final File file = File('${tempDir.path}/$fileName');

      await ref.writeToFile(file);

      debugPrint('تم تحميل النسخة الاحتياطية من السحابة');
      return file;
    } on Exception catch (_) {
      debugPrint('خطأ في تحميل النسخة الاحتياطية من السحابة: خطأ غير محدد');
      return null;
    }
  }

  /// التحقق من صحة ملف النسخة الاحتياطية
  static Future<BackupValidationResult> validateBackupFile(
      String filePath) async {
    try {
      final File file = File(filePath);
      if (!await file.exists()) {
        return BackupValidationResult(
          isValid: false,
          error: 'الملف غير موجود',
        );
      }

      final String content = await file.readAsString();
      final Map<String, dynamic> data =
          Map<String, dynamic>.from(json.decode(content) as Map);

      // التحقق من البنية الأساسية
      if (!data.containsKey('type') ||
          !data.containsKey('version') ||
          !data.containsKey('data')) {
        return BackupValidationResult(
          isValid: false,
          error: 'بنية الملف غير صحيحة',
        );
      }

      // التحقق من نوع البيانات
      final String type = (data['type'] as String?) ?? 'unknown';
      final Map<String, dynamic> backupData =
          Map<String, dynamic>.from(data['data'] as Map);

      int dataCount = 0;
      switch (type) {
        case 'full_backup':
          dataCount += (backupData['products'] as List?)?.length ?? 0;
          dataCount += (backupData['inventory'] as List?)?.length ?? 0;
          dataCount += (backupData['alerts'] as List?)?.length ?? 0;
          break;
        case 'products_only':
          dataCount = (backupData['products'] as List?)?.length ?? 0;
          break;
        case 'inventory_only':
          dataCount = (backupData['inventory'] as List?)?.length ?? 0;
          break;
      }

      return BackupValidationResult(
        isValid: true,
        type: type,
        dataCount: dataCount,
        timestamp: data['timestamp'] != null
            ? DateTime.parse((data['timestamp'] as String?) ?? '')
            : null,
        version: data['version'] as String?,
      );
    } on Exception catch (_) {
      debugPrint('خطأ في التحقق من صحة النسخة الاحتياطية: خطأ غير محدد');
      return BackupValidationResult(
        isValid: false,
        error: 'خطأ في قراءة الملف: خطأ غير محدد',
      );
    }
  }

  /// الحصول على قائمة النسخ الاحتياطية المحلية
  static Future<List<BackupInfo>> getLocalBackups() async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory backupDir = Directory('${appDir.path}/backups');

      if (!await backupDir.exists()) {
        return <BackupInfo>[];
      }

      final List<FileSystemEntity> files = backupDir.listSync();
      final List<BackupInfo> backups = <BackupInfo>[];

      for (final FileSystemEntity file in files) {
        if (file is File && file.path.endsWith('.json')) {
          final FileStat stat = await file.stat();
          final BackupValidationResult validation =
              await validateBackupFile(file.path);

          if (validation.isValid) {
            backups.add(BackupInfo(
              filePath: file.path,
              fileName: file.path.split('/').last,
              fileSize: stat.size,
              timestamp: stat.modified,
              type: validation.type ?? 'unknown',
              dataCount: validation.dataCount ?? 0,
            ));
          }
        }
      }

      // ترتيب حسب التاريخ (الأحدث أولاً)
      backups.sort(
          (BackupInfo a, BackupInfo b) => b.timestamp.compareTo(a.timestamp));

      return backups;
    } on Exception catch (_) {
      debugPrint('خطأ في الحصول على قائمة النسخ الاحتياطية: خطأ غير محدد');
      return <BackupInfo>[];
    }
  }

  /// حذف نسخة احتياطية محلية
  static Future<bool> deleteLocalBackup(String filePath) async {
    try {
      final File file = File(filePath);
      if (await file.exists()) {
        await file.delete();
        debugPrint('تم حذف النسخة الاحتياطية: $filePath');
        return true;
      }
      return false;
    } on Exception catch (_) {
      debugPrint('خطأ في حذف النسخة الاحتياطية: خطأ غير محدد');
      return false;
    }
  }

  /// تفعيل/إلغاء النسخ الاحتياطي التلقائي
  static Future<void> setAutoBackupEnabled(bool enabled) async {
    _autoBackupEnabled = enabled;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_autoBackupKey, enabled);

    if (enabled) {
      _scheduleAutoBackup();
    }
  }

  /// تعيين تكرار النسخ الاحتياطي التلقائي
  static Future<void> setBackupFrequency(int days) async {
    _backupFrequency = days;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_backupFrequencyKey, days);
  }

  /// تفعيل/إلغاء النسخ الاحتياطي السحابي
  static Future<void> setCloudBackupEnabled(bool enabled) async {
    _cloudBackupEnabled = enabled;
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cloudBackupKey, enabled);
  }

  /// التحقق من الحاجة للنسخ الاحتياطي التلقائي
  static Future<bool> shouldCreateAutoBackup() async {
    if (!_autoBackupEnabled || _lastBackupTime == null) {
      return false;
    }

    final DateTime now = DateTime.now();
    final Duration difference = now.difference(_lastBackupTime!);

    return difference.inDays >= _backupFrequency;
  }

  /// إنشاء نسخة احتياطية تلقائية
  Future<void> createAutoBackup() async {
    if (!await shouldCreateAutoBackup()) {
      return;
    }

    try {
      debugPrint('إنشاء نسخة احتياطية تلقائية...');
      final BackupResult result =
          await createFullBackup(includeCloud: _cloudBackupEnabled);

      if (result.success) {
        debugPrint('تم إنشاء النسخة الاحتياطية التلقائية بنجاح');
      } else {
        debugPrint('فشل في إنشاء النسخة الاحتياطية التلقائية: ${result.error}');
      }
    } on Exception catch (_) {
      debugPrint('خطأ في النسخ الاحتياطي التلقائي: خطأ غير محدد');
    }
  }

  // ========== الدوال المساعدة ==========

  /// جمع جميع البيانات
  Future<Map<String, dynamic>> _collectAllData() async {
    try {
      final List<Product> products =
          _ref.read(productsControllerProvider).products;
      final List<InventoryItem> inventory =
          _ref.read(inventoryControllerProvider).inventoryItems;

      // جمع إعدادات التنبيهات (إذا كانت متاحة)
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final Map<String, dynamic> alertSettings = <String, dynamic>{};

      // جمع جميع المفاتيح المتعلقة بالتنبيهات
      final Set<String> keys = prefs.getKeys();
      for (final String key in keys) {
        if (key.contains('alert') || key.contains('notification')) {
          final dynamic value = prefs.get(key);
          alertSettings[key] = value;
        }
      }

      return <String, dynamic>{
        'type': 'full_backup',
        'version': '1.0',
        'timestamp': DateTime.now().toIso8601String(),
        'app_version': '1.1.0',
        'data': <String, Object>{
          'products': products.map((Product p) => p.toMap()).toList(),
          'inventory': inventory.map((InventoryItem i) => i.toMap()).toList(),
          'alert_settings': alertSettings,
        },
      };
    } on Exception catch (_) {
      debugPrint('خطأ في جمع البيانات: خطأ غير محدد');
      rethrow;
    }
  }

  /// إنشاء ملف النسخة الاحتياطية
  static Future<File> _createBackupFile(
      Map<String, dynamic> data, String? customFileName) async {
    try {
      final Directory appDir = await getApplicationDocumentsDirectory();
      final Directory backupDir = Directory('${appDir.path}/backups');

      if (!await backupDir.exists()) {
        await backupDir.create(recursive: true);
      }

      final String timestamp =
          DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final String fileName = customFileName ?? 'backup_$timestamp.json';
      final File backupFile = File('${backupDir.path}/$fileName');

      // تحويل البيانات إلى JSON مع تنسيق جميل
      const JsonEncoder encoder = JsonEncoder.withIndent('  ');
      final String jsonString = encoder.convert(data);

      await backupFile.writeAsString(jsonString);

      debugPrint('تم إنشاء ملف النسخة الاحتياطية: ${backupFile.path}');
      return backupFile;
    } on Exception catch (_) {
      debugPrint('خطأ في إنشاء ملف النسخة الاحتياطية: خطأ غير محدد');
      rethrow;
    }
  }

  /// رفع النسخة الاحتياطية إلى السحابة
  static Future<String?> _uploadToCloud(File file) async {
    try {
      final String fileName =
          'backup_${DateTime.now().millisecondsSinceEpoch}.json';
      final Reference ref =
          FirebaseStorage.instance.ref().child('backups/$fileName');

      final UploadTask uploadTask = ref.putFile(file);
      final TaskSnapshot snapshot = await uploadTask;
      final String downloadUrl = await snapshot.ref.getDownloadURL();

      return downloadUrl;
    } on Exception catch (_) {
      debugPrint('خطأ في رفع النسخة الاحتياطية إلى السحابة: خطأ غير محدد');
      return null;
    }
  }

  /// تحديث وقت آخر نسخة احتياطية
  static Future<void> _updateLastBackupTime() async {
    _lastBackupTime = DateTime.now();
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString(_lastBackupKey, _lastBackupTime!.toIso8601String());
  }

  /// الحصول على عدد البيانات
  static int _getDataCount(Map<String, dynamic> data) {
    final Map<String, dynamic> backupData =
        data['data'] as Map<String, dynamic>;
    int count = 0;
    count += (backupData['products'] as List?)?.length ?? 0;
    count += (backupData['inventory'] as List?)?.length ?? 0;
    count += (backupData['alerts'] as List?)?.length ?? 0;
    return count;
  }

  /// جدولة النسخ الاحتياطي التلقائي
  static void _scheduleAutoBackup() {
    // يمكن إضافة منطق الجدولة هنا
    debugPrint('تم تفعيل النسخ الاحتياطي التلقائي');
  }

  // ========== Getters ==========

  static bool get autoBackupEnabled => _autoBackupEnabled;
  static int get backupFrequency => _backupFrequency;
  static bool get cloudBackupEnabled => _cloudBackupEnabled;
  static DateTime? get lastBackupTime => _lastBackupTime;

  // ========== دوال ثابتة للتوافق مع الكود الحالي ==========

  /// إنشاء مثيل من الخدمة مع المزودات المطلوبة
  static BackupService create({
    required WidgetRef ref,
  }) =>
      BackupService(
        ref: ref,
      );

  /// إنشاء نسخة احتياطية شاملة (دالة ثابتة للتوافق)
  static Future<BackupResult> createFullBackupStatic({
    required WidgetRef ref,
    bool includeCloud = false,
    String? customFileName,
  }) async {
    final BackupService service = BackupService(
      ref: ref,
    );
    return await service.createFullBackup(
      includeCloud: includeCloud,
      customFileName: customFileName,
    );
  }

  /// إنشاء نسخة احتياطية للمخزون فقط (دالة ثابتة للتوافق)
  static Future<BackupResult> createInventoryBackupStatic({
    required WidgetRef ref,
  }) async {
    final BackupService service = BackupService(
      ref: ref,
    );
    return await service.createInventoryBackup();
  }

  /// إنشاء نسخة احتياطية تلقائية (دالة ثابتة للتوافق)
  static Future<void> createAutoBackupStatic({
    required WidgetRef ref,
  }) async {
    final BackupService service = BackupService(
      ref: ref,
    );
    await service.createAutoBackup();
  }
}

/// نتيجة عملية النسخ الاحتياطي
class BackupResult {
  BackupResult({
    required this.success,
    this.filePath,
    this.cloudUrl,
    this.fileSize,
    required this.timestamp,
    this.dataCount,
    this.error,
  });
  final bool success;
  final String? filePath;
  final String? cloudUrl;
  final int? fileSize;
  final DateTime timestamp;
  final int? dataCount;
  final String? error;
}

/// نتيجة التحقق من صحة النسخة الاحتياطية
class BackupValidationResult {
  BackupValidationResult({
    required this.isValid,
    this.type,
    this.dataCount,
    this.timestamp,
    this.version,
    this.error,
  });
  final bool isValid;
  final String? type;
  final int? dataCount;
  final DateTime? timestamp;
  final String? version;
  final String? error;
}

/// معلومات النسخة الاحتياطية
class BackupInfo {
  BackupInfo({
    required this.filePath,
    required this.fileName,
    required this.fileSize,
    required this.timestamp,
    required this.type,
    required this.dataCount,
  });
  final String filePath;
  final String fileName;
  final int fileSize;
  final DateTime timestamp;
  final String type;
  final int dataCount;

  String get formattedSize {
    if (fileSize < 1024) {
      return '$fileSize B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }

  String get formattedDate => DateFormat('yyyy-MM-dd HH:mm').format(timestamp);
}
