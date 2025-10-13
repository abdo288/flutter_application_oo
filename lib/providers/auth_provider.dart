import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import '../services/auth_service.dart';
import '../services/error_handler_service.dart';
import '../services/presence_service.dart';

/// مزود حالة المصادقة والأدوار
class AuthProvider with ChangeNotifier {
  AuthProvider() {
    _listenToAuthChanges();
  }

  final AuthService _authService = AuthService.instance;
  final PresenceService _presenceService = PresenceService.instance;

  AppUser? _appUser;
  fb_auth.User? _firebaseUser;
  bool _isLoading = true;
  String? _errorMessage;

  AppUser? get appUser => _appUser;
  fb_auth.User? get firebaseUser => _firebaseUser;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _firebaseUser != null;

  bool get isAdmin => _appUser?.isAdmin == true;
  bool get isSeller => _appUser?.isSeller == true;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setError(String? message) {
    _errorMessage = message;
    notifyListeners();
  }

  void _listenToAuthChanges() {
    _authService.authStateChanges().listen((fb_auth.User? user) async {
      _firebaseUser = user;
      if (user == null) {
        _appUser = null;
        // إيقاف جلسة الحضور عند تسجيل الخروج
        await _presenceService.goOffline();
        _setLoading(false);
        return;
      }
      _setLoading(true);
      try {
        _appUser = await _authService.getCurrentAppUser();
        _setError(null);

        // بدء جلسة الحضور عند تسجيل الدخول الناجح
        if (_appUser != null) {
          await _presenceService.goOnline(_appUser!.uid);
          // إرسال تحديث فوري للواجهة
          notifyListeners();
        }
      } on Exception catch (e, stackTrace) {
        await ErrorHandlerService.handleError(
          e,
          stackTrace: stackTrace.toString(),
          type: ErrorType.unknown,
          severity: ErrorSeverity.high,
          userAction: 'تحميل بيانات المستخدم في AuthProvider',
          context: <String, dynamic>{
            'operation': '_listenToAuthChanges',
            'provider': 'AuthProvider',
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
      _appUser = user;
      _setError(null);
    } on fb_auth.FirebaseAuthException catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.firebase,
        severity: ErrorSeverity.high,
        userAction: 'تسجيل الدخول في AuthProvider',
        context: <String, dynamic>{
          'operation': 'signIn',
          'provider': 'AuthProvider',
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
    // إرسال تحديث فوري للواجهة
    notifyListeners();
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
        userAction: 'إعادة تعيين كلمة المرور في AuthProvider',
        context: <String, dynamic>{
          'operation': 'resetPassword',
          'provider': 'AuthProvider',
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
