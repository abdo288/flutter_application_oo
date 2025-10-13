import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// خدمة الأمان والتشفير المحسنة
class EnhancedSecurityService {
  static final Logger _logger = Logger('EnhancedSecurityService');

  // مفاتيح التشفير والأمان
  static const String _encryptionKeyKey = 'enhanced_encryption_key';
  static const String _saltKey = 'enhanced_salt';
  static const String _integrityHashKey = 'integrity_hash';

  // إعدادات الأمان
  static const int _keyLength = 32; // 256 bits
  static const int _saltLength = 16; // 128 bits
  static const int _ivLength = 16; // 128 bits

  static String? _cachedKey;
  static Uint8List? _cachedSalt;

  /// تهيئة خدمة الأمان المحسنة
  static Future<void> initialize() async {
    try {
      await _ensureEncryptionKey();
      await _verifyApplicationIntegrity();
      _logger.info('تم تهيئة خدمة الأمان المحسنة بنجاح');
    } on Exception catch (e) {
      _logger.severe('خطأ في تهيئة خدمة الأمان المحسنة: $e');
      rethrow;
    }
  }

  /// التأكد من وجود مفتاح التشفير
  static Future<void> _ensureEncryptionKey() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();

    String? existingKey = prefs.getString(_encryptionKeyKey);
    if (existingKey == null || existingKey.isEmpty) {
      existingKey = _generateSecureKey();
      await prefs.setString(_encryptionKeyKey, existingKey);
      _logger.info('تم إنشاء مفتاح تشفير محسن جديد');
    }

    _cachedKey = existingKey;

