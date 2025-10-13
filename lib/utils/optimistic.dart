import 'package:flutter/foundation.dart';

typedef ApplyRemote<T> = Future<T> Function();
typedef Rollback = Future<void> Function();

/// A small utility to standardize Optimistic UI flows across the app.
/// It immediately applies local changes, then executes the remote action.
/// If the remote action fails, it rolls back the local changes.
Future<R> optimistic<R>({
  required VoidCallback applyLocal,
  required ApplyRemote<R> applyRemote,
  required Rollback rollback,
  VoidCallback? onFinally,
}) async {
  try {
    applyLocal();
    return await applyRemote();
  } catch (e) {
    try {
      await rollback();
    } catch (rollbackError) {
      // تسجيل خطأ التراجع ولكن لا نريد أن يفشل التطبيق
      debugPrint('خطأ في التراجع: $rollbackError');
    }
    rethrow;
  } finally {
    try {
      onFinally?.call();
    } catch (finallyError) {
      // تسجيل خطأ finally ولكن لا نريد أن يفشل التطبيق
      debugPrint('خطأ في onFinally: $finallyError');
    }
  }
}
