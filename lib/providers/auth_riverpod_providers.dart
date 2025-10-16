import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/error_handler_service.dart';
import '../services/presence_service.dart';

/// Riverpod wrapper for AuthProvider
class AuthRiverpodNotifier extends StateNotifier<AuthState> {
  AuthRiverpodNotifier() : super(const AuthState()) {
    _listenToAuthChanges();
  }

  final AuthService _authService = AuthService.instance;
  final PresenceService _presenceService = PresenceService.instance;

  void _setLoading(bool value) {
    state = state.copyWith(isLoading: value);
  }

  void _setError(String? message) {
    state = state.copyWith(errorMessage: message);
  }

  void _listenToAuthChanges() {
    _authService.authStateChanges().listen((fb_auth.User? user) async {
      state = state.copyWith(firebaseUser: user);
      if (user == null) {
        state = state.copyWith(appUser: null);
        // إيقاف جلسة الحضور عند تسجيل الخروج
        await _presenceService.goOffline();
        _setLoading(false);
        return;
      }
      _setLoading(true);
      try {
        final AppUser? appUser = await _authService.getCurrentAppUser();
        state = state.copyWith(appUser: appUser, errorMessage: null);

        // بدء جلسة الحضور عند تسجيل الدخول الناجح
        if (appUser != null) {
          await _presenceService.goOnline(appUser.uid);
        }
      } on Exception catch (e, stackTrace) {
        await ErrorHandlerService.handleError(
          e,
          stackTrace: stackTrace.toString(),
          type: ErrorType.unknown,
          severity: ErrorSeverity.high,
          userAction: 'تحميل بيانات المستخدم في AuthRiverpodNotifier',
          context: <String, dynamic>{
            'operation': '_listenToAuthChanges',
            'provider': 'AuthRiverpodNotifier',
            'userId': user.uid,
          },
        );
        _setError('فشل تحميل بيانات المستخدم');
      } finally {
        _setLoading(false);
      }
    });
  }

  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    try {
      final AppUser user =
          await _authService.signInWithEmail(email: email, password: password);
      state = state.copyWith(appUser: user, errorMessage: null);
    } on fb_auth.FirebaseAuthException catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.firebase,
        severity: ErrorSeverity.high,
        userAction: 'تسجيل الدخول في AuthRiverpodNotifier',
        context: <String, dynamic>{
          'operation': 'signIn',
          'provider': 'AuthRiverpodNotifier',
          'email': email,
          'errorCode': e.code,
        },
      );
      _setError(_mapAuthError(e));
    } finally {
      _setLoading(false);
    }
  }

  Future<void> signOut() async {
    // إيقاف جلسة الحضور قبل تسجيل الخروج
    await _presenceService.goOffline();
    await _authService.signOut();
  }

  Future<void> resetPassword(String email) async {
    _setLoading(true);
    try {
      await _authService.resetPassword(email: email);
      _setError(null);
    } on fb_auth.FirebaseAuthException catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.firebase,
        userAction: 'إعادة تعيين كلمة المرور في AuthRiverpodNotifier',
        context: <String, dynamic>{
          'operation': 'resetPassword',
          'provider': 'AuthRiverpodNotifier',
          'email': email,
          'errorCode': e.code,
        },
      );
      _setError(_mapResetPasswordError(e));
    } finally {
      _setLoading(false);
    }
  }

  String _mapAuthError(fb_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'بيانات الدخول غير صحيحة';
      case 'too-many-requests':
        return 'محاولات كثيرة، يرجى المحاولة لاحقاً';
      case 'network-request-failed':
        return 'تحقق من اتصال الإنترنت';
      default:
        return 'حدث خطأ غير متوقع';
    }
  }

  String _mapResetPasswordError(fb_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
        return 'لا يوجد حساب مرتبط بهذا البريد الإلكتروني';
      case 'invalid-email':
        return 'البريد الإلكتروني غير صحيح';
      case 'too-many-requests':
        return 'محاولات كثيرة، يرجى المحاولة لاحقاً';
      case 'network-request-failed':
        return 'تحقق من اتصال الإنترنت';
      default:
        return 'حدث خطأ في إعادة تعيين كلمة المرور';
    }
  }
}

/// حالة المصادقة
class AuthState {
  final AppUser? appUser;
  final fb_auth.User? firebaseUser;
  final bool isLoading;
  final String? errorMessage;

  const AuthState({
    this.appUser,
    this.firebaseUser,
    this.isLoading = true,
    this.errorMessage,
  });

  bool get isAuthenticated => firebaseUser != null;
  bool get isAdmin => appUser?.isAdmin == true;
  bool get isSeller => appUser?.isSeller == true;

  AuthState copyWith({
    AppUser? appUser,
    fb_auth.User? firebaseUser,
    bool? isLoading,
    String? errorMessage,
  }) {
    return AuthState(
      appUser: appUser ?? this.appUser,
      firebaseUser: firebaseUser ?? this.firebaseUser,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

// ========== Providers ==========

/// Provider الرئيسي لحالة المصادقة
final authStateProvider =
    StateNotifierProvider.autoDispose<AuthRiverpodNotifier, AuthState>(
  (ref) => AuthRiverpodNotifier(),
);

/// Provider للتحقق من حالة المصادقة
final isAuthenticatedProvider = Provider.autoDispose<bool>(
  (ref) {
    final AuthState state = ref.watch(authStateProvider);
    return state.isAuthenticated;
  },
  dependencies: [authStateProvider],
);

/// Provider للتحقق من حالة التحميل
final authLoadingProvider = Provider.autoDispose<bool>(
  (ref) {
    final AuthState state = ref.watch(authStateProvider);
    return state.isLoading;
  },
  dependencies: [authStateProvider],
);

/// Provider للتحقق من صلاحيات المدير
final isAdminProvider = Provider.autoDispose<bool>(
  (ref) {
    final AuthState state = ref.watch(authStateProvider);
    return state.isAdmin;
  },
  dependencies: [authStateProvider],
);

/// Provider للتحقق من صلاحيات البائع
final isSellerProvider = Provider.autoDispose<bool>(
  (ref) {
    final AuthState state = ref.watch(authStateProvider);
    return state.isSeller;
  },
  dependencies: [authStateProvider],
);

/// Provider لبيانات المستخدم
final appUserProvider = Provider.autoDispose<AppUser?>(
  (ref) {
    final AuthState state = ref.watch(authStateProvider);
    return state.appUser;
  },
  dependencies: [authStateProvider],
);

/// Provider لرسالة الخطأ
final authErrorProvider = Provider.autoDispose<String?>(
  (ref) {
    final AuthState state = ref.watch(authStateProvider);
    return state.errorMessage;
  },
  dependencies: [authStateProvider],
);
