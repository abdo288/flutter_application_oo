import 'package:flutter/material.dart';

import '../services/error_handler_service.dart';
import '../utils/constants.dart';

/// شريط تنقل سفلي آمن مع اكتشاف الأخطاء وحمايتها من التعطل
class SafeBottomNavigationBar extends StatefulWidget {
  const SafeBottomNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items,
    this.type = BottomNavigationBarType.fixed,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.selectedIconTheme,
    this.unselectedIconTheme,
    this.selectedLabelStyle,
    this.unselectedLabelStyle,
    this.backgroundColor,
    this.elevation,
    this.showSelectedLabels = true,
    this.showUnselectedLabels = true,
    this.enableFeedback = true,
    this.onTapErrorHandler,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<BottomNavigationBarItem>? items;
  final BottomNavigationBarType type;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final IconThemeData? selectedIconTheme;
  final IconThemeData? unselectedIconTheme;
  final TextStyle? selectedLabelStyle;
  final TextStyle? unselectedLabelStyle;
  final Color? backgroundColor;
  final double? elevation;
  final bool showSelectedLabels;
  final bool showUnselectedLabels;
  final bool enableFeedback;
  final void Function(Object error, StackTrace stackTrace)? onTapErrorHandler;

  @override
  State<SafeBottomNavigationBar> createState() =>
      _SafeBottomNavigationBarState();
}

class _SafeBottomNavigationBarState extends State<SafeBottomNavigationBar> {
  String? _lastStack;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void didUpdateWidget(SafeBottomNavigationBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // إعادة تعيين حالة الخطأ عند تحديث الـ widget
    if (oldWidget.currentIndex != widget.currentIndex) {
      _hasError = false;
    }
  }

  /// معالج آمن للنقر على التبويبات
  void _safeOnTap(int index) {
    try {
      // التحقق من صحة الفهرس
      if (index < 0 ||
          (widget.items != null && index >= widget.items!.length)) {
        throw RangeError('Invalid navigation index: $index');
      }

      // استدعاء المعالج الأصلي
      widget.onTap(index);

      // إعادة تعيين حالة الخطأ عند النجاح
      if (_hasError) {
        setState(() {
          _hasError = false;
          _lastStack = null;
        });
      }
    } catch (e, stackTrace) {
      _handleNavigationError(e, stackTrace, index);
    }
  }

  /// معالجة أخطاء التنقل
  void _handleNavigationError(
      Object error, StackTrace stackTrace, int attemptedIndex) {
    debugPrint('❌ خطأ في التنقل إلى التبويب $attemptedIndex: $error');

    _lastStack = stackTrace.toString();

    // تسجيل الخطأ في خدمة معالجة الأخطاء
    ErrorHandlerService.handleError(
      error,
      userAction: 'navigation_tap:$attemptedIndex',
      stackTrace: _lastStack,
      showUserMessage: (String message) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      },
    );

    // استدعاء معالج الخطأ المخصص إن وجد
    widget.onTapErrorHandler?.call(error, stackTrace);

    // تحديث حالة الخطأ
    if (mounted) {
      setState(() {
        _hasError = true;
      });
    }

