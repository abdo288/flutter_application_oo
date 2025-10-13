import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../services/connectivity_service.dart';

/// مؤشر حالة الاتصال
class OfflineIndicator extends StatefulWidget {
  const OfflineIndicator({
    super.key,
    required this.child,
  });
  final Widget child;

  @override
  State<OfflineIndicator> createState() => _OfflineIndicatorState();
}

class _OfflineIndicatorState extends State<OfflineIndicator> {
  bool _isOnline = true;

  @override
  void initState() {
    super.initState();
    ConnectivityService.addConnectivityListener(_onConnectivityChanged);
  }

  @override
  void dispose() {
    ConnectivityService.removeConnectivityListener(_onConnectivityChanged);
    super.dispose();
  }

  void _onConnectivityChanged(bool isOnline) {
    if (mounted) {
      setState(() {
        _isOnline = isOnline;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
        children: <Widget>[
          widget.child,
          if (!_isOnline)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                color: Colors.red,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    const Icon(
                      Icons.wifi_off,
                      color: Colors.white,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppLocalizations.of(context).offlineMode,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      );
}
