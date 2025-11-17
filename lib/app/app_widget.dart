import 'package:adaptive_theme/adaptive_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../l10n/app_localizations.dart';
import '../services/appearance_service.dart';
import '../services/locale_service.dart';
import '../theme/app_theme.dart';
import '../utils/provider_logger.dart';
import 'auth_wrapper.dart';

/// التطبيق الرئيسي مع Riverpod فقط
class StreamProfitCalculatorApp extends StatelessWidget {
  const StreamProfitCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) => ProviderScope(
        observers: <ProviderObserver>[
          ProviderLogger(), // مراقبة تحديثات Cart Provider
        ],
        child: Consumer(
          builder: (BuildContext context, WidgetRef ref, _) => AdaptiveTheme(
            light: AppTheme.lightTheme,
            dark: AppTheme.darkTheme,
            initial: AdaptiveThemeMode.system,
            builder: (ThemeData light, ThemeData dark) => MaterialApp(
              title: 'حاسبة الأرباح - Pure Riverpod Edition',
              theme: light.copyWith(
                textTheme: AppTheme.localizedTextThemeFor(
                  light.textTheme,
                  ref.watch(currentLocaleProvider),
                  fontKey: AppearanceService.instance.fontKeyNotifier.value,
                ),
              ),
              darkTheme: dark.copyWith(
                textTheme: AppTheme.localizedTextThemeFor(
                  dark.textTheme,
                  ref.watch(currentLocaleProvider),
                  fontKey: AppearanceService.instance.fontKeyNotifier.value,
                ),
              ),
              builder: (BuildContext context, Widget? child) {
                final MediaQueryData media = MediaQuery.of(context);
                final TextScaler clamped = media.textScaler
                    .clamp(minScaleFactor: 0.85, maxScaleFactor: 1.2);
                return MediaQuery(
                  data: media.copyWith(textScaler: clamped),
                  child: child ?? const SizedBox.shrink(),
                );
              },
              localizationsDelegates: const <LocalizationsDelegate<dynamic>>[
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
                AppLocalizations.delegate,
              ],
              supportedLocales: ref.watch(supportedLocalesProvider),
              locale: ref.watch(currentLocaleProvider),
              home: const AuthWrapper(),
            ),
          ),
        ),
      );
}
