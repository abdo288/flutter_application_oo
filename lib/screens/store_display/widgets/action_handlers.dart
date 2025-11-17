import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/inventory_item.dart';
import 'handlers/delete_handler.dart';
import 'handlers/edit_handler.dart';
import 'handlers/print_handler.dart';

/// خدمة معالجة العمليات في تبويب المخزون (مبسطة)
class InventoryDisplayActionHandlers {
  /// عرض نافذة التعديل
  static Future<void> showEditDialog(
    BuildContext context,
    InventoryItem item,
  ) async {
    await EditHandler.showEditDialog(context, item);
  }

  /// تأكيد وحذف العنصر
  static Future<void> confirmAndDeleteItem(
    BuildContext context,
    WidgetRef ref,
    InventoryItem item,
  ) async {
    await DeleteHandler.confirmAndDeleteItem(context, ref, item);
  }

  /// طباعة الباركود
  static Future<void> printBarcode(
    BuildContext context,
    InventoryItem item,
  ) async {
    await PrintHandler.printBarcode(context, item);
  }
}
