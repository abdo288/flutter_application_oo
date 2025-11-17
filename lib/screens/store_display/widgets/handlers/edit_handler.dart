import 'package:flutter/material.dart';

import '../../../../dialogs/inventory_edit/modern_edit_inventory_dialog_riverpod.dart';
import '../../../../models/inventory_item.dart';
import '../../../../utils/snackbar_utils.dart';

/// معالج عمليات التعديل
class EditHandler {
  /// عرض نافذة التعديل
  static Future<void> showEditDialog(
    BuildContext context,
    InventoryItem item,
  ) async {
    try {
      await showDialog<void>(
        context: context,
        builder: (BuildContext dialogContext) =>
            ModernEditInventoryDialogRiverpod(
          item: item,
          onItemUpdated: () {
            debugPrint('✅ تم تحديث عنصر المخزون بنجاح: ${item.name}');
            // عرض رسالة نجاح
            if (context.mounted) {
              SnackbarUtils.showSuccess(
                context,
                'تم تحديث "${item.name}" بنجاح',
              );
            }
          },
        ),
      );
    } catch (e) {
      debugPrint('❌ خطأ في عرض نافذة التعديل: $e');
      if (context.mounted) {
        SnackbarUtils.showError(context, 'خطأ في فتح نافذة التعديل: $e');
      }
    }
  }
}
