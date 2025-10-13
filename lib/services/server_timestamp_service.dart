import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// خدمة إدارة التوقيتات الموثوقة من الخادم
class ServerTimestampService {
  /// الحصول على توقيت الخادم الحالي
  static FieldValue get serverTimestamp => FieldValue.serverTimestamp();

  /// إنشاء بيانات مع توقيت الخادم
  static Map<String, dynamic> createDataWithServerTimestamp(
      Map<String, dynamic> data) {
    final Map<String, dynamic> dataWithTimestamp =
        Map<String, dynamic>.from(data);
    dataWithTimestamp['last_modified'] = serverTimestamp;
    dataWithTimestamp['created_at'] = serverTimestamp;
    return dataWithTimestamp;
  }

  /// تحديث بيانات مع توقيت الخادم
  static Map<String, dynamic> updateDataWithServerTimestamp(
      Map<String, dynamic> data) {
    final Map<String, dynamic> dataWithTimestamp =
        Map<String, dynamic>.from(data);
    dataWithTimestamp['last_modified'] = serverTimestamp;
    return dataWithTimestamp;
  }

  /// التحقق من صحة التوقيت
  static bool isValidTimestamp(Object? timestamp) {
    if (timestamp == null) return false;
    if (timestamp is Timestamp) return true;
    if (timestamp is String) {
      try {
        DateTime.parse(timestamp);
        return true;
      } on FormatException catch (e) {
        debugPrint('❌ توقيت غير صالح: $timestamp - $e');
        return false;
      }
    }
    return false;
  }

  /// تحويل التوقيت إلى DateTime
  static DateTime? convertToDateTime(Object? timestamp) {
    if (timestamp == null) return null;
    if (timestamp is Timestamp) return timestamp.toDate();
    if (timestamp is String) {
      try {
        return DateTime.parse(timestamp);
      } on FormatException catch (e) {
        debugPrint('❌ خطأ في تحليل التوقيت: $timestamp - $e');
        return null;
      }
    }
    return null;
  }

  /// الحصول على توقيت آمن (الخادم أو المحلي كبديل)
  static Map<String, dynamic> getSafeTimestamp() => <String, dynamic>{
        'last_modified': serverTimestamp,
        'created_at': serverTimestamp,
      };

  /// إنشاء استعلام للمزامنة التفاضلية
  static Query<Map<String, dynamic>> createDeltaQuery(
    CollectionReference<Map<String, dynamic>> collection,
    DateTime? lastSyncTime,
  ) {
    if (lastSyncTime != null) {
      return collection.where(
        'last_modified',
        isGreaterThan: Timestamp.fromDate(lastSyncTime),
      );
    }
    return collection;
  }

  /// التحقق من أن التوقيت صحيح للاستعلام
  static bool isTimestampValidForQuery(Object? timestamp) {
    if (timestamp == null) {
      return false;
    }
    if (timestamp is Timestamp) {
      return true;
    }
    if (timestamp is String) {
      try {
        final DateTime parsed = DateTime.parse(timestamp);
        // التحقق من أن التوقيت ليس في المستقبل
        final DateTime now = DateTime.now();
        final Duration difference = parsed.difference(now);
        return difference.inDays < 365; // لا يزيد عن سنة
      } on FormatException catch (e) {
        debugPrint('❌ خطأ في التحقق من صحة التوقيت: $e');
        return false;
      }
    }
    return false;
  }

  /// إصلاح التوقيتات التالفة
  static Map<String, dynamic> repairTimestamps(Map<String, dynamic> data) {
    final Map<String, dynamic> repairedData = Map<String, dynamic>.from(data);

    // إصلاح last_modified
    if (!isValidTimestamp(repairedData['last_modified'])) {
      repairedData['last_modified'] = serverTimestamp;
    }

    // إصلاح created_at
    if (!isValidTimestamp(repairedData['created_at'])) {
      repairedData['created_at'] = serverTimestamp;
    }

    return repairedData;
  }
}
