import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:profit_calculator/firebase_options.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Test setup utility for Firebase initialization
class TestSetup {
  static bool _isInitialized = false;

  /// Initialize Firebase for testing
  static Future<void> initializeFirebase() async {
    if (_isInitialized) return;

    TestWidgetsFlutterBinding.ensureInitialized();
    // Mock SharedPreferences to avoid MissingPluginException in unit tests
    SharedPreferences.setMockInitialValues(<String, Object>{});

    // Mock path_provider calls to avoid MissingPluginException in tests
    const MethodChannel pathProviderChannel = MethodChannel('plugins.flutter.io/path_provider');
    final Directory tmpRoot = await Directory.systemTemp.createTemp('pc_tests_');
    final Directory appDocs = Directory('${tmpRoot.path}/app_docs')..createSync(recursive: true);
    final Directory appSupport = Directory('${tmpRoot.path}/app_support')..createSync(recursive: true);
    final Directory tempDir = Directory('${tmpRoot.path}/temp')..createSync(recursive: true);

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      pathProviderChannel,
      (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'getApplicationDocumentsDirectory':
            return appDocs.path;
          case 'getApplicationSupportDirectory':
            return appSupport.path;
          case 'getTemporaryDirectory':
            return tempDir.path;
          case 'getDownloadsDirectory':
            return appDocs.path; // fallback
          default:
            return appDocs.path;
        }
      },
    );
    
    try {
      // Check if Firebase is already initialized
      try {
        Firebase.app();
        _isInitialized = true;
        return;
      } catch (e) {
        // Firebase not initialized, continue with initialization
      }

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      _isInitialized = true;
    } catch (e) {
      // If Firebase is already initialized, that's fine
      if (e.toString().contains('already been initialized') || 
          e.toString().contains('PlatformException')) {
        _isInitialized = true;
      } else {
        // For testing purposes, we'll continue even if Firebase fails
        // This allows tests to run without actual Firebase connection
        print('Warning: Firebase initialization failed in test environment: $e');
        _isInitialized = true;
      }
    }
  }

  /// Clean up after tests
  static Future<void> cleanup() async {
    // Add any cleanup logic here if needed
    _isInitialized = false;
  }
}
