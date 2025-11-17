import 'package:flutter/material.dart';

import '../../../utils/constants.dart';
import '../../../utils/responsive_breakpoints.dart';
import '../../../widgets/shimmer_loading.dart';

class LoadingStates {
  static Widget buildShimmerLoading() => ListView.builder(
        itemCount: 5,
        padding: const EdgeInsets.all(AppConstants.spacing16),
        itemBuilder: (BuildContext context, int index) => const Padding(
            padding: EdgeInsets.only(bottom: AppConstants.spacing12),
            child: ShimmerCard(),
          ),
      );

  static Widget buildErrorState(
          BuildContext context, String errorMessage, VoidCallback onRetry) =>
      Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              'خطأ في تحميل بيانات المخزون',
              style: TextStyle(
                fontSize: context.responsiveFontSize(18),
                fontWeight: FontWeight.bold,
                color: Colors.red[800],
              ),
            ),
            SizedBox(height: context.responsiveSpacing * 0.5),
            Text(
              errorMessage,
              style: TextStyle(
                fontSize: context.responsiveFontSize(14),
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: onRetry,
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
}
