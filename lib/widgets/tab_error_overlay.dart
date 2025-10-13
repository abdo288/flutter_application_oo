import 'package:flutter/material.dart';

import '../services/error_handler_service.dart';
import '../utils/constants.dart';

/// غلاف بسيط للتبويبات لالتقاط الأخطاء في البناء/التحديث وعرض رسالة ودية
class TabErrorOverlay extends StatefulWidget {
  const TabErrorOverlay({
    super.key,
    required this.childBuilder,
    this.tabName,
  });

  final Widget Function(BuildContext) childBuilder;
  final String? tabName;

  @override
  State<TabErrorOverlay> createState() => _TabErrorOverlayState();
}

class _TabErrorOverlayState extends State<TabErrorOverlay> {
  Object? _lastError;
  String? _lastStack;

  @override
  Widget build(BuildContext context) {
    try {
      // محاولة بناء التبويب؛ في حال حصول استثناء سنعرض واجهة بديلة
      return widget.childBuilder(context);
    } on Exception catch (e, s) {
      _lastError = e;
      _lastStack = s.toString();
      // تسجيل الخطأ وعرض رسالة للمستخدم
      ErrorHandlerService.handleError(
        e,
        userAction: 'open_tab:${widget.tabName ?? "unknown"}',
        stackTrace: _lastStack,
        showUserMessage: (String message) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          }
        },
      );
      return _buildFallback(context);
    }
  }

  Widget _buildFallback(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(AppConstants.largePadding),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.error_outline,
                  color: AppConstants.errorColor, size: 48),
              const SizedBox(height: 12),
              const Text(
                'حدث خطأ أثناء عرض التبويب',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                _lastError?.toString() ?? 'غير معروف',
                style: const TextStyle(
                    color: AppConstants.lightTextColor, fontSize: 12),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                onPressed: () => setState(() {}),
                icon: const Icon(Icons.refresh),
                label: const Text('إعادة المحاولة'),
              ),
            ],
          ),
        ),
      );
}
