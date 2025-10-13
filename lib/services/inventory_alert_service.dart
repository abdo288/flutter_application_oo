import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:profit_calculator/models/inventory_item.dart';
import 'package:uuid/uuid.dart';

import '../models/alert_settings.dart';
import '../models/inventory_alert.dart';
import '../providers/stream_inventory_provider.dart';

/// خدمة تنبيهات المخزون
class InventoryAlertService {
  static final FirebaseFirestore _db = FirebaseFirestore.instance;
  static final CollectionReference _alertsCollection =
      _db.collection('inventory_alerts');
  static final CollectionReference _settingsCollection =
      _db.collection('alert_settings');

  /// إعدادات التنبيهات الافتراضية
  static final AlertSettings _defaultSettings = AlertSettings();

  /// فحص المخزون وإنشاء التنبيهات
  static Future<List<InventoryAlert>> checkInventoryAlerts(
      StreamInventoryProvider inventoryProvider) async {
    try {
      final List<InventoryItem> inventoryItems =
          inventoryProvider.inventoryItems;
      final AlertSettings settings = await getAlertSettings();
      final List<InventoryAlert> alerts = <InventoryAlert>[];

      for (final InventoryItem item in inventoryItems) {
        // فحص نفاد الكمية
        if (settings.enableOutOfStockAlert && item.isOutOfStock()) {
          final InventoryAlert? alert = await _createAlert(
            productName: item.name,
            alertType: AlertType.outOfStock,
            currentQuantity: 0,
            threshold: 0,
          );
          if (alert != null) alerts.add(alert);
        }

        // فحص الحد الأدنى
        if (settings.enableLowStockAlert &&
            !item.isOutOfStock() &&
            item.quantity <= settings.lowStockThreshold) {
          final InventoryAlert? alert = await _createAlert(
            productName: item.name,
            alertType: AlertType.lowStock,
            currentQuantity: item.quantity,
            threshold: settings.lowStockThreshold,
          );
          if (alert != null) alerts.add(alert);
        }

        // فحص قرب الانتهاء (إذا كان مفعلاً)
        if (settings.enableExpiringAlert) {
          if (item.expiryDate != null) {
            final DateTime now = DateTime.now();
            final int daysUntilExpiry = item.expiryDate!.difference(now).inDays;
            if (daysUntilExpiry <= settings.expiringDaysThreshold &&
                daysUntilExpiry >= 0) {
              final InventoryAlert? alert = await _createAlert(
                productName: item.name,
                alertType: AlertType.expiringSoon,
                currentQuantity: item.quantity,
                threshold: settings.expiringDaysThreshold,
                description: 'ينتهي خلال $daysUntilExpiry يوم',
              );
              if (alert != null) alerts.add(alert);
            }
          }
        }
      }

      return alerts;
    } on Exception catch (e) {
      debugPrint('خطأ في فحص تنبيهات المخزون: $e');
      return <InventoryAlert>[];
    }
  }

  /// إنشاء تنبيه جديد
  static Future<InventoryAlert?> _createAlert({
    required String productName,
    required AlertType alertType,
    required int currentQuantity,
    required int threshold,
    String? description,
  }) async {
    try {
      // التحقق من وجود تنبيه مشابه غير مقروء
      final InventoryAlert? existingAlert =
          await _getExistingAlert(productName, alertType);
      if (existingAlert != null) {
        // تحديث التنبيه الموجود بدلاً من إنشاء جديد
        await _updateExistingAlert(existingAlert, currentQuantity, description);
        return existingAlert;
      }

      // التحقق من وجود تنبيهات قديمة للمنتج نفسه وحذفها
      await _cleanupOldAlerts(productName, alertType);

      final InventoryAlert alert = InventoryAlert(
        productName: productName,
        alertType: alertType,
        currentQuantity: currentQuantity,
        threshold: threshold,
        alertDate: DateTime.now(),
        description: description,
      );

      final String uniqueId = const Uuid().v4();
      alert.id = uniqueId;

      await _alertsCollection.doc(uniqueId).set(alert.toMap());
      debugPrint('تم إنشاء تنبيه جديد: ${alert.alertMessage}');

      return alert;
    } on Exception catch (e) {
      debugPrint('خطأ في إنشاء التنبيه: $e');
      return null;
    }
  }

  /// الحصول على تنبيه موجود
  static Future<InventoryAlert?> _getExistingAlert(
      String productName, AlertType alertType) async {
    try {
      final QuerySnapshot<Object?> snapshot = await _alertsCollection
          .where('productName', isEqualTo: productName)
          .where('alertType', isEqualTo: alertType.name)
          .where('isRead', isEqualTo: false)
          .limit(1)
          .get();

      if (snapshot.docs.isNotEmpty) {
        final Map<String, dynamic> data =
            snapshot.docs.first.data() as Map<String, dynamic>;
        return InventoryAlert.fromMap(<String, dynamic>{
          'id': snapshot.docs.first.id,
          ...data,
        });
      }
      return null;
    } on Exception catch (e) {
      debugPrint('خطأ في البحث عن تنبيه موجود: $e');
      return null;
    }
  }

