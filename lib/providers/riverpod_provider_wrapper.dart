import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';
import 'stream_app_provider.dart';

/// Riverpod provider that wraps the existing StreamAppProvider
final Provider<StreamAppProvider> streamAppProvider = Provider<StreamAppProvider>((ProviderRef<StreamAppProvider> ref) {
  // This will be provided by the main app through ProviderScope
  throw UnimplementedError(
      'StreamAppProvider must be provided by the main app');
});

/// Riverpod provider for accessing the existing Provider context
final Provider<BuildContext> providerContextProvider = Provider<BuildContext>((ProviderRef<BuildContext> ref) {
  throw UnimplementedError('BuildContext must be provided by the main app');
});

/// Riverpod wrapper for existing Provider services
class RiverpodProviderWrapper {
  static Widget wrapWithRiverpod({
    required Widget child,
    required StreamAppProvider appProvider,
    required BuildContext context,
  }) => ProviderScope(
      overrides: [
        streamAppProvider.overrideWithValue(appProvider),
        providerContextProvider.overrideWithValue(context),
      ],
      child: child,
    );
}
