import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/error_handler_service.dart';
import '../services/presence_service.dart';

/// حالة المصادقة
@immutable
class AuthState {
  const AuthState({
    this.appUser,
    this.firebaseUser,
    this.isLoading = true,
    this.errorMessage,
  });

  final AppUser? appUser;
  final fb_auth.User? firebaseUser;
  final bool isLoading;
  final String? errorMessage;

  bool get isAuthenticated => firebaseUser != null;
  bool get isAdmin => appUser?.isAdmin == true;
  bool get isSeller => appUser?.isSeller == true;

  AuthState copyWith({
    AppUser? appUser,
    fb_auth.User? firebaseUser,
    bool? isLoading,
    String? errorMessage,
  }) =>
      AuthState(
        appUser: appUser ?? this.appUser,
        firebaseUser: firebaseUser ?? this.firebaseUser,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: errorMessage ?? this.errorMessage,
      );
}

/// مزود حالة المصادقة والأدوار
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
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
    _authService.authStateChanges().listen((fb_auth.User? user) {
      // استخدام SchedulerBinding للتأكد من platform thread
      SchedulerBinding.instance.addPostFrameCallback((_) {
        // استخدام Future.microtask للتأكد من platform thread
        Future.microtask(() async {
          state = state.copyWith(firebaseUser: user);
          if (user == null) {
            // إيقاف جلسة الحضور عند تسجيل الخروج
            await _presenceService.goOffline();
            state = state.copyWith(
              isLoading: false,
            );
            return;
          }
          _setLoading(true);
          try {
            final AppUser? appUser = await _authService.getCurrentAppUser();
            state = state.copyWith(
              appUser: appUser,
            );

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
              userAction: 'تحميل بيانات المستخدم في AuthNotifier',
              context: <String, dynamic>{
                'operation': '_listenToAuthChanges',
                'provider': 'AuthNotifier',
                'userId': user.uid,
              },
            );
            _setError('فشل تحميل بيانات المستخدم');
          } finally {
            _setLoading(false);
          }
        });
      });
    });
  }

  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    try {
      final AppUser user =
          await _authService.signInWithEmail(email: email, password: password);
      state = state.copyWith(
        appUser: user,
      );
    } on fb_auth.FirebaseAuthException catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.firebase,
        severity: ErrorSeverity.high,
        userAction: 'تسجيل الدخول في AuthNotifier',
        context: <String, dynamic>{
          'operation': 'signIn',
          'provider': 'AuthNotifier',
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
    // إعادة تعيين الحالة
    state = const AuthState();
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
        userAction: 'إعادة تعيين كلمة المرور في AuthNotifier',
        context: <String, dynamic>{
          'operation': 'resetPassword',
          'provider': 'AuthNotifier',
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

// ========== Riverpod Providers ==========

/// Provider للـ AuthNotifier
final StateNotifierProvider<AuthNotifier, AuthState> authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>(
        (StateNotifierProviderRef<AuthNotifier, AuthState> ref) =>
            AuthNotifier());

/// Provider لحالة المصادقة
final Provider<AuthState> authStateProvider = Provider<AuthState>(
    (ProviderRef<AuthState> ref) => ref.watch(authNotifierProvider));

/// Provider للمستخدم الحالي
final Provider<AppUser?> currentUserProvider = Provider<AppUser?>(
    (ProviderRef<AppUser?> ref) => ref.watch(authStateProvider).appUser);

/// Provider لحالة التحميل
final Provider<bool> authLoadingProvider = Provider<bool>(
    (ProviderRef<bool> ref) => ref.watch(authStateProvider).isLoading);

/// Provider لرسالة الخطأ
final Provider<String?> authErrorProvider = Provider<String?>(
    (ProviderRef<String?> ref) => ref.watch(authStateProvider).errorMessage);

/// Provider لحالة المصادقة
final Provider<bool> isAuthenticatedProvider = Provider<bool>(
    (ProviderRef<bool> ref) => ref.watch(authStateProvider).isAuthenticated);

/// Provider للتحقق من صلاحية المدير
final Provider<bool> isAdminProvider = Provider<bool>(
    (ProviderRef<bool> ref) => ref.watch(authStateProvider).isAdmin);

/// Provider للتحقق من صلاحية البائع
final Provider<bool> isSellerProvider = Provider<bool>(
    (ProviderRef<bool> ref) => ref.watch(authStateProvider).isSeller);
