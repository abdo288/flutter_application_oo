import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:profit_calculator/models/cart_item.dart';
import '../../../../models/inventory_item.dart';
import '../../../../providers/pos_riverpod_providers.dart';
import '../../../../providers/riverpod/stream_inventory_riverpod_provider.dart'
    as stream;
import '../../../../utils/constants.dart';
import '../../../../utils/snackbar_utils.dart';
import 'delete_dialog.dart';

/// معالج عمليات الحذف
class DeleteHandler {
  /// تأكيد وحذف العنصر
  static Future<void> confirmAndDeleteItem(
    BuildContext context,
    WidgetRef ref,
    InventoryItem item,
  ) async {
    try {
      // التحقق من صحة البيانات
      if (item.id == null || item.id!.isEmpty) {
        _showDeleteResult(context, false, item.name, 'معرف العنصر غير صالح');
        return;
      }

      // التحقق من وجود المنتج في السلة قبل الحذف
      final bool isInCart = await _checkIfItemInCart(ref, item);
      if (isInCart) {
        _showDeleteResult(context, false, item.name,
            'لا يمكن حذف المنتج لأنه موجود في السلة. يرجى إزالة المنتج من السلة أولاً.');
        return;
      }

      // عرض dialog التأكيد المحسّن
      final bool? confirmed = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) => DeleteConfirmationDialog(
          item: item,
          onConfirm: () => Navigator.of(context).pop(true),
          onCancel: () => Navigator.of(context).pop(false),
        ),
      );

      if (confirmed == true && context.mounted) {
        await _executeDelete(context, ref, item);
      }
    } catch (e) {
      debugPrint('❌ خطأ في تأكيد الحذف: $e');
      if (context.mounted) {
        SnackbarUtils.showError(context, 'خطأ في تأكيد الحذف: $e');
      }
    }
  }

  /// التحقق من وجود المنتج في السلة
  static Future<bool> _checkIfItemInCart(
      WidgetRef ref, InventoryItem item) async {
    try {
      // البحث عن المنتج بالاسم في السلة
      final CartState cartState = ref.read(cartStateProvider);
      final bool isInCart = cartState.cart.any(
          (CartItem cartItem) => cartItem.name.toLowerCase() == item.name.toLowerCase());

      debugPrint('🛒 التحقق من وجود المنتج في السلة: ${item.name} - $isInCart');
      return isInCart;
    } catch (e) {
      debugPrint('❌ خطأ في التحقق من السلة: $e');
      return false; // في حالة الخطأ، نسمح بالحذف
    }
  }

  /// تنفيذ الحذف المحسّن مع Optimistic UI
  static Future<bool> _executeDelete(
    BuildContext context,
    WidgetRef ref,
    InventoryItem item,
  ) async {
    try {
      debugPrint('🗑️ بدء حذف العنصر: ${item.name} (${item.id})');

      // التحقق من وجود المعرف
      if (item.id == null || item.id!.isEmpty) {
        _showDeleteResult(context, false, item.name, 'معرف العنصر غير صالح');
        return false;
      }

      // تنفيذ الحذف باستخدام inventory controller مباشرة
      try {
        final bool success = await ref
            .read(stream.inventoryControllerProvider.notifier)
            .deleteInventoryItem(item.id!);

        if (success) {
          _showDeleteResult(context, true, item.name);
          debugPrint('✅ تم حذف العنصر بنجاح: ${item.name}');
          return true;
        } else {
          _showDeleteResult(
              context, false, item.name, 'فشل في حذف العنصر من قاعدة البيانات');
          return false;
        }
      } catch (e) {
        debugPrint('❌ خطأ في حذف العنصر: $e');
        _showDeleteResult(context, false, item.name, 'خطأ في الحذف: $e');
        return false;
      }
    } catch (e) {
      debugPrint('❌ خطأ في حذف العنصر: $e');
      _showDeleteResult(
          context, false, item.name, 'خطأ في الحذف: ${e.toString()}');
      return false;
    }
  }

  /// دالة عرض نتائج الحذف المحسّنة
  static void _showDeleteResult(
    BuildContext context,
    bool success,
    String itemName, [
    String? errorMessage,
  ]) {
    if (!context.mounted) return;

    final String message = success
        ? 'تم حذف "$itemName" بنجاح'
        : 'فشل في حذف "$itemName"${errorMessage != null ? ': $errorMessage' : ''}';

    final Color backgroundColor = success ? Colors.green : Colors.red;
    final IconData icon = success ? Icons.check_circle : Icons.error;

    final SnackBar snackBar = SnackBar(
      content: Row(
        children: <Widget>[
          Icon(icon, color: Colors.white),
          const SizedBox(width: 8),
          Expanded(child: Text(message)),
        ],
      ),
      backgroundColor: backgroundColor,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppConstants.borderRadius),
      ),
      duration: Duration(seconds: success ? 3 : 5),
      action: success
          ? SnackBarAction(
              label: 'تراجع',
              textColor: Colors.white,
              onPressed: () {
                // TODO: تنفيذ التراجع إذا لزم الأمر
                debugPrint('تراجع عن حذف: $itemName');
              },
            )
          : null,
    );

    ScaffoldMessenger.of(context).showSnackBar(snackBar);
  }
}