  /// الحصول على جميع التنبيهات
  static Future<List<InventoryAlert>> getAllAlerts() async {
    try {
      final QuerySnapshot<Object?> snapshot =
          await _alertsCollection.orderBy('alertDate', descending: true).get();

      return snapshot.docs.map((QueryDocumentSnapshot<Object?> doc) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return InventoryAlert.fromMap(<String, dynamic>{
          'id': doc.id,
          ...data,
        });
      }).toList();
    } on Exception catch (e) {
      debugPrint('خطأ في جلب التنبيهات: $e');
      return <InventoryAlert>[];
    }
  }

  /// الحصول على التنبيهات غير المقروءة
  static Future<List<InventoryAlert>> getUnreadAlerts() async {
    try {
      final QuerySnapshot<Object?> snapshot = await _alertsCollection
          .where('isRead', isEqualTo: false)
          .orderBy('alertDate', descending: true)
          .get();

      return snapshot.docs.map((QueryDocumentSnapshot<Object?> doc) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        return InventoryAlert.fromMap(<String, dynamic>{
          'id': doc.id,
          ...data,
        });
      }).toList();
    } on Exception catch (e) {
      debugPrint('خطأ في جلب التنبيهات غير المقروءة: $e');
      return <InventoryAlert>[];
    }
  }

  /// تحديد التنبيه كمقروء
  static Future<void> markAlertAsRead(String alertId) async {
    try {
      await _alertsCollection
          .doc(alertId)
          .update(<Object, Object?>{'isRead': true});
      debugPrint('تم تحديد التنبيه كمقروء: $alertId');
    } on Exception catch (e) {
      debugPrint('خطأ في تحديد التنبيه كمقروء: $e');
      rethrow;
    }
  }

  /// تحديد جميع التنبيهات كمقروءة
  static Future<void> markAllAlertsAsRead() async {
    try {
      final List<InventoryAlert> unreadAlerts = await getUnreadAlerts();
      final WriteBatch batch = _db.batch();

      for (final InventoryAlert alert in unreadAlerts) {
        if (alert.id != null) {
          batch.update(_alertsCollection.doc(alert.id!),
              <String, dynamic>{'isRead': true});
        }
      }

      await batch.commit();
      debugPrint('تم تحديد جميع التنبيهات كمقروءة');
    } on Exception catch (e) {
      debugPrint('خطأ في تحديد جميع التنبيهات كمقروءة: $e');
      rethrow;
    }
  }

  /// حذف تنبيه
  static Future<void> deleteAlert(String alertId) async {
    try {
      await _alertsCollection.doc(alertId).delete();
      debugPrint('تم حذف التنبيه: $alertId');
    } on Exception catch (e) {
      debugPrint('خطأ في حذف التنبيه: $e');
      rethrow;
    }
  }

  /// حذف جميع التنبيهات المقروءة
  static Future<void> deleteReadAlerts() async {
    try {
      final QuerySnapshot<Object?> readAlerts =
          await _alertsCollection.where('isRead', isEqualTo: true).get();

      final WriteBatch batch = _db.batch();
      for (final QueryDocumentSnapshot<Object?> doc in readAlerts.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
      debugPrint('تم حذف جميع التنبيهات المقروءة');
    } on Exception catch (e) {
      debugPrint('خطأ في حذف التنبيهات المقروءة: $e');
      rethrow;
    }
  }

  /// الحصول على إعدادات التنبيهات
  static Future<AlertSettings> getAlertSettings() async {
    try {
      final DocumentSnapshot<Object?> snapshot =
          await _settingsCollection.doc('default').get();

      if (snapshot.exists) {
        final Map<String, dynamic> data =
            snapshot.data() as Map<String, dynamic>;
        return AlertSettings.fromMap(data);
      } else {
        // إنشاء الإعدادات الافتراضية إذا لم تكن موجودة
        await saveAlertSettings(_defaultSettings);
        return _defaultSettings;
      }
    } on Exception catch (e) {
      debugPrint('خطأ في جلب إعدادات التنبيهات: $e');
      return _defaultSettings;
    }
  }

  /// حفظ إعدادات التنبيهات
  static Future<void> saveAlertSettings(AlertSettings settings) async {
    try {
      if (!settings.isValid()) {
        throw ArgumentError('إعدادات التنبيهات غير صحيحة');
      }

      await _settingsCollection.doc('default').set(settings.toMap());
      debugPrint('تم حفظ إعدادات التنبيهات بنجاح');
    } on Exception catch (e) {
      debugPrint('خطأ في حفظ إعدادات التنبيهات: $e');
      rethrow;
    }
  }

  /// الحصول على عدد التنبيهات غير المقروءة
  static Future<int> getUnreadAlertsCount() async {
    try {
      final QuerySnapshot<Object?> snapshot =
          await _alertsCollection.where('isRead', isEqualTo: false).get();

      return snapshot.docs.length;
    } on Exception catch (e) {
      debugPrint('خطأ في جلب عدد التنبيهات غير المقروءة: $e');
      return 0;
    }
  }

  /// تحديث تنبيه موجود
  static Future<void> _updateExistingAlert(
    InventoryAlert existingAlert,
    int currentQuantity,
    String? description,
  ) async {
    try {
      if (existingAlert.id != null) {
        await _alertsCollection.doc(existingAlert.id!).update(<Object, Object?>{
          'currentQuantity': currentQuantity,
          'description': description,
          'alertDate': DateTime.now().toIso8601String(),
        });
        debugPrint('تم تحديث التنبيه الموجود: ${existingAlert.productName}');
      }
    } on Exception catch (e) {
      debugPrint('خطأ في تحديث التنبيه الموجود: $e');
    }
  }

  /// تنظيف التنبيهات القديمة للمنتج
  static Future<void> _cleanupOldAlerts(
      String productName, AlertType alertType) async {
    try {
      // البحث عن التنبيهات القديمة المقروءة للمنتج نفسه
      final QuerySnapshot<Object?> oldAlerts = await _alertsCollection
          .where('productName', isEqualTo: productName)
          .where('alertType', isEqualTo: alertType.name)
          .where('isRead', isEqualTo: true)
          .get();

      if (oldAlerts.docs.length > 5) {
        // الاحتفاظ بآخر 5 تنبيهات مقروءة فقط
        final WriteBatch batch = _db.batch();
        final List<QueryDocumentSnapshot<Object?>> sortedDocs = oldAlerts.docs
            .toList()
          ..sort((QueryDocumentSnapshot<Object?> a,
              QueryDocumentSnapshot<Object?> b) {
            final Map<String, dynamic> dataA = a.data() as Map<String, dynamic>;
            final Map<String, dynamic> dataB = b.data() as Map<String, dynamic>;
            final DateTime dateA = DateTime.parse(dataA['alertDate'] as String);
            final DateTime dateB = DateTime.parse(dataB['alertDate'] as String);
            return dateB.compareTo(dateA);
          });

        // حذف التنبيهات الأقدم (الاحتفاظ بآخر 5 فقط)
        for (int i = 5; i < sortedDocs.length; i++) {
          batch.delete(sortedDocs[i].reference);
        }

        await batch.commit();
        debugPrint(
            'تم حذف ${sortedDocs.length - 5} تنبيه قديم للمنتج: $productName');
      }
    } on Exception catch (e) {
      debugPrint('خطأ في تنظيف التنبيهات القديمة: $e');
    }
  }

  /// تنظيف جميع التنبيهات القديمة
  static Future<void> cleanupOldAlerts() async {
    try {
      final DateTime cutoffDate =
          DateTime.now().subtract(const Duration(days: 30));

      final QuerySnapshot<Object?> oldAlerts = await _alertsCollection
          .where('alertDate', isLessThan: cutoffDate.toIso8601String())
          .where('isRead', isEqualTo: true)
          .get();

      if (oldAlerts.docs.isNotEmpty) {
        final WriteBatch batch = _db.batch();
        for (final QueryDocumentSnapshot<Object?> doc in oldAlerts.docs) {
          batch.delete(doc.reference);
        }
        await batch.commit();
        debugPrint('تم حذف ${oldAlerts.docs.length} تنبيه قديم');
      }
    } on Exception catch (e) {
      debugPrint('خطأ في تنظيف التنبيهات القديمة: $e');
    }
  }

  /// الحصول على إحصائيات التنبيهات
  static Future<Map<String, int>> getAlertStatistics() async {
    try {
      final QuerySnapshot<Object?> allAlerts = await _alertsCollection.get();
      final QuerySnapshot<Object?> unreadAlerts =
          await _alertsCollection.where('isRead', isEqualTo: false).get();

      int outOfStockCount = 0;
      int lowStockCount = 0;
      int expiringCount = 0;

      for (final QueryDocumentSnapshot<Object?> doc in allAlerts.docs) {
        final Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
        final String alertType = data['alertType'] as String;

        switch (alertType) {
          case 'outOfStock':
            outOfStockCount++;
            break;
          case 'lowStock':
            lowStockCount++;
            break;
          case 'expiringSoon':
            expiringCount++;
            break;
        }
      }

      return <String, int>{
        'total': allAlerts.docs.length,
        'unread': unreadAlerts.docs.length,
        'outOfStock': outOfStockCount,
        'lowStock': lowStockCount,
        'expiring': expiringCount,
      };
    } on Exception catch (e) {
      debugPrint('خطأ في جلب إحصائيات التنبيهات: $e');
      return <String, int>{
        'total': 0,
        'unread': 0,
        'outOfStock': 0,
        'lowStock': 0,
        'expiring': 0,
      };
    }
  }

  /// الحصول على مرجع مجموعة التنبيهات للاستماع للتغييرات
  static CollectionReference get alertsCollection => _alertsCollection;
}
