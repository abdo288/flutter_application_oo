import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../utils/constants.dart';
import '../../utils/snackbar_utils.dart';
import '../../widgets/barcode_scanner_view.dart';

class BarcodeScannerWidget extends StatefulWidget {
  const BarcodeScannerWidget({
    super.key,
    required this.onBarcodeScanned,
  });

  final void Function(String) onBarcodeScanned;

  @override
  State<BarcodeScannerWidget> createState() => _BarcodeScannerWidgetState();
}

class _BarcodeScannerWidgetState extends State<BarcodeScannerWidget> {
  final TextEditingController _barcodeController = TextEditingController();
  bool _isScanning = false;

  @override
  void dispose() {
    _barcodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(AppConstants.borderRadius),
          border: Border.all(
            color: AppConstants.primaryColor.withValues(alpha: 0.2),
          ),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: AppConstants.primaryColor.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'مسح الباركود',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppConstants.primaryColor,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Expanded(
                  child: TextField(
                    controller: _barcodeController,
                    decoration: const InputDecoration(
                      hintText: 'أدخل الباركود أو امسحه',
                      prefixIcon: Icon(Icons.qr_code_scanner),
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    onSubmitted: _handleBarcode,
                    textInputAction: TextInputAction.done,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _isScanning ? null : _scanBarcode,
                  icon: _isScanning
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.camera_alt),
                  tooltip: 'مسح الباركود',
                  style: IconButton.styleFrom(
                    backgroundColor: AppConstants.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(48, 48),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _barcodeController.text.isNotEmpty
                    ? () => _handleBarcode(_barcodeController.text)
                    : null,
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('إضافة للسلة'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppConstants.successColor,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      );

  Future<void> _scanBarcode() async {
    if (_isScanning) return;

    setState(() {
      _isScanning = true;
    });

    try {
      HapticFeedback.lightImpact();

      final String? barcode = await Navigator.of(context).push<String>(
        MaterialPageRoute<String>(
          builder: (BuildContext context) => const BarcodeScannerView(),
        ),
      );

      if (barcode != null && barcode.isNotEmpty) {
        _barcodeController.text = barcode;
        await _handleBarcode(barcode);
      }
    } catch (e) {
      SnackbarUtils.showError(context, 'خطأ في مسح الباركود: $e');
    } finally {
      if (mounted) {
        setState(() {
          _isScanning = false;
        });
      }
    }
  }

  Future<void> _handleBarcode(String barcode) async {
    if (barcode.trim().isEmpty) {
      SnackbarUtils.showError(context, 'الباركود فارغ');
      return;
    }

    try {
      widget.onBarcodeScanned(barcode.trim());
      _barcodeController.clear();
    } catch (e) {
      SnackbarUtils.showError(context, 'خطأ في معالجة الباركود: $e');
    }
  }
}
