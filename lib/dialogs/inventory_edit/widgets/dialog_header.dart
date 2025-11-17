import 'package:flutter/material.dart';

import '../../../models/inventory_item.dart';
import '../../../utils/constants.dart';
import '../../../utils/responsive_breakpoints.dart';

class DialogHeader extends StatelessWidget {
  const DialogHeader({
    super.key,
    required this.item,
    required this.onClose,
  });

  final InventoryItem item;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) => Container(
        padding: context.responsivePadding,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              Colors.blue[600]!,
              Colors.blue[400]!,
            ],
          ),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(AppConstants.borderRadius * 2),
            topRight: Radius.circular(AppConstants.borderRadius * 2),
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              padding: EdgeInsets.all(context.responsiveSpacing * 0.5),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              ),
              child: Icon(
                Icons.inventory,
                color: Colors.white,
                size: context.isSmallScreen ? 20 : 24,
              ),
            ),
            SizedBox(width: context.responsiveSpacing),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    'تعديل عنصر المخزون',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: context.responsiveFontSize(18),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    item.name,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: context.responsiveFontSize(12),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            IconButton(
              onPressed: onClose,
              icon: const Icon(Icons.close, color: Colors.white),
              padding: EdgeInsets.all(context.responsiveSpacing * 0.5),
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
}
