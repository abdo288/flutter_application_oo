import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../screens/alerts_tab_riverpod.dart';
import '../../../screens/settings_tab_riverpod.dart';
import '../../../utils/constants.dart';
import '../../../utils/responsive_breakpoints.dart';
import '../../../widgets/alert_badge.dart';
import '../../../widgets/responsive_widgets.dart';
import '../../../widgets/sync_status_indicator.dart';
import 'action_button_widget.dart';
import 'quick_stats_widget.dart';

class DesktopAppBar extends ConsumerWidget {
  const DesktopAppBar({
    super.key,
    required this.currentIndex,
    required this.onTabTapped,
  });

  final int currentIndex;
  final void Function(int) onTabTapped;

  @override
  Widget build(BuildContext context, WidgetRef ref) => Container(
        height: 70,
        padding: EdgeInsets.symmetric(horizontal: context.responsiveSpacing),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              AppConstants.primaryColor,
              AppConstants.primaryColor.withValues(alpha: 0.9),
            ],
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppConstants.primaryColor.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
          borderRadius: const BorderRadius.vertical(
            bottom: Radius.circular(20),
          ),
        ),
        child: Row(
          children: <Widget>[
            // شعار التطبيق
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.calculate,
                color: Colors.white,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            // عنوان التطبيق مع تأثير
            ShaderMask(
              shaderCallback: (Rect bounds) => const LinearGradient(
                colors: <Color>[Colors.white, Colors.white70],
              ).createShader(bounds),
              child: ResponsiveText(
                AppLocalizations.of(context).appTitle,
                fontSize: AppConstants.titleFontSize + 2,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const Spacer(),
            // إحصائيات سريعة
            const QuickStatsWidget(),
            const SizedBox(width: 20),
            ..._buildAppBarActions(context, ref),
          ],
        ),
      );

  /// بناء أزرار شريط التطبيق
  List<Widget> _buildAppBarActions(BuildContext context, WidgetRef ref) => <Widget>[
      // ✅ مؤشر المزامنة
      const InteractiveSyncIndicator(),
      const SizedBox(width: 6),
      // زر الإعدادات (متاح لجميع المستخدمين)
      ActionButtonWidget(
        context: context,
        icon: Icons.settings,
        tooltip: AppLocalizations.of(context).settings,
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (BuildContext context) =>
                  const SettingsTabRiverpod(), // Riverpod version
            ),
          );
        },
        color: Colors.white,
        backgroundColor: Colors.white.withValues(alpha: 0.15),
        iconSize: 20,
      ),
      const SizedBox(width: 6),
      // أيقونة التنبيهات مع شارة
      AlertBadge(
        child: ActionButtonWidget(
          context: context,
          icon: Icons.notifications,
          tooltip: AppLocalizations.of(context).notifications,
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (BuildContext context) => const AlertsTabRiverpod(),
              ),
            );
          },
          color: Colors.white,
          backgroundColor: Colors.white.withValues(alpha: 0.15),
          iconSize: 20,
        ),
      ),
    ];
}