    // إظهار رسالة خطأ للمستخدم
    _showErrorSnackBar(error, attemptedIndex);
  }

  /// إظهار رسالة خطأ للمستخدم
  void _showErrorSnackBar(Object error, int attemptedIndex) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: <Widget>[
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'خطأ في التنقل إلى التبويب ${attemptedIndex + 1}',
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: AppConstants.errorColor,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'إعادة المحاولة',
          textColor: Colors.white,
          onPressed: () => _safeOnTap(attemptedIndex),
        ),
      ),
    );
  }

  /// بناء واجهة الخطأ
  Widget _buildErrorFallback() => Container(
        height: 60,
        decoration: BoxDecoration(
          color: AppConstants.errorColor.withValues(alpha: 0.1),
          border: Border(
            top: BorderSide(
              color: AppConstants.errorColor.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.error_outline,
              color: AppConstants.errorColor,
              size: 20,
            ),
            const SizedBox(width: 8),
            const Text(
              'خطأ في التنقل',
              style: TextStyle(
                color: AppConstants.errorColor,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(width: 16),
            TextButton(
              onPressed: () {
                setState(() {
                  _hasError = false;
                  _lastStack = null;
                });
              },
              child: const Text(
                'إعادة المحاولة',
                style: TextStyle(
                  color: AppConstants.errorColor,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    try {
      // إذا كان هناك خطأ، اعرض واجهة الخطأ
      if (_hasError) {
        return _buildErrorFallback();
      }

      // بناء شريط التنقل العادي مع حماية من الأخطاء
      return BottomNavigationBar(
        type: widget.type,
        currentIndex:
            widget.currentIndex.clamp(0, (widget.items?.length ?? 1) - 1),
        onTap: _safeOnTap,
        items: widget.items ?? _getDefaultItems(),
        selectedItemColor:
            widget.selectedItemColor ?? AppConstants.primaryColor,
        unselectedItemColor:
            widget.unselectedItemColor ?? AppConstants.lightTextColor,
        selectedIconTheme: widget.selectedIconTheme ??
            const IconThemeData(
              color: AppConstants.primaryColor,
              size: 20,
            ),
        unselectedIconTheme: widget.unselectedIconTheme ??
            const IconThemeData(
              color: AppConstants.lightTextColor,
              size: 18,
            ),
        selectedLabelStyle: widget.selectedLabelStyle ??
            const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
        unselectedLabelStyle: widget.unselectedLabelStyle ??
            const TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 9,
            ),
        backgroundColor: widget.backgroundColor,
        elevation: widget.elevation,
        showSelectedLabels: widget.showSelectedLabels,
        showUnselectedLabels: widget.showUnselectedLabels,
        enableFeedback: widget.enableFeedback,
      );
    } catch (e, stackTrace) {
      // في حالة حدوث خطأ في البناء نفسه
      debugPrint('❌ خطأ في بناء SafeBottomNavigationBar: $e');
      ErrorHandlerService.handleError(
        e,
        userAction: 'build_bottom_navigation',
        stackTrace: stackTrace.toString(),
        showUserMessage: (String message) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          }
        },
      );

      return _buildErrorFallback();
    }
  }

  /// الحصول على عناصر التنقل الافتراضية
  List<BottomNavigationBarItem> _getDefaultItems() =>
      const <BottomNavigationBarItem>[
        BottomNavigationBarItem(
          icon: Icon(Icons.dashboard),
          label: 'لوحة التحكم',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.point_of_sale),
          label: 'نقطة البيع',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.inventory_2),
          label: 'نموذج المنتج',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.list),
          label: 'سجل المبيعات',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.analytics),
          label: 'التقارير',
        ),
      ];
}

/// شريط تنقل جانبي آمن للشاشات الكبيرة
class SafeSideNavigationBar extends StatefulWidget {
  const SafeSideNavigationBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    this.items,
    this.width = 200,
    this.backgroundColor,
    this.selectedItemColor,
    this.unselectedItemColor,
    this.onTapErrorHandler,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<SafeNavigationItem>? items;
  final double width;
  final Color? backgroundColor;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;
  final void Function(Object error, StackTrace stackTrace)? onTapErrorHandler;

  @override
  State<SafeSideNavigationBar> createState() => _SafeSideNavigationBarState();
}

class _SafeSideNavigationBarState extends State<SafeSideNavigationBar> {
  bool _hasError = false;

  /// معالج آمن للنقر على التبويبات الجانبية
  void _safeOnTap(int index) {
    try {
      if (index < 0 ||
          (widget.items != null && index >= widget.items!.length)) {
        throw RangeError('Invalid side navigation index: $index');
      }

      widget.onTap(index);

      if (_hasError) {
        setState(() {
          _hasError = false;
        });
      }
    } catch (e, stackTrace) {
      _handleSideNavigationError(e, stackTrace, index);
    }
  }

