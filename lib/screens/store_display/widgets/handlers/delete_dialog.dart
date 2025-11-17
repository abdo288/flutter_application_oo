import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../models/inventory_item.dart';
import '../../../../utils/constants.dart';
import '../../../../utils/currency_formatter.dart';

/// نافذة تأكيد الحذف المحسّنة مع عرض تفاصيل العنصر
class DeleteConfirmationDialog extends StatelessWidget {
  const DeleteConfirmationDialog({
    super.key,
    required this.item,
    required this.onConfirm,
    required this.onCancel,
  });

  final InventoryItem item;
  final VoidCallback onConfirm;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
        ),
        title: Row(
          children: <Widget>[
            Icon(
              Icons.warning_amber_rounded,
              color: Colors.red[600],
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                AppLocalizations.of(context).confirmDelete,
                style: TextStyle(
                  color: Colors.red[700],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // رسالة التأكيد
              Text(
                AppLocalizations.of(context).confirmDeleteMessage(item.name),
                style: const TextStyle(fontSize: 16),
              ),

              const SizedBox(height: 20),

              // تفاصيل العنصر
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'تفاصيل العنصر المراد حذفه:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey[700],
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildDetailRow('الاسم:', item.name),
                    _buildDetailRow('الكمية:',
                        '${item.quantity} ${AppLocalizations.of(context).quantityUnit}'),
                    _buildDetailRow(
                        'سعر الجملة:',
                        CurrencyFormatter.formatCurrency(
                            item.wholesalePrice.toDouble(), context)),
                    if (item.barcode?.isNotEmpty == true)
                      _buildDetailRow('الباركود:', item.barcode ?? ''),
                    _buildDetailRow(
                        'تاريخ الإضافة:',
                        DateFormat(AppConstants.dateFormat)
                            .format(item.addedDate)),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // تحذير
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: <Widget>[
                    Icon(Icons.info_outline, color: Colors.red[600], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'هذا الإجراء لا يمكن التراجع عنه',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        actions: <Widget>[
          // زر الإلغاء
          TextButton(
            onPressed: onCancel,
            style: TextButton.styleFrom(
              foregroundColor: Colors.grey[600],
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('إلغاء'),
          ),

          // زر الحذف
          ElevatedButton(
            onPressed: onConfirm,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red[600],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
            ),
            child: const Text('حذف'),
          ),
        ],
      );

  Widget _buildDetailRow(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              width: 80,
              child: Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w500,
                  color: Colors.grey[600],
                ),
              ),
            ),
            Expanded(
              child: Text(
                value,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
      );
}
