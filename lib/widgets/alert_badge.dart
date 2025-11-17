import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../services/inventory_alert_service.dart';
import '../utils/platform_thread_safety.dart';

/// شارة عرض عدد التنبيهات غير المقروءة
class AlertBadge extends StatefulWidget {
  const AlertBadge({
    super.key,
    required this.child,
    this.onTap,
  });
  final Widget child;
  final VoidCallback? onTap;

  @override
  State<AlertBadge> createState() => _AlertBadgeState();
}

class _AlertBadgeState extends State<AlertBadge> {
  int _unreadCount = 0;

  @override
  void initState() {
    super.initState();
    _loadUnreadCount();
    _setupListener();
  }

  void _setupListener() {
    // الاستماع للتغييرات في التنبيهات
    InventoryAlertService.alertsCollection
        .where('isRead', isEqualTo: false)
        .snapshots()
        .listen((QuerySnapshot<Object?> snapshot) {
      // ✅ استخدام PlatformThreadSafety لضمان التنفيذ على platform thread
      PlatformThreadSafety.executeStreamListenerCallback(
        () {
          if (mounted) {
            setState(() {
              _unreadCount = snapshot.docs.length;
            });
          }
        },
        operationName: 'alertBadgeListener',
      );
    });
  }

  Future<void> _loadUnreadCount() async {
    try {
      final int count = await InventoryAlertService.getUnreadAlertsCount();
      if (mounted) {
        setState(() {
          _unreadCount = count;
        });
      }
    } on Exception catch (e) {
      debugPrint('خطأ في تحميل عدد التنبيهات: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final Widget badgeStack = Stack(
      clipBehavior: Clip.none,
      children: <Widget>[
        widget.child,
        if (_unreadCount > 0)
          Positioned(
            right: 0,
            top: 0,
            child: IgnorePointer(
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white, width: 2),
                ),
                constraints: const BoxConstraints(
                  minWidth: 20,
                  minHeight: 20,
                ),
                child: Text(
                  _unreadCount > 99 ? '99+' : _unreadCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );

    if (widget.onTap != null) {
      return Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: widget.onTap,
          child: badgeStack,
        ),
      );
    }
    return badgeStack;
  }
}
