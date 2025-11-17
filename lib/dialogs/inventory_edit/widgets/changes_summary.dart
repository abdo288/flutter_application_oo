import 'package:flutter/material.dart';

import '../../../utils/constants.dart';
import '../controllers/edit_item_controller.dart';
import 'summary_item.dart';

class ChangesSummary extends StatefulWidget {
  const ChangesSummary({
    super.key,
    required this.editController,
  });

  final EditItemController editController;

  @override
  State<ChangesSummary> createState() => _ChangesSummaryState();
}

class _ChangesSummaryState extends State<ChangesSummary> {
  @override
  void initState() {
    super.initState();
    // لا نحتاج addListener مع StateNotifier
  }

  @override
  void dispose() {
    // لا نحتاج removeListener مع StateNotifier
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(AppConstants.mediumPadding),
        decoration: BoxDecoration(
          color: Colors.purple[50],
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: Colors.purple[200]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.analytics, color: Colors.purple[600]),
                const SizedBox(width: AppConstants.smallPadding),
                Text(
                  'ملخص التغييرات',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.purple[800],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Row(
              children: <Widget>[
                Expanded(
                  child: SummaryItem(
                    label: 'القيمة الإجمالية',
                    value: '${widget.editController.calculateTotalValue()} DZ',
                    color: Colors.purple[600]!,
                  ),
                ),
                Expanded(
                  child: SummaryItem(
                    label: 'الكمية الحالية',
                    value: widget.editController.quantityController.text.isEmpty
                        ? '0'
                        : widget.editController.quantityController.text,
                    color: Colors.orange[600]!,
                  ),
                ),
              ],
            ),
          ],
        ),
      );
}
