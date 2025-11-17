import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/auth_riverpod_providers.dart';
import '../providers/riverpod/stream_app_riverpod_provider.dart';
import '../screens/login_screen.dart';
import '../screens/main_screen/main_screen.dart';

// TODO: تعطيل مؤقت - إزالة هذا الثابت لإعادة تفعيل شاشة الدخول
const bool _disableLoginTemporarily = true;

class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch both providers for changes.
    final AuthState auth = ref.watch(authStateProvider);
    final AppState appState = ref.watch(appControllerProvider);

    // Show a loading screen if auth is processing or the app provider is not ready.
    if (auth.isLoading || !appState.isInitialized) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text(
                'جاري تهيئة التطبيق...',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    // تعطيل مؤقت لشاشة الدخول - تجاوز فحص المصادقة
    if (_disableLoginTemporarily) {
      return const StreamProfitCalculatorScreen();
    }

    // If the user is not authenticated, show the login screen.
    if (!auth.isAuthenticated) {
      return const LoginScreen();
    }

    // Once authenticated and providers are ready, show the main screen.
    return const StreamProfitCalculatorScreen();
  }
}
