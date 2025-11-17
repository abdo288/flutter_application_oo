import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

import '../../error_handler_service.dart';
import '../../error_handler_service.dart' as error_handler;
import '../models/cleanup_result.dart';
import '../models/cleanup_stats.dart';

/// خدمة تنظيف البيانات السحابية (Firebase Firestore)
class FirestoreCleanupService {
  factory FirestoreCleanupService() => _instance;
  FirestoreCleanupService._internal();
  static final FirestoreCleanupService _instance =
      FirestoreCleanupService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// تنظيف شامل للبيانات السحابية فقط
  Future<CleanupResult> performFirestoreCleanup() async {
    try {
      debugPrint('🔥 بدء التنظيف الشامل للبيانات السحابية...');

      // حذف جميع المنتجات من Firestore
      final int productsDeleted = await deleteAllProductsFromFirestore();

      // حذف جميع عناصر المخزون من Firestore
      final int inventoryDeleted = await deleteAllInventoryFromFirestore();

      debugPrint('✅ تم التنظيف الشامل للبيانات السحابية بنجاح');
      return CleanupResult(
        success: true,
        message: 'تم التنظيف الشامل للبيانات السحابية بنجاح',
        stats: CleanupStats(
          productsDeleted: productsDeleted,
          inventoryItemsDeleted: inventoryDeleted,
          additionalInfo: 'تم حذف البيانات من Firebase Firestore فقط',
        ),
      );
    } catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: error_handler.ErrorType.unknown,
        severity: error_handler.ErrorSeverity.high,
        userAction: 'تنظيف البيانات السحابية',
        context: <String, dynamic>{
          'operation': 'performFirestoreCleanup',
        },
      );
      return CleanupResult(
        success: false,
        message: 'فشل في التنظيف الشامل للبيانات السحابية: $e',
      );
    }
  }

  /// حذف جميع المنتجات من Firebase Firestore
  Future<int> deleteAllProductsFromFirestore() async {
    try {
      debugPrint('🔥 حذف جميع المنتجات من Firebase Firestore...');

      final QuerySnapshot productsSnapshot =
          await _firestore.collection('products').get();

      int deletedCount = 0;
      for (final QueryDocumentSnapshot doc in productsSnapshot.docs) {
        await doc.reference.delete();
        deletedCount++;
      }

      debugPrint('🔥 تم حذف $deletedCount منتج من Firestore');
      return deletedCount;
    } catch (e) {
      debugPrint('❌ خطأ في حذف المنتجات من Firestore: $e');
      return 0;
    }
  }

  /// حذف جميع عناصر المخزون من Firebase Firestore
  Future<int> deleteAllInventoryFromFirestore() async {
    try {
      debugPrint('🔥 حذف جميع عناصر المخزون من Firebase Firestore...');

      final QuerySnapshot inventorySnapshot =
          await _firestore.collection('quantities').get();

      int deletedCount = 0;
      for (final QueryDocumentSnapshot doc in inventorySnapshot.docs) {
        await doc.reference.delete();
        deletedCount++;
      }

      debugPrint('🔥 تم حذف $deletedCount عنصر مخزون من Firestore');
      return deletedCount;
    } catch (e) {
      debugPrint('❌ خطأ في حذف عناصر المخزون من Firestore: $e');
      return 0;
    }
  }
}
