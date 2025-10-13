import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

/// خدمة إدارة الحضور والجلسات النشطة
class PresenceService {
  factory PresenceService() => _instance;
  PresenceService._internal();
  static final PresenceService _instance = PresenceService._internal();
  static PresenceService get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collectionName = 'active_sessions';

  Timer? _heartbeatTimer;
  String? _currentSessionId;
  String? _currentUserId;
  String? _currentPlatform;

  // Stream controller للجلسات النشطة
  final StreamController<List<ActiveSession>> _sessionsController =
      StreamController<List<ActiveSession>>.broadcast();

  Stream<List<ActiveSession>> get activeSessionsStream =>
      _sessionsController.stream;

  /// بدء جلسة حضور جديدة
  Future<void> goOnline(String userId) async {
    try {
      // التحقق من أن المستخدم لم يسجل دخول بالفعل
      if (_currentUserId == userId && _currentSessionId != null) {
        debugPrint('⚠️ المستخدم مسجل دخول بالفعل، تجاهل الطلب');
        return;
      }

      // إيقاف الجلسة السابقة إن وجدت
      await goOffline();

      // إنشاء معرف جلسة فريد
      _currentSessionId = const Uuid().v4();
      _currentUserId = userId;
      _currentPlatform = _getCurrentPlatform();

      // إنشاء مستند الجلسة
      final Map<String, dynamic> sessionData = <String, dynamic>{
        'userId': userId,
        'platform': _currentPlatform,
        'lastSeen': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
        'sessionId': _currentSessionId,
        'isActive': true,
      };

      await _firestore
          .collection(_collectionName)
          .doc(_currentSessionId)
          .set(sessionData);

      debugPrint(
          '✅ تم بدء جلسة الحضور: $_currentSessionId على $_currentPlatform');

      // بدء نبضات القلب
      _startHeartbeat();

      // إرسال تحديث فوري للجلسات
      _sessionsController.add(<ActiveSession>[]);
    } catch (e) {
      debugPrint('❌ خطأ في بدء جلسة الحضور: $e');
      rethrow;
    }
  }

  /// إيقاف جلسة الحضور
  Future<void> goOffline() async {
    try {
      // إيقاف نبضات القلب
      _stopHeartbeat();

      // حذف الجلسة من قاعدة البيانات
      if (_currentSessionId != null) {
        await _firestore
            .collection(_collectionName)
            .doc(_currentSessionId)
            .delete();

        debugPrint('✅ تم إيقاف جلسة الحضور: $_currentSessionId');

        // إرسال تحديث فوري للجلسات
        _sessionsController.add(<ActiveSession>[]);
      }

      // مسح البيانات المحلية
      _currentSessionId = null;
      _currentUserId = null;
      _currentPlatform = null;
    } catch (e) {
      debugPrint('❌ خطأ في إيقاف جلسة الحضور: $e');
      rethrow;
    }
  }

  /// بدء نبضات القلب
  void _startHeartbeat() {
    _stopHeartbeat(); // إيقاف أي نبضات سابقة

    // استخدام scheduleMicrotask للتأكد من تشغيل العملية على platform thread
    scheduleMicrotask(() {
      _heartbeatTimer =
          Timer.periodic(const Duration(seconds: 30), (Timer timer) async {
        if (_currentSessionId != null && _currentUserId != null) {
          try {
            await _firestore
                .collection(_collectionName)
                .doc(_currentSessionId)
                .update(<Object, Object?>{
              'lastSeen': FieldValue.serverTimestamp(),
            });

            debugPrint('💓 تم إرسال نبضة قلب للجلسة: $_currentSessionId');
          } catch (e) {
            debugPrint('❌ خطأ في إرسال نبضة القلب: $e');
          }
        }
      });
    });
  }

