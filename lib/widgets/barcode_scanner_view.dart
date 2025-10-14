import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerView extends StatefulWidget {
  const BarcodeScannerView({super.key});

  @override
  State<BarcodeScannerView> createState() => _BarcodeScannerViewState();
}

class _BarcodeScannerViewState extends State<BarcodeScannerView> {
  bool _handled = false;
  MobileScannerController? _controller;

  @override
  void initState() {
    super.initState();
    _controller = MobileScannerController(
      facing: CameraFacing.back,
    );
  }

  @override
  void dispose() {
    // إيقاف الكاميرا قبل التخلص من الـ controller
    _controller?.stop();
    _controller?.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_handled) return;
    final Barcode? first =
        capture.barcodes.isNotEmpty ? capture.barcodes.first : null;
    final String? code = first?.rawValue;
    if (code == null || code.isEmpty) return;
    _handled = true;
    if (mounted) Navigator.of(context).pop(code);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('مسح الباركود')),
        body: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            MobileScanner(
              controller: _controller,
              onDetect: _onDetect,
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'وجّه الباركود داخل الإطار',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      );
}