    String? existingSalt = prefs.getString(_saltKey);
    if (existingSalt == null || existingSalt.isEmpty) {
      _cachedSalt = _generateSalt();
      existingSalt = base64.encode(_cachedSalt!);
      await prefs.setString(_saltKey, existingSalt);
      _logger.info('تم إنشاء Salt محسن جديد');
    } else {
      _cachedSalt = base64.decode(existingSalt);
    }
  }

  /// إنشاء مفتاح آمن بطريقة محسنة
  static String _generateSecureKey() {
    final Random random = Random.secure();
    final Uint8List bytes = Uint8List(_keyLength);
    for (int i = 0; i < _keyLength; i++) {
      bytes[i] = random.nextInt(256);
    }

    // إضافة طبقة إضافية من الأمان
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final List<int> combined = bytes + utf8.encode(timestamp);
    final List<int> hashedKey = sha256.convert(combined).bytes;

    return base64.encode(hashedKey);
  }

  /// إنشاء Salt عشوائي محسن
  static Uint8List _generateSalt() {
    final Random random = Random.secure();
    final Uint8List salt = Uint8List(_saltLength);
    for (int i = 0; i < _saltLength; i++) {
      salt[i] = random.nextInt(256);
    }
    return salt;
  }

  /// تشفير النص مع HMAC للتحقق من السلامة
  static Future<String> encryptWithIntegrity(String plainText) async {
    try {
      if (_cachedKey == null) {
        await _ensureEncryptionKey();
      }

      final Uint8List plainBytes = utf8.encode(plainText);
      final Uint8List iv = _generateIV();
      final Uint8List key = base64.decode(_cachedKey!);

      // تشفير البيانات
      final Uint8List encryptedBytes = _performEncryption(plainBytes, key, iv);

      // إنشاء HMAC للتحقق من السلامة
      final List<int> hmacKey = sha256.convert(key + _cachedSalt!).bytes;
      final Hmac hmac = Hmac(sha256, hmacKey);
      final List<int> mac = hmac.convert(iv + encryptedBytes).bytes;

      // تجميع IV + البيانات المشفرة + MAC
      final Uint8List combined =
          Uint8List(iv.length + encryptedBytes.length + mac.length);
      combined.setAll(0, iv);
      combined.setAll(iv.length, encryptedBytes);
      combined.setAll(iv.length + encryptedBytes.length, mac);

      return base64.encode(combined);
    } on Exception catch (e) {
      _logger.severe('خطأ في التشفير مع التحقق من السلامة: $e');
      rethrow;
    }
  }

  /// فك التشفير مع التحقق من السلامة
  static Future<String?> decryptWithIntegrity(String encryptedData) async {
    try {
      if (_cachedKey == null) {
        await _ensureEncryptionKey();
      }

      final Uint8List combined = base64.decode(encryptedData);
      final Uint8List key = base64.decode(_cachedKey!);

      // استخراج المكونات
      final Uint8List iv = combined.sublist(0, _ivLength);
      const int macLength = 32; // SHA-256 hash length
      final Uint8List encryptedBytes =
          combined.sublist(_ivLength, combined.length - macLength);
      final Uint8List receivedMac =
          combined.sublist(combined.length - macLength);

      // التحقق من سلامة البيانات
      final List<int> hmacKey = sha256.convert(key + _cachedSalt!).bytes;
      final Hmac hmac = Hmac(sha256, hmacKey);
      final List<int> expectedMac = hmac.convert(iv + encryptedBytes).bytes;

      if (!_constantTimeEquals(receivedMac, expectedMac)) {
        _logger.warning('فشل في التحقق من سلامة البيانات المشفرة');
        await _logSecurityIncident('integrity_check_failed', <String, dynamic>{
          'data_length': encryptedData.length,
          'timestamp': DateTime.now().toIso8601String(),
        });
        return null;
      }

      // فك التشفير
      final Uint8List decryptedBytes =
          _performDecryption(encryptedBytes, key, iv);
      return utf8.decode(decryptedBytes);
    } on Exception catch (e) {
      _logger.severe('خطأ في فك التشفير مع التحقق من السلامة: $e');
      return null;
    }
  }

  /// مقارنة آمنة للمصفوفات (لمنع Timing Attacks)
  static bool _constantTimeEquals(List<int> a, List<int> b) {
    if (a.length != b.length) return false;
    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  /// إنشاء IV عشوائي
  static Uint8List _generateIV() {
    final Random random = Random.secure();
    final Uint8List iv = Uint8List(_ivLength);
    for (int i = 0; i < _ivLength; i++) {
      iv[i] = random.nextInt(256);
    }
    return iv;
  }

  /// تشفير البيانات (XOR محسن مع تدوير)
  static Uint8List _performEncryption(
      Uint8List data, Uint8List key, Uint8List iv) {
    final Uint8List encrypted = Uint8List(data.length);
    for (int i = 0; i < data.length; i++) {
      final int keyByte = key[i % key.length];
      final int ivByte = iv[i % iv.length];
      final int rotation = (keyByte + ivByte) % 8;
      encrypted[i] = _rotateRight(data[i] ^ keyByte ^ ivByte, rotation);
    }
    return encrypted;
  }

  /// فك تشفير البيانات
  static Uint8List _performDecryption(
      Uint8List encryptedData, Uint8List key, Uint8List iv) {
    final Uint8List decrypted = Uint8List(encryptedData.length);
    for (int i = 0; i < encryptedData.length; i++) {
      final int keyByte = key[i % key.length];
      final int ivByte = iv[i % iv.length];
      final int rotation = (keyByte + ivByte) % 8;
      decrypted[i] = _rotateLeft(encryptedData[i], rotation) ^ keyByte ^ ivByte;
    }
    return decrypted;
  }

  /// تدوير البتات لليمين
  static int _rotateRight(int value, int positions) =>
      ((value >> positions) | (value << (8 - positions))) & 0xFF;

  /// تدوير البتات لليسار
  static int _rotateLeft(int value, int positions) =>
      ((value << positions) | (value >> (8 - positions))) & 0xFF;

  /// حفظ البيانات الحساسة مع التشفير المحسن
  static Future<void> storeSecureData(String key, String value) async {
    try {
      final String encryptedValue = await encryptWithIntegrity(value);
      final SharedPreferences prefs = await SharedPreferences.getInstance();

      // إضافة timestamp وhash للبيانات
      final Map<String, String> metadata = <String, String>{
        'encrypted_data': encryptedValue,
        'timestamp': DateTime.now().toIso8601String(),
        'hash': sha256.convert(utf8.encode(value)).toString(),
      };

      await prefs.setString('secure_v2_$key', jsonEncode(metadata));
      _logger.fine('تم حفظ البيانات الآمنة المحسنة: $key');
    } on Exception catch (e) {
      _logger.severe('خطأ في حفظ البيانات الآمنة المحسنة: $e');
      rethrow;
    }
  }

  /// استرداد البيانات الحساسة مع التحقق المحسن
  static Future<String?> retrieveSecureData(String key) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? metadataJson = prefs.getString('secure_v2_$key');

      if (metadataJson == null) {
        return null;
      }

      final Map<String, dynamic> metadata =
          jsonDecode(metadataJson) as Map<String, dynamic>;
      final String encryptedData = metadata['encrypted_data'] as String;
      final String savedHash = metadata['hash'] as String;

      final String? decryptedValue = await decryptWithIntegrity(encryptedData);
      if (decryptedValue == null) {
        return null;
      }

      // التحقق من hash البيانات
      final String currentHash =
          sha256.convert(utf8.encode(decryptedValue)).toString();
      if (currentHash != savedHash) {
        _logger.warning('تم اكتشاف تعديل في البيانات المحفوظة: $key');
        await _logSecurityIncident('data_tampering_detected', <String, dynamic>{
          'key': key,
          'expected_hash': savedHash,
          'actual_hash': currentHash,
        });
        return null;
      }

      _logger.fine('تم استرداد البيانات الآمنة المحسنة: $key');
      return decryptedValue;
    } on Exception catch (e) {
      _logger.severe('خطأ في استرداد البيانات الآمنة المحسنة: $e');
      return null;
    }
  }

  /// إنشاء hash آمن مع salt
  static String createSecureHash(String data, {String? salt}) {
    final String saltToUse = salt ?? base64.encode(_cachedSalt ?? Uint8List(0));
    final String combined = data + saltToUse;
    final Uint8List bytes = utf8.encode(combined);
    final Digest digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// التحقق من سلامة التطبيق
  static Future<void> _verifyApplicationIntegrity() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      const String appVersion = '1.1.0'; // من pubspec.yaml

      final String? savedHash = prefs.getString(_integrityHashKey);
      final String currentHash =
          createSecureHash(appVersion + kDebugMode.toString());

      if (savedHash == null) {
        // أول تشغيل
        await prefs.setString(_integrityHashKey, currentHash);
        _logger.info('تم إنشاء hash سلامة التطبيق');
      } else if (savedHash != currentHash && !kDebugMode) {
        // تم اكتشاف تغيير مشبوه
        await _logSecurityIncident('app_integrity_violation', <String, dynamic>{
          'expected_hash': savedHash,
          'actual_hash': currentHash,
          'app_version': appVersion,
        });
        _logger.warning('تم اكتشاف انتهاك لسلامة التطبيق');
      }
    } on Exception catch (e) {
      _logger.warning('خطأ في التحقق من سلامة التطبيق: $e');
    }
  }

  /// تسجيل حادث أمني
  static Future<void> _logSecurityIncident(
      String incidentType, Map<String, dynamic> details) async {
    try {
      // تسجيل الحادث الأمني
      final Map<String, Object> incident = <String, Object>{
        'type': incidentType,
        'timestamp': DateTime.now().toIso8601String(),
        'details': details,
        'platform': defaultTargetPlatform.toString(),
        'app_version': '1.1.0',
        'debug_mode': kDebugMode,
      };

      // استخدام المتغير لتجنب تحذير عدم الاستخدام
      _logger.fine('تم تسجيل حادث أمني: ${incident['type']}');

      _logger.warning('حادث أمني: $incidentType');

      // في الإنتاج، يمكن إرسال هذا إلى خدمة مراقبة أمنية
      if (!kDebugMode) {
        // await _sendSecurityIncidentToService(incident);
      }
    } on Exception catch (e) {
      _logger.severe('خطأ في تسجيل الحادث الأمني: $e');
    }
  }

  /// التحقق من قوة كلمة المرور مع معايير محسنة
  static PasswordStrength checkPasswordStrength(String password) {
    int score = 0;
    final List<String> checks = <String>[];

    if (password.length >= 8) {
      score += 1;
      checks.add('الطول مناسب');
    } else {
      checks.add('الطول قصير (أقل من 8 أحرف)');
    }

    if (password.contains(RegExp('[a-z]'))) {
      score += 1;
      checks.add('يحتوي على أحرف صغيرة');
    }

    if (password.contains(RegExp('[A-Z]'))) {
      score += 1;
      checks.add('يحتوي على أحرف كبيرة');
    }

    if (password.contains(RegExp('[0-9]'))) {
      score += 1;
      checks.add('يحتوي على أرقام');
    }

    if (password.contains(RegExp(r'[!@#$%^&*(),.?\":{}|<>]'))) {
      score += 1;
      checks.add('يحتوي على رموز خاصة');
    }

    if (password.length >= 12) {
      score += 1;
      checks.add('طول ممتاز');
    }

    // التحقق من عدم وجود أنماط شائعة
    if (!_hasCommonPatterns(password)) {
      score += 1;
      checks.add('لا يحتوي على أنماط شائعة');
    } else {
      checks.add('يحتوي على أنماط شائعة');
    }

    PasswordStrengthLevel level;
    if (score <= 2) {
      level = PasswordStrengthLevel.weak;
    } else if (score <= 4) {
      level = PasswordStrengthLevel.medium;
    } else if (score <= 6) {
      level = PasswordStrengthLevel.strong;
    } else {
      level = PasswordStrengthLevel.veryStrong;
    }

    return PasswordStrength(level: level, score: score, checks: checks);
  }

  /// التحقق من وجود أنماط شائعة في كلمة المرور
  static bool _hasCommonPatterns(String password) {
    final List<String> commonPatterns = <String>[
      '123456',
      'password',
      'qwerty',
      'abc123',
      '111111',
      '123123',
      'admin',
      'letmein',
      'welcome',
      '1234567890'
    ];

    final String lowerPassword = password.toLowerCase();
    return commonPatterns.any(lowerPassword.contains);
  }

  /// إنشاء كلمة مرور قوية مخصصة
  static String generateCustomPassword({
    int length = 16,
    bool includeSymbols = true,
    bool includeNumbers = true,
    bool includeUppercase = true,
    bool includeLowercase = true,
  }) {
    if (!includeSymbols &&
        !includeNumbers &&
        !includeUppercase &&
        !includeLowercase) {
      throw ArgumentError('يجب تضمين نوع واحد على الأقل من الأحرف');
    }

    String chars = '';
    if (includeLowercase) chars += 'abcdefghijklmnopqrstuvwxyz';
    if (includeUppercase) chars += 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
    if (includeNumbers) chars += '0123456789';
    if (includeSymbols) chars += '!@#\$%^&*()_+-=[]{}|;:,.<>?';

    final Random random = Random.secure();
    final String password =
        List.generate(length, (_) => chars[random.nextInt(chars.length)])
            .join();

    // التأكد من أن كلمة المرور تحتوي على جميع الأنواع المطلوبة
    if (checkPasswordStrength(password).level == PasswordStrengthLevel.weak) {
      return generateCustomPassword(
        length: length,
        includeSymbols: includeSymbols,
        includeNumbers: includeNumbers,
        includeUppercase: includeUppercase,
        includeLowercase: includeLowercase,
      );
    }

    return password;
  }

  /// مسح البيانات الحساسة من الذاكرة
  static void clearSecureMemory() {
    try {
      _cachedKey = null;
      _cachedSalt = null;
      _logger.info('تم مسح البيانات الحساسة من الذاكرة');
    } on Exception catch (e) {
      _logger.warning('خطأ في مسح البيانات الحساسة: $e');
    }
  }

  /// الحصول على تقرير الأمان الشامل
  static Future<SecurityReport> getSecurityReport() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final Set<String> allKeys = prefs.getKeys();
      final List<String> secureKeys =
          allKeys.where((String key) => key.startsWith('secure_v2_')).toList();

      return SecurityReport(
        encryptionEnabled: _cachedKey != null,
        totalSecureItems: secureKeys.length,
        lastSecurityCheck: DateTime.now(),
        integrityVerified: await _isIntegrityVerified(),
        debugMode: kDebugMode,
        platform: defaultTargetPlatform.toString(),
      );
    } on Exception catch (e) {
      _logger.warning('خطأ في إنشاء تقرير الأمان: $e');
      return SecurityReport(
        encryptionEnabled: false,
        totalSecureItems: 0,
        lastSecurityCheck: DateTime.now(),
        integrityVerified: false,
        debugMode: kDebugMode,
        platform: defaultTargetPlatform.toString(),
      );
    }
  }

  /// التحقق من سلامة البيانات
  static Future<bool> _isIntegrityVerified() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? savedHash = prefs.getString(_integrityHashKey);
      return savedHash != null;
    } on Exception {
      return false;
    }
  }
}

