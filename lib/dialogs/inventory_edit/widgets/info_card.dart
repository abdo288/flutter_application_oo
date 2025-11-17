import 'package:flutter/material.dart';

import '../../../utils/constants.dart';
import '../../../utils/responsive_breakpoints.dart';
import '../controllers/edit_item_controller.dart';
import 'info_item.dart';

class InfoCard extends StatelessWidget {
  const InfoCard({
    super.key,
    required this.editController,
  });

  final EditItemController editController;

  @override
  Widget build(BuildContext context) => Container(
        padding: context.responsivePadding,
        decoration: BoxDecoration(
          color: Colors.green[50],
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(color: Colors.green[200]!),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.info_outline,
                    color: Colors.green[600],
                    size: context.isSmallScreen ? 18 : 22),
                SizedBox(width: context.responsiveSpacing * 0.5),
                Text(
                  'معلومات العنصر',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                    fontSize: context.responsiveFontSize(14),
                  ),
                ),
              ],
            ),
            SizedBox(height: context.responsiveSpacing * 0.5),
            if (context.shouldUseVerticalLayout)
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  InfoItem(
                    label: 'الباركود',
                    value: editController.barcode ?? 'غير محدد',
                    icon: Icons.qr_code,
                  ),
                  SizedBox(height: context.responsiveSpacing * 0.5),
                  InfoItem(
                    label: 'تاريخ الإضافة',
                    value:
                        editController.item.addedDate.toString().split(' ')[0],
                    icon: Icons.calendar_today,
                  ),
                ],
              )
            else
              Row(
                children: <Widget>[
                  Expanded(
                    child: InfoItem(
                      label: 'الباركود',
                      value: editController.barcode ?? 'غير محدد',
                      icon: Icons.qr_code,
                    ),
                  ),
                  SizedBox(width: context.responsiveSpacing * 0.5),
                  Expanded(
                    child: InfoItem(
                      label: 'تاريخ الإضافة',
                      value: editController.item.addedDate
                          .toString()
                          .split(' ')[0],
                      icon: Icons.calendar_today,
                    ),
                  ),
                ],
              ),
            if (editController.item.expiryDate != null) ...<Widget>[
              SizedBox(height: context.responsiveSpacing * 0.5),
              InfoItem(
                label: 'تاريخ الانتهاء',
                value: editController.item.expiryDate!.toString().split(' ')[0],
                icon: Icons.event,
              ),
            ],
          ],
        ),
      );
}
