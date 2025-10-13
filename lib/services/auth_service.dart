import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter/foundation.dart';

import '../models/app_user.dart';
import 'error_handler_service.dart';

/// خدمة إدارة المستخدمين وتسجيل الدخول
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// المرجع لمجموعة المستخدمين
  CollectionReference<Map<String, dynamic>> get _usersCol =>
      _db.collection('users');

  /// المستخدم الحالي إن وجد
  fb_auth.User? get currentFirebaseUser => _auth.currentUser;

  /// بث حالة المصادقة
  Stream<fb_auth.User?> authStateChanges() => _auth.authStateChanges();

  /// تسجيل الدخول بالبريد وكلمة المرور
  Future<AppUser> signInWithEmail(
      {required String email, required String password}) async {
    try {
      final fb_auth.UserCredential cred = await _auth
          .signInWithEmailAndPassword(email: email.trim(), password: password);
      final String uid = cred.user!.uid;

      final DocumentSnapshot<Map<String, dynamic>> doc =
          await _usersCol.doc(uid).get();
      if (!doc.exists) {
        // إنشاء سجل مستخدم افتراضي كبائع إن لم يوجد
        final AppUser appUser = AppUser(
          uid: uid,
          email: cred.user!.email ?? email,
          displayName: cred.user!.displayName,
          role: UserRole.seller,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
        await _usersCol.doc(uid).set(<String, dynamic>{
          'email': appUser.email,
          'displayName': appUser.displayName,
          'role': userRoleToString(appUser.role),
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        return appUser;
      }
      return AppUser.fromDoc(doc);
    } on fb_auth.FirebaseAuthException catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.firebase,
        severity: ErrorSeverity.high,
        userAction: 'تسجيل الدخول في AuthService',
        context: <String, dynamic>{
          'operation': 'signInWithEmail',
          'service': 'AuthService',
          'email': email,
          'errorCode': e.code,
        },
      );
      debugPrint('خطأ في تسجيل الدخول: ${e.code}');
      rethrow;
    }
  }

  /// تسجيل الخروج
  Future<void> signOut() => _auth.signOut();

  /// إعادة تعيين كلمة المرور
  Future<void> resetPassword({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email.trim());
      debugPrint('تم إرسال رابط إعادة تعيين كلمة المرور إلى: $email');
    } on fb_auth.FirebaseAuthException catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.firebase,
        userAction: 'إعادة تعيين كلمة المرور في AuthService',
        context: <String, dynamic>{
          'operation': 'resetPassword',
          'service': 'AuthService',
          'email': email,
          'errorCode': e.code,
        },
      );
      debugPrint('خطأ في إعادة تعيين كلمة المرور: ${e.code}');
      rethrow;
    }
  }

  /// إنشاء مستخدم جديد مع دور محدد (للاستخدام من قبل المدير)
  Future<void> createUserWithRole({
    required String email,
    required String password,
    required UserRole role,
    String? displayName,
  }) async {
    // ملاحظة: إنشاء الحسابات عادة من لوحة مدير خارج التطبيق أو عبر Cloud Functions.
    // هنا خيار مبسط يعمل فقط عندما يكون المدير مسجلاً على نفس الجهاز.
    final fb_auth.User? admin = _auth.currentUser;
    if (admin == null) {
      throw StateError('لا يوجد مستخدم مدير مسجل حالياً');
    }
    // استخدام REST/Custom Token أفضل، لكن لتبسيط سنستخدم createUserWithEmailAndPassword ثم نعيد تسجيل المدير.
    final String? adminEmail = admin.email;
    const String adminPasswordPlaceholder = '__relogin_required__';

    try {
      // إنشاء جلسة ثانوية مؤقتة غير مدعومة مباشرة في SDK، لذا هذا القسم توضيحي.
      // بديل عملي: أنشئ الوثيقة يدوياً وافصل إنشاء الحساب الفعلي عن التطبيق.
      await _usersCol
          .doc('pending_${email.toLowerCase()}')
          .set(<String, dynamic>{
        'email': email,
        'displayName': displayName,
        'role': userRoleToString(role),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on Exception catch (e, stackTrace) {
      await ErrorHandlerService.handleError(
        e,
        stackTrace: stackTrace.toString(),
        type: ErrorType.unknown,
        severity: ErrorSeverity.high,
        userAction: 'إنشاء مستخدم جديد في AuthService',
        context: <String, dynamic>{
          'operation': 'createUserWithRole',
          'service': 'AuthService',
          'email': email,
          'role': userRoleToString(role),
        },
      );
      debugPrint('خطأ في إنشاء المستخدم: $e');
      rethrow;
    } finally {
      // إعادة المدير للجلسة الأصلية إن لزم (لا تغيير فعلي هنا)
      if (adminEmail != null && adminPasswordPlaceholder == 'no-op') {
        await _auth.signInWithEmailAndPassword(
            email: adminEmail, password: adminPasswordPlaceholder);
      }
    }
  }

  /// جلب نموذج المستخدم الحالي مع الدور
  Future<AppUser?> getCurrentAppUser() async {
    final fb_auth.User? u = _auth.currentUser;
    if (u == null) return null;
    final DocumentSnapshot<Map<String, dynamic>> doc =
        await _usersCol.doc(u.uid).get();
    if (!doc.exists) return null;
    return AppUser.fromDoc(doc);
  }

  /// بث نموذج المستخدم مع التحديثات
  Stream<AppUser?> appUserStream() =>
      authStateChanges().asyncExpand((fb_auth.User? u) async* {
        if (u == null) {
          yield null;
        } else {
          yield* _usersCol.doc(u.uid).snapshots().map(
              (DocumentSnapshot<Map<String, dynamic>> snap) =>
                  snap.exists ? AppUser.fromDoc(snap) : null);
        }
      });

  /// بث قائمة جميع المستخدمين (لوحة المدير)
  Stream<List<AppUser>> usersStream() =>
      _usersCol.orderBy('createdAt', descending: true).snapshots().map(
            (QuerySnapshot<Map<String, dynamic>> query) => query.docs
                .where((QueryDocumentSnapshot<Map<String, dynamic>> d) =>
                    d.data().containsKey('email'))
                .map(AppUser.fromDoc)
                .toList(),
          );

  /// تحديث دور المستخدم
  Future<void> setUserRole(
      {required String uid, required UserRole role}) async {
    await _usersCol.doc(uid).set(
      <String, dynamic>{
        'role': userRoleToString(role),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  /// إنشاء/تحديث وثيقة مستخدم يدوياً (عند توفر UID من Authentication)
  Future<void> upsertUserDoc({
    required String uid,
    required String email,
    String? displayName,
    required UserRole role,
  }) async {
    await _usersCol.doc(uid).set(
      <String, dynamic>{
        'email': email,
        'displayName': displayName,
        'role': userRoleToString(role),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