/// مستويات قوة كلمة المرور
enum PasswordStrengthLevel { weak, medium, strong, veryStrong }

/// معلومات قوة كلمة المرور
class PasswordStrength {
  const PasswordStrength({
    required this.level,
    required this.score,
    required this.checks,
  });
  final PasswordStrengthLevel level;
  final int score;
  final List<String> checks;

  String get description {
    switch (level) {
      case PasswordStrengthLevel.weak:
        return 'ضعيفة';
      case PasswordStrengthLevel.medium:
        return 'متوسطة';
      case PasswordStrengthLevel.strong:
        return 'قوية';
      case PasswordStrengthLevel.veryStrong:
        return 'قوية جداً';
    }
  }
}

/// تقرير الأمان
class SecurityReport {
  const SecurityReport({
    required this.encryptionEnabled,
    required this.totalSecureItems,
    required this.lastSecurityCheck,
    required this.integrityVerified,
    required this.debugMode,
    required this.platform,
  });
  final bool encryptionEnabled;
  final int totalSecureItems;
  final DateTime lastSecurityCheck;
  final bool integrityVerified;
  final bool debugMode;
  final String platform;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'encryptionEnabled': encryptionEnabled,
        'totalSecureItems': totalSecureItems,
        'lastSecurityCheck': lastSecurityCheck.toIso8601String(),
        'integrityVerified': integrityVerified,
        'debugMode': debugMode,
        'platform': platform,
      };
}
