import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

import '../l10n/app_localizations.dart';
import '../utils/constants.dart';

/// عنصر تحميل مخصص
class LoadingWidget extends StatelessWidget {
  const LoadingWidget({
    super.key,
    this.message,
    this.size = 50.0,
    this.color,
  });
  final String? message;
  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: _buildSkeletonCard(),
            ),
            const SizedBox(height: 12),
            Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: _buildSkeletonCard(width: 220, height: 14, radius: 6),
            ),
            if (message != null) ...<Widget>[
              const SizedBox(height: 8),
              Text(
                message!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppConstants.lightTextColor,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      );

  Widget _buildSkeletonCard(
          {double? width, double? height, double radius = 12}) =>
      Container(
        width: width ?? size * 2.4,
        height: height ?? size * 1.4,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(radius),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      );
}

/// عنصر تحميل بسيط
class SimpleLoadingWidget extends StatelessWidget {
  const SimpleLoadingWidget({
    super.key,
    this.message,
  });
  final String? message;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const CircularProgressIndicator(),
            if (message != null) ...<Widget>[
              const SizedBox(height: AppConstants.defaultPadding),
              Text(message!),
            ],
          ],
        ),
      );
}

/// عنصر تحميل مع رسالة خطأ
class ErrorWidget extends StatelessWidget {
  const ErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
  });
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppConstants.errorColor,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: AppConstants.textColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: AppConstants.defaultPadding),
              ElevatedButton(
                onPressed: onRetry,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: Text(AppLocalizations.of(context).retry),
              ),
            ],
          ],
        ),
      );
}

/// عنصر فارغ
class EmptyWidget extends StatelessWidget {
  const EmptyWidget({
    super.key,
    required this.message,
    this.icon,
  });
  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(
              icon ?? Icons.inbox_outlined,
              size: 64,
              color: AppConstants.lightTextColor,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: AppConstants.lightTextColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
}