  /// إيقاف نبضات القلب
  void _stopHeartbeat() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
  }

  /// الحصول على الجلسات النشطة
  Stream<List<ActiveSession>> getActiveSessionsStream() => _firestore
          .collection(_collectionName)
          .where('lastSeen',
              isGreaterThan: Timestamp.fromDate(
                  DateTime.now().subtract(const Duration(seconds: 45))))
          .orderBy('lastSeen', descending: true)
          .snapshots()
          .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
        final List<ActiveSession> sessions = snapshot.docs
            .map((QueryDocumentSnapshot<Map<String, dynamic>> doc) =>
                ActiveSession.fromMap(doc.data(), doc.id))
            .toList();

        // تحديث الـ stream
        _sessionsController.add(sessions);

        return sessions;
      });

  /// الحصول على منصة التشغيل الحالية
  String _getCurrentPlatform() {
    if (kIsWeb) return 'Web';
    if (Platform.isWindows) return 'Windows';
    if (Platform.isAndroid) return 'Android';
    if (Platform.isIOS) return 'iOS';
    if (Platform.isLinux) return 'Linux';
    if (Platform.isMacOS) return 'macOS';
    return 'Unknown';
  }

  /// تنظيف الجلسات المنتهية الصلاحية
  Future<void> cleanupExpiredSessions() async {
    try {
      final Timestamp cutoffTime = Timestamp.fromDate(
          DateTime.now().subtract(const Duration(seconds: 60)));

      final QuerySnapshot expiredSessions = await _firestore
          .collection(_collectionName)
          .where('lastSeen', isLessThan: cutoffTime)
          .get();

      if (expiredSessions.docs.isNotEmpty) {
        final WriteBatch batch = _firestore.batch();

        for (final QueryDocumentSnapshot<Object?> doc in expiredSessions.docs) {
          batch.delete(doc.reference);
        }

        await batch.commit();

        debugPrint(
            '🧹 تم تنظيف ${expiredSessions.docs.length} جلسة منتهية الصلاحية');

        // إرسال تحديث فوري للجلسات
        _sessionsController.add(<ActiveSession>[]);
      }
    } catch (e) {
      debugPrint('❌ خطأ في تنظيف الجلسات المنتهية: $e');
    }
  }

  /// إجبار إنهاء جلسة محددة
  Future<void> forceEndSession(String sessionId) async {
    try {
      await _firestore.collection(_collectionName).doc(sessionId).delete();
      debugPrint('🗑️ تم حذف الجلسة: $sessionId');
    } catch (e) {
      debugPrint('❌ خطأ في حذف الجلسة $sessionId: $e');
    }
  }

  /// إغلاق الخدمة
  void dispose() {
    _stopHeartbeat();
    _sessionsController.close();
  }
}

/// نموذج بيانات الجلسة النشطة
class ActiveSession {
  ActiveSession({
    required this.sessionId,
    required this.userId,
    required this.platform,
    required this.lastSeen,
    required this.createdAt,
  });

  factory ActiveSession.fromMap(Map<String, dynamic> data, String id) =>
      ActiveSession(
        sessionId: id,
        userId: (data['userId'] ?? '') as String,
        platform: (data['platform'] ?? 'Unknown') as String,
        lastSeen: (data['lastSeen'] as Timestamp?)?.toDate() ?? DateTime.now(),
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      );
  final String sessionId;
  final String userId;
  final String platform;
  final DateTime lastSeen;
  final DateTime createdAt;

  Map<String, dynamic> toMap() => <String, dynamic>{
        'sessionId': sessionId,
        'userId': userId,
        'platform': platform,
        'lastSeen': Timestamp.fromDate(lastSeen),
        'createdAt': Timestamp.fromDate(createdAt),
      };

  /// التحقق من أن الجلسة لا تزال نشطة (آخر 45 ثانية)
  bool get isActive {
    final Duration difference = DateTime.now().difference(lastSeen);
    return difference.inSeconds <= 45;
  }

  /// الحصول على وقت آخر نشاط بصيغة مقروءة
  String get lastSeenFormatted {
    final Duration difference = DateTime.now().difference(lastSeen);

    if (difference.inSeconds < 60) {
      return 'منذ ${difference.inSeconds} ثانية';
    } else if (difference.inMinutes < 60) {
      return 'منذ ${difference.inMinutes} دقيقة';
    } else if (difference.inHours < 24) {
      return 'منذ ${difference.inHours} ساعة';
    } else {
      return 'منذ ${difference.inDays} يوم';
    }
  }

  @override
  String toString() =>
      'ActiveSession(sessionId: $sessionId, userId: $userId, platform: $platform, lastSeen: $lastSeen)';
}
