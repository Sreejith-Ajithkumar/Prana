import 'package:flutter/material.dart';

import '../../domain/entities/product_barcode.dart';
import '../../domain/services/product_barcode_parser.dart';
import '../widgets/mobile_product_barcode_scanner.dart';

typedef ProductBarcodeScannerBuilder =
    Widget Function(
      BuildContext context,
      ProductBarcodeDetectionCallback onDetected,
    );

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({
    super.key,
    this.scannerBuilder,
    this.parser = const ProductBarcodeParser(),
  });

  final ProductBarcodeScannerBuilder? scannerBuilder;
  final ProductBarcodeParser parser;

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen> {
  bool _hasAcceptedScan = false;
  bool _showInvalidBarcodeMessage = false;

  void _handleDetection(String? rawValue, ProductBarcodeFormat format) {
    if (_hasAcceptedScan) {
      return;
    }

    final barcode = widget.parser.tryParse(rawValue: rawValue, format: format);

    if (barcode == null) {
      if (!_showInvalidBarcodeMessage && mounted) {
        setState(() {
          _showInvalidBarcodeMessage = true;
        });
      }

      return;
    }

    _hasAcceptedScan = true;

    Navigator.of(context).pop(barcode);
  }

  @override
  Widget build(BuildContext context) {
    final scannerBuilder =
        widget.scannerBuilder ??
        (BuildContext context, ProductBarcodeDetectionCallback onDetected) {
          return MobileProductBarcodeScanner(onDetected: onDetected);
        };

    return Scaffold(
      appBar: AppBar(title: const Text('Scan barcode')),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  scannerBuilder(context, _handleDetection),
                  const IgnorePointer(child: _BarcodeScanOverlay()),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Column(
                children: [
                  Text(
                    'Center the product barcode inside the frame.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Prana validates EAN and UPC retail barcodes before '
                    'accepting the scan.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (_showInvalidBarcodeMessage) ...[
                    const SizedBox(height: 12),
                    Text(
                      'That barcode could not be validated. Try another code.',
                      key: const ValueKey('invalid-barcode-message'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BarcodeScanOverlay extends StatelessWidget {
  const _BarcodeScanOverlay();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: 0.78,
        heightFactor: 0.34,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.primary,
              width: 3,
            ),
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}