  /// معالجة أخطاء التنقل الجانبي
  void _handleSideNavigationError(
      Object error, StackTrace stackTrace, int attemptedIndex) {
    debugPrint('❌ خطأ في التنقل الجانبي إلى التبويب $attemptedIndex: $error');

    ErrorHandlerService.handleError(
      error,
      userAction: 'side_navigation_tap:$attemptedIndex',
      stackTrace: stackTrace.toString(),
      showUserMessage: (String message) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(message)),
          );
        }
      },
    );

    widget.onTapErrorHandler?.call(error, stackTrace);

    if (mounted) {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      if (_hasError) {
        return _buildSideErrorFallback();
      }

      return Container(
        width: widget.width,
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? Colors.white,
          border: Border(
            right: BorderSide(
              color: Colors.grey.withValues(alpha: 0.2),
            ),
          ),
        ),
        child: Column(
          children: <Widget>[
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              child: const Text(
                'التنقل',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // Navigation Items
            Expanded(
              child: ListView.builder(
                itemCount:
                    widget.items?.length ?? _getDefaultSideItems().length,
                itemBuilder: (BuildContext context, int index) {
                  final List<SafeNavigationItem> items =
                      widget.items ?? _getDefaultSideItems();
                  final SafeNavigationItem item = items[index];
                  final bool isSelected = widget.currentIndex == index;

                  return Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (widget.selectedItemColor ??
                                  AppConstants.primaryColor)
                              .withValues(alpha: 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: ListTile(
                      leading: Icon(
                        item.icon,
                        color: isSelected
                            ? widget.selectedItemColor ??
                                AppConstants.primaryColor
                            : widget.unselectedItemColor ??
                                AppConstants.lightTextColor,
                      ),
                      title: Text(
                        item.label,
                        style: TextStyle(
                          color: isSelected
                              ? widget.selectedItemColor ??
                                  AppConstants.primaryColor
                              : widget.unselectedItemColor ??
                                  AppConstants.textColor,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                      ),
                      onTap: () => _safeOnTap(index),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      );
    } catch (e, stackTrace) {
      debugPrint('❌ خطأ في بناء SafeSideNavigationBar: $e');
      ErrorHandlerService.handleError(
        e,
        userAction: 'build_side_navigation',
        stackTrace: stackTrace.toString(),
        showUserMessage: (String message) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(message)),
            );
          }
        },
      );

      return _buildSideErrorFallback();
    }
  }

  /// بناء واجهة خطأ التنقل الجانبي
  Widget _buildSideErrorFallback() => Container(
        width: widget.width,
        decoration: BoxDecoration(
          color: AppConstants.errorColor.withValues(alpha: 0.1),
          border: Border(
            right: BorderSide(
              color: AppConstants.errorColor.withValues(alpha: 0.3),
            ),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Icon(
              Icons.error_outline,
              color: AppConstants.errorColor,
              size: 48,
            ),
            const SizedBox(height: 16),
            const Text(
              'خطأ في التنقل',
              style: TextStyle(
                color: AppConstants.errorColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _hasError = false;
                });
              },
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );

  /// الحصول على عناصر التنقل الجانبي الافتراضية
  List<SafeNavigationItem> _getDefaultSideItems() => const <SafeNavigationItem>[
        SafeNavigationItem(
          icon: Icons.dashboard,
          label: 'لوحة التحكم',
        ),
        SafeNavigationItem(
          icon: Icons.point_of_sale,
          label: 'نقطة البيع',
        ),
        SafeNavigationItem(
          icon: Icons.inventory_2,
          label: 'نموذج المنتج',
        ),
        SafeNavigationItem(
          icon: Icons.list,
          label: 'سجل المبيعات',
        ),
        SafeNavigationItem(
          icon: Icons.analytics,
          label: 'التقارير',
        ),
      ];
}

/// عنصر تنقل آمن
class SafeNavigationItem {
  const SafeNavigationItem({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;
}
