import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة تتبع حالة المزامنة وحفظ آخر وقت مزامنة
class SyncStateService {
  factory SyncStateService() => _instance;
  SyncStateService._internal();
  static final SyncStateService _instance = SyncStateService._internal();

  static const String _lastProductSyncKey = 'last_product_sync';
  static const String _lastInventorySyncKey = 'last_inventory_sync';
  static const String _lastFullSyncKey = 'last_full_sync';
  static const String _syncVersionKey = 'sync_version';

  SharedPreferences? _prefs;
  DateTime? _lastProductSync;
  DateTime? _lastInventorySync;
  DateTime? _lastFullSync;
  String? _syncVersion;

  /// تهيئة الخدمة
  Future<void> initialize() async {
    try {
      _prefs = await SharedPreferences.getInstance();
      await _loadSyncState();
      debugPrint('✅ تم تهيئة SyncStateService بنجاح');
    } on Exception catch (e) {
      debugPrint('❌ خطأ في تهيئة SyncStateService: $e');
    }
  }

  /// تحميل حالة المزامنة من التخزين المحلي
  Future<void> _loadSyncState() async {
    try {
      if (_prefs == null) return;

      final String? lastProductSyncStr = _prefs!.getString(_lastProductSyncKey);
      final String? lastInventorySyncStr =
          _prefs!.getString(_lastInventorySyncKey);
      final String? lastFullSyncStr = _prefs!.getString(_lastFullSyncKey);
      final String? syncVersion = _prefs!.getString(_syncVersionKey);

      _lastProductSync = lastProductSyncStr != null
          ? DateTime.tryParse(lastProductSyncStr)
          : null;
      _lastInventorySync = lastInventorySyncStr != null
          ? DateTime.tryParse(lastInventorySyncStr)
          : null;
      _lastFullSync =
          lastFullSyncStr != null ? DateTime.tryParse(lastFullSyncStr) : null;
      _syncVersion = syncVersion;

      debugPrint('📊 حالة المزامنة المحملة:');
      debugPrint('  - آخر مزامنة منتجات: $_lastProductSync');
      debugPrint('  - آخر مزامنة مخزون: $_lastInventorySync');
      debugPrint('  - آخر مزامنة شاملة: $_lastFullSync');
      debugPrint('  - إصدار المزامنة: $_syncVersion');
    } on Exception catch (e) {
      debugPrint('❌ خطأ في تحميل حالة المزامنة: $e');
    }
  }

  /// حفظ حالة المزامنة في التخزين المحلي
  Future<void> _saveSyncState() async {
    try {
      if (_prefs == null) return;

      await _prefs!.setString(
          _lastProductSyncKey, _lastProductSync?.toIso8601String() ?? '');
      await _prefs!.setString(
          _lastInventorySyncKey, _lastInventorySync?.toIso8601String() ?? '');
      await _prefs!
          .setString(_lastFullSyncKey, _lastFullSync?.toIso8601String() ?? '');
      await _prefs!.setString(_syncVersionKey, _syncVersion ?? '1.0.0');
    } on Exception catch (e) {
      debugPrint('❌ خطأ في حفظ حالة المزامنة: $e');
    }
  }

  /// تحديث آخر وقت مزامنة للمنتجات
  Future<void> updateLastProductSync() async {
    _lastProductSync = DateTime.now();
    await _saveSyncState();
    debugPrint('📦 تم تحديث آخر مزامنة للمنتجات: $_lastProductSync');
  }

  /// تحديث آخر وقت مزامنة للمخزون
  Future<void> updateLastInventorySync() async {
    _lastInventorySync = DateTime.now();
    await _saveSyncState();
    debugPrint('📦 تم تحديث آخر مزامنة للمخزون: $_lastInventorySync');
  }

  /// تحديث آخر وقت مزامنة شاملة
  Future<void> updateLastFullSync() async {
    _lastFullSync = DateTime.now();
    await _saveSyncState();
    debugPrint('🔄 تم تحديث آخر مزامنة شاملة: $_lastFullSync');
  }

  /// تحديث إصدار المزامنة
  Future<void> updateSyncVersion(String version) async {
    _syncVersion = version;
    await _saveSyncState();
    debugPrint('📋 تم تحديث إصدار المزامنة: $version');
  }

  /// الحصول على آخر وقت مزامنة للمنتجات
  DateTime? get lastProductSync => _lastProductSync;

  /// الحصول على آخر وقت مزامنة للمخزون
  DateTime? get lastInventorySync => _lastInventorySync;

  /// الحصول على آخر وقت مزامنة شاملة
  DateTime? get lastFullSync => _lastFullSync;

