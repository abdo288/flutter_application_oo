import 'package:flutter/material.dart';

import '../../../utils/constants.dart';
import '../../../utils/responsive_breakpoints.dart';

class EmptyState extends StatelessWidget {
  const EmptyState({super.key, this.onRefresh});

  final VoidCallback? onRefresh;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppConstants.primaryColor.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.inventory_2_outlined,
                  size: 64,
                  color: AppConstants.primaryColor.withValues(alpha: 0.6),
                ),
              ),
              SizedBox(height: context.responsiveSpacing),
              Text(
                'No products available in inventory',
                style: TextStyle(
                  fontSize: context.responsiveFontSize(24),
                  fontWeight: FontWeight.bold,
                  color: AppConstants.primaryColor,
                ),
              ),
              SizedBox(height: context.responsiveSpacing * 0.5),
              Text(
                'Please add products to inventory first',
                style: TextStyle(
                  fontSize: context.responsiveFontSize(16),
                  color: Colors.grey[600],
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: context.responsiveSpacing),
              ElevatedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة تحميل'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
}
