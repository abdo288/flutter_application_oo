import 'package:flutter_test/flutter_test.dart';
import 'package:profit_calculator/services/enhanced_security_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('EnhancedSecurityService Tests', () {
    setUp(() async {
      // إعداد SharedPreferences للاختبار
      SharedPreferences.setMockInitialValues(<String, Object>{});
    });

    tearDown(() async {
      // تنظيف بعد كل اختبار
      EnhancedSecurityService.clearSecureMemory();
    });

    test('Should initialize security service correctly', () async {
      // Act & Assert
      expect(EnhancedSecurityService.initialize, returnsNormally);
    });

    test('Should encrypt and decrypt text correctly', () async {
      // Arrange
      await EnhancedSecurityService.initialize();
      const String plainText = 'هذا نص سري للاختبار';

      // Act
      final String encrypted =
          await EnhancedSecurityService.encryptWithIntegrity(plainText);
      final String? decrypted =
          await EnhancedSecurityService.decryptWithIntegrity(encrypted);

      // Assert
      expect(encrypted, isNotEmpty);
      expect(encrypted, isNot(equals(plainText)));
      expect(decrypted, equals(plainText));
    });

    test('Should fail decryption with tampered data', () async {
      // Arrange
      await EnhancedSecurityService.initialize();
      const String plainText = 'نص للاختبار';

      // Act
      final String encrypted =
          await EnhancedSecurityService.encryptWithIntegrity(plainText);
      final String tamperedEncrypted =
          '${encrypted.substring(0, encrypted.length - 5)}XXXXX';
      final String? decrypted =
          await EnhancedSecurityService.decryptWithIntegrity(tamperedEncrypted);

      // Assert
      expect(decrypted, isNull);
    });

    test('Should store and retrieve secure data', () async {
      // Arrange
      await EnhancedSecurityService.initialize();
      const String key = 'test_key';
      const String value = 'قيمة آمنة للاختبار';

      // Act
      await EnhancedSecurityService.storeSecureData(key, value);
      final String? retrieved =
          await EnhancedSecurityService.retrieveSecureData(key);

      // Assert
      expect(retrieved, equals(value));
    });

    test('Should return null for non-existent secure data', () async {
      // Arrange
      await EnhancedSecurityService.initialize();

      // Act
      final String? retrieved =
          await EnhancedSecurityService.retrieveSecureData('non_existent_key');

      // Assert
      expect(retrieved, isNull);
    });

    test('Should create secure hash consistently', () async {
      // Arrange
      await EnhancedSecurityService.initialize();
      const String data = 'test data';

      // Act
      final String hash1 = EnhancedSecurityService.createSecureHash(data);
      final String hash2 = EnhancedSecurityService.createSecureHash(data);

      // Assert
      expect(hash1, isNotEmpty);
      expect(hash1, equals(hash2));
      expect(hash1.length, equals(64)); // SHA-256 hex length
    });

    test('Should check password strength correctly', () {
      // Test weak password
      final PasswordStrength weak =
          EnhancedSecurityService.checkPasswordStrength('123');
      expect(weak.level, equals(PasswordStrengthLevel.weak));
      expect(weak.score, lessThan(3));

      // Test medium password
      final PasswordStrength medium =
          EnhancedSecurityService.checkPasswordStrength('Password123');
      expect(medium.level, equals(PasswordStrengthLevel.medium));

      // Test strong password
      final PasswordStrength strong =
          EnhancedSecurityService.checkPasswordStrength('StrongPass123!');
      expect(strong.level.index,
          greaterThanOrEqualTo(PasswordStrengthLevel.strong.index));
      expect(strong.score, greaterThan(4));
    });

    test('Should generate custom passwords correctly', () {
      // Test default generation
      final String password1 = EnhancedSecurityService.generateCustomPassword();
      expect(password1.length, equals(16));

      // Test custom length
      final String password2 =
          EnhancedSecurityService.generateCustomPassword(length: 20);
      expect(password2.length, equals(20));

      // Test numbers only
      final String password3 = EnhancedSecurityService.generateCustomPassword(
        length: 10,
        includeSymbols: false,
        includeUppercase: false,
        includeLowercase: false,
      );
      expect(password3.length, equals(10));
      expect(RegExp(r'^[0-9]+$').hasMatch(password3), isTrue);
    });

    test('Should throw error for invalid password generation params', () {
      // Act & Assert
      expect(
        () => EnhancedSecurityService.generateCustomPassword(
          includeSymbols: false,
          includeNumbers: false,
          includeUppercase: false,
          includeLowercase: false,
        ),
        throwsArgumentError,
      );
    });

    test('Should generate security report correctly', () async {
      // Arrange
      await EnhancedSecurityService.initialize();
      await EnhancedSecurityService.storeSecureData('test1', 'value1');
      await EnhancedSecurityService.storeSecureData('test2', 'value2');

      // Act
      final SecurityReport report =
          await EnhancedSecurityService.getSecurityReport();

      // Assert
      expect(report.encryptionEnabled, isTrue);
      expect(report.totalSecureItems, equals(2));
      expect(report.lastSecurityCheck, isA<DateTime>());
      expect(report.debugMode, isTrue); // في وضع الاختبار
    });

    test('Should clear secure memory correctly', () {
      // Act & Assert
      expect(EnhancedSecurityService.clearSecureMemory, returnsNormally);
    });

    test('Should handle encryption errors gracefully', () async {
      // Test with invalid data - should return null, not throw exception
      final String? result = await EnhancedSecurityService.decryptWithIntegrity(
          'invalid_base64!@#');
      expect(result, isNull);
    });

    test('Password strength checks should be comprehensive', () {
      final List<(String, PasswordStrengthLevel)> testCases =
          <(String, PasswordStrengthLevel)>[
        ('', PasswordStrengthLevel.weak),
        ('123', PasswordStrengthLevel.weak),
        ('password', PasswordStrengthLevel.weak),
        ('Password1', PasswordStrengthLevel.medium),
        ('StrongPass123!', PasswordStrengthLevel.strong),
        ('VeryStr0ng!P@ssw0rd#2024', PasswordStrengthLevel.veryStrong),
      ];

      for (final (String, PasswordStrengthLevel) testCase in testCases) {
        final PasswordStrength result =
            EnhancedSecurityService.checkPasswordStrength(testCase.$1);
        expect(
          result.level.index >= testCase.$2.index,
          isTrue,
          reason: 'Password "${testCase.$1}" should be at least ${testCase.$2}',
        );
      }
    });

    test('Security report should contain valid data', () async {
      // Arrange
      await EnhancedSecurityService.initialize();

      // Act
      final SecurityReport report =
          await EnhancedSecurityService.getSecurityReport();
      final Map<String, dynamic> reportMap = report.toMap();

      // Assert
      expect(reportMap, containsPair('encryptionEnabled', isA<bool>()));
      expect(reportMap, containsPair('totalSecureItems', isA<int>()));
      expect(reportMap, containsPair('lastSecurityCheck', isA<String>()));
      expect(reportMap, containsPair('integrityVerified', isA<bool>()));
      expect(reportMap, containsPair('debugMode', isA<bool>()));
      expect(reportMap, containsPair('platform', isA<String>()));
    });
  });
}