  /// الحصول على إصدار المزامنة
  String? get syncVersion => _syncVersion;

  /// التحقق من الحاجة لمزامنة المنتجات
  bool needsProductSync({Duration? threshold}) {
    if (_lastProductSync == null) return true;

    final Duration timeSinceLastSync =
        DateTime.now().difference(_lastProductSync!);
    final Duration syncThreshold = threshold ?? const Duration(minutes: 5);

    return timeSinceLastSync > syncThreshold;
  }

  /// التحقق من الحاجة لمزامنة المخزون
  bool needsInventorySync({Duration? threshold}) {
    if (_lastInventorySync == null) return true;

    final Duration timeSinceLastSync =
        DateTime.now().difference(_lastInventorySync!);
    final Duration syncThreshold = threshold ?? const Duration(minutes: 5);

    return timeSinceLastSync > syncThreshold;
  }

  /// التحقق من الحاجة لمزامنة شاملة
  bool needsFullSync({Duration? threshold}) {
    if (_lastFullSync == null) return true;

    final Duration timeSinceLastSync =
        DateTime.now().difference(_lastFullSync!);
    final Duration syncThreshold = threshold ?? const Duration(hours: 1);

    return timeSinceLastSync > syncThreshold;
  }

  /// الحصول على معلومات حالة المزامنة
  Map<String, dynamic> getSyncStateInfo() => <String, dynamic>{
        'lastProductSync': _lastProductSync?.toIso8601String(),
        'lastInventorySync': _lastInventorySync?.toIso8601String(),
        'lastFullSync': _lastFullSync?.toIso8601String(),
        'syncVersion': _syncVersion,
        'needsProductSync': needsProductSync(),
        'needsInventorySync': needsInventorySync(),
        'needsFullSync': needsFullSync(),
        'timeSinceLastProductSync': _lastProductSync != null
            ? DateTime.now().difference(_lastProductSync!).inMinutes
            : null,
        'timeSinceLastInventorySync': _lastInventorySync != null
            ? DateTime.now().difference(_lastInventorySync!).inMinutes
            : null,
        'timeSinceLastFullSync': _lastFullSync != null
            ? DateTime.now().difference(_lastFullSync!).inHours
            : null,
      };

  /// إعادة تعيين حالة المزامنة
  Future<void> resetSyncState() async {
    try {
      _lastProductSync = null;
      _lastInventorySync = null;
      _lastFullSync = null;
      _syncVersion = '1.0.0';

      await _saveSyncState();
      debugPrint('🔄 تم إعادة تعيين حالة المزامنة');
    } on Exception catch (e) {
      debugPrint('❌ خطأ في إعادة تعيين حالة المزامنة: $e');
    }
  }

  /// تنظيف البيانات القديمة
  Future<void> cleanup() async {
    try {
      // يمكن إضافة منطق لتنظيف البيانات القديمة هنا
      debugPrint('🧹 تم تنظيف SyncStateService');
    } on Exception catch (e) {
      debugPrint('❌ خطأ في تنظيف SyncStateService: $e');
    }
  }

  /// الحصول على آخر وقت مزامنة لنوع معين
  static Future<DateTime?> getLastSync(String syncType) async {
    try {
      final SyncStateService instance = SyncStateService();
      await instance.initialize();

      switch (syncType) {
        case 'products':
          return instance.lastProductSync;
        case 'inventory':
          return instance.lastInventorySync;
        case 'full':
          return instance.lastFullSync;
        default:
          debugPrint('⚠️ نوع مزامنة غير معروف: $syncType');
          return null;
      }
    } on Exception catch (e) {
      debugPrint('❌ خطأ في الحصول على آخر مزامنة: $e');
      return null;
    }
  }

  /// تحديث آخر وقت مزامنة لنوع معين
  static Future<void> setLastSync(String syncType, DateTime timestamp) async {
    try {
      final SyncStateService instance = SyncStateService();
      await instance.initialize();

      switch (syncType) {
        case 'products':
          instance._lastProductSync = timestamp;
          break;
        case 'inventory':
          instance._lastInventorySync = timestamp;
          break;
        case 'full':
          instance._lastFullSync = timestamp;
          break;
        default:
          debugPrint('⚠️ نوع مزامنة غير معروف: $syncType');
          return;
      }

      await instance._saveSyncState();
      debugPrint('✅ تم تحديث آخر مزامنة لـ $syncType: $timestamp');
    } on Exception catch (e) {
      debugPrint('❌ خطأ في تحديث آخر مزامنة: $e');
    }
  }
}
