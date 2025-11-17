import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../models/app_user.dart';
import '../providers/auth_riverpod_providers.dart';
import '../providers/settings_riverpod_providers.dart';
import '../services/appearance_service.dart';
import '../services/auth_service.dart';
import '../services/locale_service.dart';
import '../utils/constants.dart';
import 'data_cleanup_screen.dart';
import 'user_management_screen.dart';

/// شاشة الإعدادات للوضع غير المتصل والإشعارات - Riverpod Version
class SettingsTabRiverpod extends ConsumerStatefulWidget {
  const SettingsTabRiverpod({super.key});

  @override
  ConsumerState<SettingsTabRiverpod> createState() =>
      _SettingsTabRiverpodState();
}

class _SettingsTabRiverpodState extends ConsumerState<SettingsTabRiverpod> {
  @override
  void initState() {
    super.initState();
    // تحميل الإعدادات وإعداد مستمع الاتصال
    Future.microtask(() {
      ref.read(settingsNotifierProvider.notifier).loadSettings();
    });
  }

  /// بناء شريط تطبيق حديث
  PreferredSizeWidget _buildModernAppBar(BuildContext context) => AppBar(
        title: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: <Color>[
                    Colors.white.withValues(alpha: 0.2),
                    Colors.white.withValues(alpha: 0.1),
                  ],
                ),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.3),
                ),
              ),
              child: const Icon(Icons.settings, size: 26, color: Colors.white),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    AppLocalizations.of(context).settingsAppBar,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context).appManagement,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: AppConstants.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                AppConstants.primaryColor,
                AppConstants.primaryColor.withValues(alpha: 0.9),
                AppConstants.primaryColor.withValues(alpha: 0.8),
              ],
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: AppConstants.primaryColor.withValues(alpha: 0.4),
                blurRadius: 15,
                offset: const Offset(0, 5),
              ),
            ],
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(25),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final SettingsState settingsState = ref.watch(settingsNotifierProvider);
    final SettingsNotifier settingsNotifier =
        ref.read(settingsNotifierProvider.notifier);
    final bool isAdmin = ref.watch(isAdminProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildModernAppBar(context),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: <Color>[
              Colors.grey[50]!,
              Colors.grey[100]!,
            ],
          ),
        ),
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) =>
              ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: constraints.maxHeight,
              maxHeight: constraints.maxHeight,
            ),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: <Widget>[
                // بطاقة ترحيبية
                _buildWelcomeCard(context),
                const SizedBox(height: 24),

                // إدارة المستخدمين (للمدير فقط)
                if (isAdmin)
                  _buildModernSectionCard(
                    title: 'إدارة المستخدمين',
                    icon: Icons.supervised_user_circle,
                    color: Colors.brown,
                    child: _buildUserManagementCard(),
                    isExpanded: settingsState.isUserMgmtExpanded,
                    onToggle: () =>
                        settingsNotifier.toggleExpansion('userMgmt'),
                  )
                else
                  const SizedBox.shrink(),
                const SizedBox(height: 20),

                // قسم حالة الاتصال
                _buildModernSectionCard(
                  title: AppLocalizations.of(context).connectionStatus,
                  icon: Icons.wifi,
                  color: settingsState.isOnline ? Colors.green : Colors.red,
                  child: _buildConnectionStatusCard(settingsState),
                  isExpanded: settingsState.isConnectionExpanded,
                  onToggle: () =>
                      settingsNotifier.toggleExpansion('connection'),
                ),
                const SizedBox(height: 20),

                // قسم اللغة
                _buildModernSectionCard(
                  title: AppLocalizations.of(context).languageAndRegion,
                  icon: Icons.language,
                  color: Colors.blue,
                  child: _buildLanguageCard(),
                  isExpanded: settingsState.isLanguageExpanded,
                  onToggle: () => settingsNotifier.toggleExpansion('language'),
                ),
                const SizedBox(height: 20),

                // قسم المظهر
                _buildModernSectionCard(
                  title: 'المظهر والخطوط',
                  icon: Icons.color_lens,
                  color: Colors.indigo,
                  child: _buildAppearanceCard(),
                  isExpanded: settingsState.isAppearanceExpanded,
                  onToggle: () =>
                      settingsNotifier.toggleExpansion('appearance'),
                ),
                const SizedBox(height: 20),

                // قسم الإشعارات
                _buildModernSectionCard(
                  title: AppLocalizations.of(context).notificationsSettings,
                  icon: Icons.notifications,
                  color: Colors.orange,
                  child:
                      _buildNotificationsCard(settingsState, settingsNotifier),
                  isExpanded: settingsState.isNotificationsExpanded,
                  onToggle: () =>
                      settingsNotifier.toggleExpansion('notifications'),
                ),
                const SizedBox(height: 20),

                // قسم التذكيرات
                _buildModernSectionCard(
                  title: AppLocalizations.of(context).remindersSettings,
                  icon: Icons.schedule,
                  color: Colors.green,
                  child: _buildRemindersCard(settingsState, settingsNotifier),
                  isExpanded: settingsState.isRemindersExpanded,
                  onToggle: () => settingsNotifier.toggleExpansion('reminders'),
                ),
                const SizedBox(height: 20),

                // قسم الإجراءات
                _buildModernSectionCard(
                  title: AppLocalizations.of(context).actionsSettings,
                  icon: Icons.build,
                  color: Colors.purple,
                  child: _buildActionsCard(settingsNotifier),
                  isExpanded: settingsState.isActionsExpanded,
                  onToggle: () => settingsNotifier.toggleExpansion('actions'),
                ),
                const SizedBox(height: 20),

                // قسم معلومات التطبيق
                _buildModernSectionCard(
                  title: AppLocalizations.of(context).appInfoSettings,
                  icon: Icons.info,
                  color: Colors.teal,
                  child: _buildAppInfoCard(),
                  isExpanded: settingsState.isAppInfoExpanded,
                  onToggle: () => settingsNotifier.toggleExpansion('appInfo'),
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// بناء بطاقة ترحيبية
  Widget _buildWelcomeCard(BuildContext context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              AppConstants.primaryColor,
              AppConstants.primaryColor.withValues(alpha: 0.8),
            ],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppConstants.primaryColor.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.settings_applications,
                color: Colors.white,
                size: 32,
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    AppLocalizations.of(context).welcomeToSettings,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    AppLocalizations.of(context).customizeApp,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.white.withValues(alpha: 0.9),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  /// بناء بطاقة قسم حديثة قابلة للتوسع
  Widget _buildModernSectionCard({
    required String title,
    required IconData icon,
    required Color color,
    required Widget child,
    required bool isExpanded,
    required VoidCallback onToggle,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: 0.1),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: color.withValues(alpha: 0.1),
              blurRadius: 15,
              offset: const Offset(0, 5),
            ),
            BoxShadow(
              color: Colors.grey.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: <Widget>[
            // عنوان القسم القابل للنقر
            InkWell(
              onTap: onToggle,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(20),
                topRight: Radius.circular(20),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: <Color>[
                      color.withValues(alpha: 0.1),
                      color.withValues(alpha: 0.05),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: <Color>[color, color.withValues(alpha: 0.8)],
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: color.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(icon, color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: isExpanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 300),
                      child: Icon(
                        Icons.keyboard_arrow_down,
                        color: color,
                        size: 28,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // محتوى القسم مع انيميشن التوسع
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              height: isExpanded ? null : 0,
              child: isExpanded
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: child,
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      );

  /// بطاقة اختيار اللغة
  Widget _buildLanguageCard() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            AppLocalizations.of(context).language,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<Locale>(
            decoration: InputDecoration(
              labelText: AppLocalizations.of(context).chooseLanguage,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.blue, width: 2),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              filled: true,
              fillColor: Colors.grey[50],
            ),
            initialValue: _currentLocaleForDropdown(),
            items: ref
                .watch(supportedLocalesProvider)
                .map((Locale l) => DropdownMenuItem<Locale>(
                      value: l,
                      child: Row(
                        children: <Widget>[
                          Icon(
                            _getLocaleIcon(l.languageCode),
                            size: 20,
                            color: Colors.blue,
                          ),
                          const SizedBox(width: 8),
                          Text(_labelForLocale(l.languageCode)),
                        ],
                      ),
                    ))
                .toList(),
            onChanged: (Locale? l) async {
              await ref.read(localeNotifierProvider.notifier).setLocale(l);
              if (mounted) setState(() {});
            },
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalizations.of(context).pleaseWait,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      );

  /// بطاقة المظهر والثيم والخط
  Widget _buildAppearanceCard() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // تبديل وضع الثيم
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.indigo.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.brightness_6,
                      color: Colors.indigo, size: 20),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'نمط الثيم',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                DropdownButton<AdaptiveThemeMode>(
                  value: AdaptiveTheme.of(context).mode,
                  onChanged: (AdaptiveThemeMode? mode) {
                    if (mode == null) return;
                    switch (mode) {
                      case AdaptiveThemeMode.light:
                        AdaptiveTheme.of(context).setLight();
                        break;
                      case AdaptiveThemeMode.dark:
                        AdaptiveTheme.of(context).setDark();
                        break;
                      case AdaptiveThemeMode.system:
                        AdaptiveTheme.of(context).setSystem();
                        break;
                    }
                    setState(() {});
                  },
                  items: const <DropdownMenuItem<AdaptiveThemeMode>>[
                    DropdownMenuItem(
                        value: AdaptiveThemeMode.system,
                        child: Text('افتراضي النظام')),
                    DropdownMenuItem(
                        value: AdaptiveThemeMode.light, child: Text('فاتح')),
                    DropdownMenuItem(
                        value: AdaptiveThemeMode.dark, child: Text('داكن')),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // اختيار الخط
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.indigo.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.indigo.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.font_download,
                      color: Colors.indigo, size: 20),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'عائلة الخط',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ),
                ValueListenableBuilder<String>(
                  valueListenable: AppearanceService.instance.fontKeyNotifier,
                  builder: (BuildContext context, String value, Widget? _) =>
                      DropdownButton<String>(
                    value: value,
                    onChanged: (String? key) async {
                      if (key == null) return;
                      await AppearanceService.instance.setFontKey(key);
                      if (mounted) setState(() {});
                    },
                    items: const <DropdownMenuItem<String>>[
                      DropdownMenuItem(
                          value: 'auto', child: Text('تلقائي (حسب اللغة)')),
                      DropdownMenuItem(
                          value: 'cairo', child: Text('Cairo (عربي)')),
                      DropdownMenuItem(
                          value: 'tajawal', child: Text('Tajawal (عربي)')),
                      DropdownMenuItem(
                          value: 'poppins', child: Text('Poppins (لاتيني)')),
                      DropdownMenuItem(
                          value: 'lato', child: Text('Lato (لاتيني)')),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );

  Locale? _currentLocaleForDropdown() =>
      ref.watch(currentLocaleProvider) ?? const Locale('ar');

  String _labelForLocale(String code) => switch (code) {
        'ar' => 'العربية',
        'en' => 'English',
        'fr' => 'Français',
        _ => code,
      };

  IconData _getLocaleIcon(String code) => switch (code) {
        'ar' => Icons.language,
        'en' => Icons.public,
        'fr' => Icons.flag,
        _ => Icons.language,
      };

  /// بطاقة الإشعارات
  Widget _buildNotificationsCard(
          SettingsState settingsState, SettingsNotifier settingsNotifier) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSwitchTile(
            title: AppLocalizations.of(context).enableNotifications,
            subtitle: AppLocalizations.of(context).enableNotificationsDesc,
            value: settingsState.notificationsEnabled,
            onChanged: (bool value) =>
                settingsNotifier.toggleNotifications(value),
            icon: Icons.notifications,
            color: Colors.orange,
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            title: AppLocalizations.of(context).lowStockAlerts,
            subtitle: AppLocalizations.of(context).lowStockAlertsDesc,
            value: settingsState.lowStockAlertsEnabled,
            onChanged: (bool value) =>
                settingsNotifier.toggleLowStockAlerts(value),
            icon: Icons.warning,
            color: Colors.red,
          ),
        ],
      );

  /// بناء عنصر تبديل
  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    required IconData icon,
    required Color color,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeThumbColor: color,
              activeTrackColor: color.withValues(alpha: 0.3),
            ),
          ],
        ),
      );

  /// بطاقة التذكيرات
  Widget _buildRemindersCard(
          SettingsState settingsState, SettingsNotifier settingsNotifier) =>
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildSwitchTile(
            title: AppLocalizations.of(context).dailyReminders,
            subtitle: AppLocalizations.of(context).dailyRemindersDesc,
            value: settingsState.dailyRemindersEnabled,
            onChanged: (bool value) =>
                settingsNotifier.toggleDailyReminders(value),
            icon: Icons.today,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          _buildSwitchTile(
            title: AppLocalizations.of(context).weeklyReminders,
            subtitle: AppLocalizations.of(context).weeklyRemindersDesc,
            value: settingsState.weeklyRemindersEnabled,
            onChanged: (bool value) =>
                settingsNotifier.toggleWeeklyReminders(value),
            icon: Icons.calendar_today,
            color: Colors.blue,
          ),
        ],
      );

  /// بطاقة حالة الاتصال
  Widget _buildConnectionStatusCard(SettingsState settingsState) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // مؤشر حالة الاتصال الرئيسي
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: settingsState.isOnline
                  ? Colors.green.withValues(alpha: 0.1)
                  : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: settingsState.isOnline
                    ? Colors.green.withValues(alpha: 0.3)
                    : Colors.red.withValues(alpha: 0.3),
              ),
            ),
            child: Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: settingsState.isOnline ? Colors.green : Colors.red,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    settingsState.isOnline ? Icons.wifi : Icons.wifi_off,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        settingsState.isOnline
                            ? AppLocalizations.of(context).connectedToInternet
                            : AppLocalizations.of(context)
                                .notConnectedToInternet,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: settingsState.isOnline
                              ? Colors.green[700]
                              : Colors.red[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        settingsState.isOnline
                            ? AppLocalizations.of(context).appConnectedMessage
                            : AppLocalizations.of(context).appOfflineMessage,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // معلومات إضافية عن الاتصال
          _buildConnectionInfoItem(
            icon: Icons.signal_wifi_4_bar,
            title: AppLocalizations.of(context).connectionType,
            value: settingsState.isOnline
                ? AppLocalizations.of(context).available
                : AppLocalizations.of(context).unavailable,
            color: settingsState.isOnline ? Colors.green : Colors.red,
          ),
          const SizedBox(height: 12),
          _buildConnectionInfoItem(
            icon: Icons.sync,
            title: AppLocalizations.of(context).syncStatus,
            value: settingsState.isOnline
                ? AppLocalizations.of(context).automatic
                : AppLocalizations.of(context).manual,
            color: settingsState.isOnline ? Colors.blue : Colors.orange,
          ),
          const SizedBox(height: 12),
          _buildConnectionInfoItem(
            icon: Icons.cloud_off,
            title: AppLocalizations.of(context).localData,
            value: AppLocalizations.of(context).available,
            color: Colors.teal,
          ),
        ],
      );

  /// بناء عنصر معلومات الاتصال
  Widget _buildConnectionInfoItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Flexible(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.left,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      );

  /// بطاقة الإجراءات
  Widget _buildActionsCard(SettingsNotifier settingsNotifier) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildActionTile(
            title: 'النسخ الاحتياطي والاستعادة',
            subtitle: 'إدارة النسخ الاحتياطية واستعادة البيانات',
            icon: Icons.backup,
            color: Colors.blue,
            onTap: _openBackupRestoreScreen,
          ),
          const SizedBox(height: 12),
          _buildActionTile(
            title: 'تنظيف البيانات المحلية',
            subtitle: 'إدارة وتنظيف البيانات المحلية',
            icon: Icons.cleaning_services,
            color: Colors.orange,
            onTap: _openDataCleanupScreen,
          ),
          const SizedBox(height: 12),
          _buildActionTile(
            title: AppLocalizations.of(context).cleanupData,
            subtitle: AppLocalizations.of(context).cleanupDataDesc,
            icon: Icons.cleaning_services,
            color: Colors.orange,
            onTap: () => _showCleanupDialog(settingsNotifier),
          ),
          const SizedBox(height: 12),
          _buildActionTile(
            title: AppLocalizations.of(context).resetSettings,
            subtitle: AppLocalizations.of(context).resetSettingsDesc,
            icon: Icons.refresh,
            color: Colors.red,
            onTap: () => _showResetSettingsDialog(settingsNotifier),
          ),
          const SizedBox(height: 12),
          _buildActionTile(
            title: 'تسجيل الخروج',
            subtitle: 'الخروج من الحساب والعودة لشاشة تسجيل الدخول',
            icon: Icons.logout,
            color: Colors.red.shade700,
            onTap: _showLogoutDialog,
          ),
        ],
      );

  /// بناء عنصر إجراء
  Widget _buildActionTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) =>
      Container(
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: ListTile(
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          subtitle: Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          trailing: Icon(
            Icons.arrow_forward_ios,
            size: 16,
            color: color,
          ),
          onTap: onTap,
        ),
      );

  /// بناء بطاقة معلومات التطبيق
  Widget _buildAppInfoCard() => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          _buildInfoItem(
            icon: Icons.info_outline,
            title: AppLocalizations.of(context).appVersion,
            value: '1.0.0',
            color: Colors.blue,
          ),
          const SizedBox(height: 16),
          _buildInfoItem(
            icon: Icons.developer_mode,
            title: AppLocalizations.of(context).developer,
            value: AppLocalizations.of(context).developmentTeam,
            color: Colors.green,
          ),
          const SizedBox(height: 16),
          _buildInfoItem(
            icon: Icons.update,
            title: AppLocalizations.of(context).lastUpdate,
            value: 'ديسمبر 2024',
            color: Colors.orange,
          ),
          const SizedBox(height: 20),
          Text(
            AppLocalizations.of(context).availableFeatures,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          _buildFeatureChip(
              AppLocalizations.of(context).offlineWork, Colors.blue),
          const SizedBox(height: 8),
          _buildFeatureChip(
              AppLocalizations.of(context).autoSync, Colors.green),
          const SizedBox(height: 8),
          _buildFeatureChip(
              AppLocalizations.of(context).localNotifications, Colors.orange),
          const SizedBox(height: 8),
          _buildFeatureChip(
              AppLocalizations.of(context).scheduledReminders, Colors.purple),
          const SizedBox(height: 8),
          _buildFeatureChip(
              AppLocalizations.of(context).autoDataCleanup, Colors.teal),
        ],
      );

  /// بناء عنصر معلومات
  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) =>
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  /// بناء شريحة ميزة
  Widget _buildFeatureChip(String feature, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: color.withValues(alpha: 0.3),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(
              Icons.check_circle,
              size: 16,
              color: color,
            ),
            const SizedBox(width: 8),
            Text(
              feature,
              style: TextStyle(
                fontSize: 14,
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      );

  /// فتح شاشة النسخ الاحتياطي والاستعادة
  void _openBackupRestoreScreen() {
    // TODO: Implement backup restore screen
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('شاشة النسخ الاحتياطي قيد التطوير'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  /// فتح شاشة تنظيف البيانات المحلية
  void _openDataCleanupScreen() {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (BuildContext context) => const DataCleanupScreen(),
      ),
    );
  }

  void _showCleanupDialog(SettingsNotifier settingsNotifier) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(AppLocalizations.of(context).cleanupConfirm),
        content: Text(AppLocalizations.of(context).cleanupConfirmMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              // حفظ reference للـ ScaffoldMessenger قبل إغلاق الحوار
              final ScaffoldMessengerState scaffoldMessenger =
                  ScaffoldMessenger.of(context);
              final String successMessage =
                  AppLocalizations.of(context).cleanupSuccessMessage;

              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }

              await settingsNotifier.performCleanup();

              // استخدام المرجع المحفوظ لعرض الرسالة
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(successMessage),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context).cleanup),
          ),
        ],
      ),
    );
  }

  void _showResetSettingsDialog(SettingsNotifier settingsNotifier) {
    showDialog<void>(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        title: Text(AppLocalizations.of(context).resetConfirm),
        content: Text(AppLocalizations.of(context).resetConfirmMessage),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(AppLocalizations.of(context).cancel),
          ),
          ElevatedButton(
            onPressed: () async {
              // حفظ reference للـ ScaffoldMessenger قبل إغلاق الحوار
              final ScaffoldMessengerState scaffoldMessenger =
                  ScaffoldMessenger.of(context);
              final String successMessage =
                  AppLocalizations.of(context).resetSuccessMessage;

              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              }

              await settingsNotifier.resetSettings();

              // استخدام المرجع المحفوظ لعرض الرسالة
              scaffoldMessenger.showSnackBar(
                SnackBar(
                  content: Text(successMessage),
                  backgroundColor: Colors.green,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: Text(AppLocalizations.of(context).reset),
          ),
        ],
      ),
    );
  }

  /// حوار تسجيل الخروج
  void _showLogoutDialog() {
    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) => AlertDialog(
        title: const Text('تسجيل الخروج'),
        content: const Text('هل أنت متأكد من رغبتك في تسجيل الخروج؟'),
        actions: <Widget>[
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () async {
              // حفظ المرجع قبل إغلاق الحوار
              final WidgetRef currentRef = ref;

              // إغلاق الحوار أولاً
              Navigator.of(dialogContext).pop();

              // تسجيل الخروج (سيتم توجيه المستخدم تلقائياً لشاشة تسجيل الدخول)
              try {
                await currentRef.read(authStateProvider.notifier).signOut();
              } catch (e) {
                debugPrint('⚠️ خطأ في تسجيل الخروج: $e');
                // لا نحاول إغلاق شاشة الإعدادات يدوياً - AuthWrapper سيفعل ذلك تلقائياً
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('تسجيل الخروج'),
          ),
        ],
      ),
    );
  }

  /// بطاقة إدارة المستخدمين (مدير)
  Widget _buildUserManagementCard() {
    final AuthService authService = AuthService.instance;
    return _UserManagementCard(authService: authService);
  }
}

