import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/add_product_riverpod_providers.dart';
import '../../../utils/constants.dart';

class HeaderSection extends ConsumerWidget {
  const HeaderSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final String? errorMessage = ref.watch(addProductErrorProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: AppConstants.defaultPadding),

        // رسالة توضيحية
        Container(
          padding: const EdgeInsets.all(AppConstants.defaultPadding),
          margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
          decoration: BoxDecoration(
            color: AppConstants.primaryColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppConstants.borderRadius),
            border:
                Border.all(color: AppConstants.primaryColor.withOpacity(0.3)),
          ),
          child: const Row(
            children: <Widget>[
              Icon(Icons.info_outline, color: AppConstants.primaryColor),
              SizedBox(width: AppConstants.smallPadding),
              Expanded(
                child: Text(
                  'هذا التبويب للبيع السريع لمنتجات موجودة في المخزون.\nلإضافة منتج جديد للمخزون، استخدم تبويب "نموذج المنتج".',
                  style: TextStyle(
                    color: AppConstants.primaryColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),

        // عرض رسالة الخطأ إذا وجدت
        if (errorMessage != null) ...<Widget>[
          Container(
            padding: const EdgeInsets.all(AppConstants.defaultPadding),
            margin: const EdgeInsets.only(bottom: AppConstants.defaultPadding),
            decoration: BoxDecoration(
              color: AppConstants.errorColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              border:
                  Border.all(color: AppConstants.errorColor.withOpacity(0.3)),
            ),
            child: Row(
              children: <Widget>[
                const Icon(Icons.error_outline, color: AppConstants.errorColor),
                const SizedBox(width: AppConstants.smallPadding),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: const TextStyle(color: AppConstants.errorColor),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    ref.read(addProductStateProvider.notifier).clearError();
                  },
                  icon: const Icon(Icons.close),
                  color: AppConstants.errorColor,
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
