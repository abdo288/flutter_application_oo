import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/app_user.dart';
import '../repositories/unified_repository.dart';
import '../services/auth_service.dart';
import '../services/error_handler_service.dart';
import '../services/presence_service.dart';

/// Riverpod wrapper for AuthProvider
class AuthRiverpodNotifier extends StateNotifier<AuthState> {
  AuthRiverpodNotifier(this.ref) : super(const AuthState()) {
    _listenToAuthChanges();
  }

  final Ref ref;
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
            state = state.copyWith();
            // إيقاف جلسة الحضور عند تسجيل الخروج
            await _presenceService.goOffline();
            _setLoading(false);
            return;
          }
          _setLoading(true);
          try {
            final AppUser? appUser = await _authService.getCurrentAppUser();
            state = state.copyWith(appUser: appUser);

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
      });
    });
  }

  Future<void> signIn(String email, String password) async {
    _setLoading(true);
    try {
      final AppUser user =
          await _authService.signInWithEmail(email: email, password: password);
      state = state.copyWith(appUser: user);
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
    try {
      debugPrint('🚪 بدء عملية تسجيل الخروج...');

      // ✅ 1. إيقاف تشغيل جميع Streams قبل تسجيل الخروج (مع timeout)
      ref.read(userStreamsEnabledProvider.notifier).state = false;
      try {
        final UnifiedRepository repository = UnifiedRepository();
        await repository.disableStreams().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            debugPrint('⚠️ انتهت مهلة تعطيل Streams - متابعة تسجيل الخروج');
          },
        );
        debugPrint('🔒 تم تعطيل Streams قبل تسجيل الخروج');
      } catch (e) {
        debugPrint('⚠️ خطأ في تعطيل Streams (سيتم تجاهله): $e');
      }

      // ✅ 2. إيقاف جلسة الحضور بعد تعطيل Streams (مع timeout)
      try {
        await _presenceService.goOffline().timeout(
          const Duration(seconds: 2),
          onTimeout: () {
            debugPrint('⚠️ انتهت مهلة إيقاف جلسة الحضور - متابعة تسجيل الخروج');
          },
        );
      } catch (e) {
        debugPrint('⚠️ خطأ في إيقاف جلسة الحضور (سيتم تجاهله): $e');
      }

      // ✅ 3. تسجيل الخروج من Firebase (هذه العملية الأهم)
      try {
        await _authService.signOut().timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            debugPrint('⚠️ انتهت مهلة تسجيل الخروج من Firebase');
          },
        );
      } catch (e) {
        debugPrint('⚠️ خطأ في تسجيل الخروج من Firebase: $e');
        // نواصل حتى لو فشل تسجيل الخروج من Firebase
      }

      // ✅ 4. إعادة تعيين حالة المصادقة فوراً
      state = const AuthState();
      debugPrint('✅ تم إعادة تعيين حالة المصادقة');

      // ✅ 5. إعادة تفعيل المفتاح استعداداً لعملية الدخول التالية
      ref.read(userStreamsEnabledProvider.notifier).state = true;
      final UnifiedRepository repository2 = UnifiedRepository();
      repository2.enableStreams();
      debugPrint('🔓 تم إعادة تفعيل Streams');

      debugPrint('✅ تم تسجيل الخروج بنجاح');
    } catch (e) {
      debugPrint('❌ خطأ في تسجيل الخروج: $e');
      // إعادة تعيين الحالة حتى لو حدث خطأ
      state = const AuthState();
      ref.read(userStreamsEnabledProvider.notifier).state = true;
      rethrow;
    }
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

// ========== Providers ==========

/// Provider الرئيسي لحالة المصادقة
final AutoDisposeStateNotifierProvider<AuthRiverpodNotifier, AuthState>
    authStateProvider =
    StateNotifierProvider.autoDispose<AuthRiverpodNotifier, AuthState>(
  AuthRiverpodNotifier.new,
);

/// Provider للتحقق من حالة المصادقة
final AutoDisposeProvider<bool> isAuthenticatedProvider =
    Provider.autoDispose<bool>(
  (AutoDisposeProviderRef<bool> ref) {
    final AuthState state = ref.watch(authStateProvider);
    return state.isAuthenticated;
  },
  dependencies: <ProviderOrFamily>[authStateProvider],
);

/// Provider للتحقق من حالة التحميل
final AutoDisposeProvider<bool> authLoadingProvider =
    Provider.autoDispose<bool>(
  (AutoDisposeProviderRef<bool> ref) {
    final AuthState state = ref.watch(authStateProvider);
    return state.isLoading;
  },
  dependencies: <ProviderOrFamily>[authStateProvider],
);

/// Provider للتحقق من صلاحيات المدير
final AutoDisposeProvider<bool> isAdminProvider = Provider.autoDispose<bool>(
  (AutoDisposeProviderRef<bool> ref) {
    final AuthState state = ref.watch(authStateProvider);
    return state.isAdmin;
  },
  dependencies: <ProviderOrFamily>[authStateProvider],
);

/// Provider للتحقق من صلاحيات البائع
final AutoDisposeProvider<bool> isSellerProvider = Provider.autoDispose<bool>(
  (AutoDisposeProviderRef<bool> ref) {
    final AuthState state = ref.watch(authStateProvider);
    return state.isSeller;
  },
  dependencies: <ProviderOrFamily>[authStateProvider],
);

/// Provider لبيانات المستخدم
final AutoDisposeProvider<AppUser?> appUserProvider =
    Provider.autoDispose<AppUser?>(
  (AutoDisposeProviderRef<AppUser?> ref) {
    final AuthState state = ref.watch(authStateProvider);
    return state.appUser;
  },
  dependencies: <ProviderOrFamily>[authStateProvider],
);

/// Provider لرسالة الخطأ
final AutoDisposeProvider<String?> authErrorProvider =
    Provider.autoDispose<String?>(
  (AutoDisposeProviderRef<String?> ref) {
    final AuthState state = ref.watch(authStateProvider);
    return state.errorMessage;
  },
  dependencies: <ProviderOrFamily>[authStateProvider],
);

/// مفتاح الأمان - يتحكم في تفعيل/تعطيل Streams قبل وبعد تسجيل الخروج
final StateProvider<bool> userStreamsEnabledProvider =
    StateProvider<bool>((StateProviderRef<bool> ref) => true);