/// بطاقة إدارة المستخدمين منفصلة لضمان تنظيف TextEditingController
class _UserManagementCard extends ConsumerStatefulWidget {
  const _UserManagementCard({required this.authService});
  final AuthService authService;

  @override
  ConsumerState<_UserManagementCard> createState() =>
      _UserManagementCardState();
}

class _UserManagementCardState extends ConsumerState<_UserManagementCard> {
  final TextEditingController _uidController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  UserRole _selectedRole = UserRole.seller;

  @override
  void dispose() {
    _uidController.dispose();
    _emailController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text('قائمة المستخدمين',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700])),
              ),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (BuildContext context) =>
                          const UserManagementScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.manage_accounts),
                label: const Text('إدارة متقدمة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.purple,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.brown.withValues(alpha: 0.2)),
            ),
            child: StreamBuilder<List<AppUser>>(
              stream: widget.authService.usersStream(),
              builder: (BuildContext context,
                  AsyncSnapshot<List<AppUser>> snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final List<AppUser> users = snapshot.data ?? <AppUser>[];
                if (users.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('لا يوجد مستخدمون بعد'),
                  );
                }
                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemBuilder: (BuildContext context, int index) {
                    final AppUser u = users[index];
                    return ListTile(
                      title: Text(u.displayName?.isNotEmpty == true
                          ? u.displayName!
                          : u.email),
                      subtitle:
                          Text('${u.email} • ${u.isAdmin ? 'مدير' : 'بائع'}'),
                      trailing: DropdownButton<UserRole>(
                        value: u.role,
                        onChanged: (UserRole? val) async {
                          if (val == null) return;
                          await widget.authService
                              .setUserRole(uid: u.uid, role: val);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      'تم تحديث دور ${u.email} إلى ${val == UserRole.admin ? 'مدير' : 'بائع'}')),
                            );
                          }
                        },
                        items: const <DropdownMenuItem<UserRole>>[
                          DropdownMenuItem(
                              value: UserRole.admin, child: Text('مدير')),
                          DropdownMenuItem(
                              value: UserRole.seller, child: Text('بائع')),
                        ],
                      ),
                    );
                  },
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemCount: users.length,
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          Text('إضافة/تحديث مستخدم (بوثيقة Firestore فقط)',
              style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[700])),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _uidController,
                  decoration: const InputDecoration(
                    labelText: 'UID',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'البريد الإلكتروني',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'الاسم (اختياري)',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              DropdownButton<UserRole>(
                value: _selectedRole,
                onChanged: (UserRole? v) {
                  if (v == null) return;
                  setState(() => _selectedRole = v);
                },
                items: const <DropdownMenuItem<UserRole>>[
                  DropdownMenuItem(value: UserRole.admin, child: Text('مدير')),
                  DropdownMenuItem(value: UserRole.seller, child: Text('بائع')),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: ElevatedButton.icon(
              onPressed: () async {
                final String uid = _uidController.text.trim();
                final String email = _emailController.text.trim();
                final String name = _nameController.text.trim();
                if (uid.isEmpty || email.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('الـ UID والبريد مطلوبان')),
                  );
                  return;
                }
                await widget.authService.upsertUserDoc(
                  uid: uid,
                  email: email,
                  displayName: name.isEmpty ? null : name,
                  role: _selectedRole,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم حفظ وثيقة المستخدم')),
                  );
                }
              },
              icon: const Icon(Icons.save),
              label: const Text('حفظ المستخدم'),
            ),
          ),
        ],
      );
}
