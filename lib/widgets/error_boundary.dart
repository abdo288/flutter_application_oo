import 'package:flutter/material.dart';
import '../utils/constants.dart';

/// مكون معالجة الأخطاء المحسن
class ErrorBoundary extends StatefulWidget {
  const ErrorBoundary({
    super.key,
    required this.child,
    this.onError,
    this.fallback,
  });

  final Widget child;
  final void Function(Object error, StackTrace stackTrace)? onError;
  final Widget Function(Object error)? fallback;

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.fallback?.call(_error!) ?? _buildDefaultErrorWidget();
    }

    return widget.child;
  }

  Widget _buildDefaultErrorWidget() => Center(
      child: Padding(
        padding: const EdgeInsets.all(AppConstants.largePadding),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.error_outline,
              size: 64,
              color: AppConstants.errorColor,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            const Text(
              'حدث خطأ غير متوقع',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppConstants.errorColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.smallPadding),
            Text(
              'تفاصيل الخطأ: ${_error.toString()}',
              style: const TextStyle(
                fontSize: 14,
                color: AppConstants.lightTextColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppConstants.defaultPadding),
            ElevatedButton.icon(
              onPressed: _resetError,
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppConstants.primaryColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );

  void _resetError() {
    if (mounted) {
      setState(() {
        _error = null;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    // تسجيل معالج الأخطاء
    FlutterError.onError = (FlutterErrorDetails details) {
      if (mounted) {
        setState(() {
          _error = details.exception;
        });
      }
      widget.onError
          ?.call(details.exception, details.stack ?? StackTrace.empty);
    };
  }
}

/// مكون معالجة الأخطاء المبسط
class SimpleErrorBoundary extends StatelessWidget {
  const SimpleErrorBoundary({
    super.key,
    required this.child,
    this.errorMessage = 'حدث خطأ في التحميل',
    this.onRetry,
  });

  final Widget child;
  final String errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Builder(
      builder: (BuildContext context) {
        try {
          return child;
        } catch (error) {
          return _buildErrorWidget(error);
        }
      },
    );

  Widget _buildErrorWidget(Object error) => Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppConstants.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppConstants.errorColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
}

/// مكون معالجة حالات التحميل والأخطاء
class LoadingErrorHandler extends StatelessWidget {
  const LoadingErrorHandler({
    super.key,
    required this.isLoading,
    required this.hasError,
    required this.child,
    this.loadingMessage = 'جاري التحميل...',
    this.errorMessage = 'حدث خطأ في التحميل',
    this.onRetry,
  });

  final bool isLoading;
  final bool hasError;
  final Widget child;
  final String loadingMessage;
  final String errorMessage;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingWidget();
    }

    if (hasError) {
      return _buildErrorWidget();
    }

    return child;
  }

  Widget _buildLoadingWidget() => Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          const CircularProgressIndicator(
            valueColor:
                AlwaysStoppedAnimation<Color>(AppConstants.primaryColor),
          ),
          const SizedBox(height: 16),
          Text(
            loadingMessage,
            style: const TextStyle(
              fontSize: 16,
              color: AppConstants.primaryColor,
            ),
          ),
        ],
      ),
    );

  Widget _buildErrorWidget() => Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppConstants.errorColor,
            ),
            const SizedBox(height: 16),
            Text(
              errorMessage,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppConstants.errorColor,
              ),
              textAlign: TextAlign.center,
            ),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.primaryColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ],
        ),
      ),
    );
}
