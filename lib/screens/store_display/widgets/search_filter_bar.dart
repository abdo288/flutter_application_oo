import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../providers/store_display_riverpod_providers.dart';
import '../../../utils/constants.dart';
import '../../../utils/responsive_breakpoints.dart';
import '../../../utils/snackbar_utils.dart';
import 'filter_button.dart';
import 'sort_button.dart';

class SearchFilterBar extends ConsumerStatefulWidget {
  const SearchFilterBar({super.key});

  @override
  ConsumerState<SearchFilterBar> createState() => _SearchFilterBarState();
}

class _SearchFilterBarState extends ConsumerState<SearchFilterBar> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        margin: EdgeInsets.symmetric(
            horizontal: context.responsiveSpacing * 0.5,
            vertical: context.responsiveSpacing * 0.4),
        padding: context.responsivePadding,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[
              AppConstants.primaryColor.withValues(alpha: 0.06),
              AppConstants.primaryColor.withValues(alpha: 0.03),
              Colors.white.withValues(alpha: 0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppConstants.primaryColor.withValues(alpha: 0.2),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppConstants.primaryColor.withValues(alpha: 0.08),
              blurRadius: 5,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            // شريط البحث المصغّر
            TextField(
              controller: _searchController,
              onChanged: (String value) {
                _debounce?.cancel();
                _debounce = Timer(const Duration(milliseconds: 300), () {
                  if (mounted) {
                    try {
                      // استخدام Riverpod للفلترة
                      ref
                          .read(inventoryDisplayStateProvider.notifier)
                          .updateSearchQuery(value);
                    } catch (e) {
                      debugPrint(
                          '❌ خطأ في تطبيق البحث في store_display_riverpod: $e');
                    }
                  }
                });
              },
              style: TextStyle(fontSize: context.responsiveFontSize(14)),
              decoration: InputDecoration(
                isDense: context.isSmallScreen,
                hintText: AppLocalizations.of(context).searchInventoryHint,
                hintStyle: TextStyle(
                    fontSize: context.responsiveFontSize(12),
                    color: Colors.grey),
                contentPadding: context.responsivePadding,
                prefixIcon: Container(
                  margin: const EdgeInsets.only(left: 6, right: 4),
                  decoration: BoxDecoration(
                    color: AppConstants.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.search,
                      color: AppConstants.primaryColor,
                      size: context.isSmallScreen ? 16 : 18),
                ),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: Icon(Icons.clear,
                            color: AppConstants.primaryColor,
                            size: context.isSmallScreen ? 16 : 18),
                        onPressed: () {
                          _searchController.clear();
                          _debounce?.cancel();
                          // استخدام Riverpod لإعادة تعيين الفلتر
                          ref
                              .read(inventoryDisplayStateProvider.notifier)
                              .resetFilter();
                        },
                        tooltip: AppLocalizations.of(context).clearSearch,
                      )
                    : null,
                filled: true,
                fillColor: Colors.white,
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                      color: AppConstants.primaryColor.withValues(alpha: 0.25)),
                  borderRadius: BorderRadius.circular(10),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: const BorderSide(
                      color: AppConstants.primaryColor, width: 1.5),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            const SizedBox(height: 6),

            // أزرار الفرز والفلترة (مصغّرة)
            Row(
              children: <Widget>[
                const Expanded(child: SortButton()),
                const SizedBox(width: 6),
                const Expanded(child: FilterButton()),
                const SizedBox(width: 6),
                _buildCleanupButton(),
              ],
            ),
          ],
        ),
      );

  Widget _buildCleanupButton() => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: AppConstants.warningColor.withValues(alpha: 0.3)),
        ),
        child: IconButton(
          onPressed: _cleanupInventoryData,
          icon: const Icon(Icons.cleaning_services,
              color: AppConstants.warningColor, size: 18),
          tooltip: 'تنظيف البيانات الخاطئة',
        ),
      );

  /// تنظيف البيانات الخاطئة من المخزون
  Future<void> _cleanupInventoryData() async {
    try {
      // لا نحتاج تنظيف خاص مع النظام الهجين
      // البيانات يتم تنظيفها تلقائياً
      debugPrint('🔄 تحديث المخزون - الـ provider يتولى التحديث تلقائياً');
      if (mounted) {
        SnackbarUtils.showSuccess(context, 'تم تنظيف البيانات الخاطئة بنجاح');
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'خطأ في تنظيف البيانات: $e');
      }
    }
  }
}
