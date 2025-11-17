import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:profit_calculator/models/cart_item.dart';
import '../providers/pos_riverpod_providers.dart';

/// ProviderObserver لمراقبة تحديثات Providers وتسجيلها في الـ console
class ProviderLogger extends ProviderObserver {
  @override
  void didUpdateProvider(
    ProviderBase<Object?> provider,
    Object? previousValue,
    Object? newValue,
    ProviderContainer container,
  ) {
    // نراقب فقط cartStateProvider في وضع Debug
    if (kDebugMode && provider == cartStateProvider) {
      final CartState? prevState = previousValue as CartState?;
      final CartState? newState = newValue as CartState?;

      debugPrint('''
🔔 Cart Provider Updated:
   - Previous cart length: ${prevState?.cart.length ?? 0}
   - New cart length: ${newState?.cart.length ?? 0}
   - Previous total: ${prevState?.totalAmount ?? 0}
   - New total: ${newState?.totalAmount ?? 0}
   - State changed: ${prevState?.hashCode != newState?.hashCode}
      ''');

      // إذا تغيرت القائمة، نطبع التفاصيل
      if ((prevState?.cart.length ?? 0) != (newState?.cart.length ?? 0)) {
        debugPrint('   📦 Cart items changed!');
        if (newState != null && newState.cart.isNotEmpty) {
          debugPrint('   Current items:');
          for (final CartItem item in newState.cart) {
            debugPrint('      - ${item.name} x${item.quantity}');
          }
        }
      }
    }
  }

  @override
  void didAddProvider(
    ProviderBase<Object?> provider,
    Object? value,
    ProviderContainer container,
  ) {
    if (kDebugMode && provider == cartStateProvider) {
      debugPrint('✅ Cart Provider initialized');
    }
  }

  @override
  void providerDidFail(
    ProviderBase<Object?> provider,
    Object error,
    StackTrace stackTrace,
    ProviderContainer container,
  ) {
    if (kDebugMode && provider == cartStateProvider) {
      debugPrint('❌ Cart Provider failed: $error');
    }
  }
}

