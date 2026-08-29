import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../domain/entities/product_barcode.dart';

typedef ProductBarcodeDetectionCallback =
    void Function(String? rawValue, ProductBarcodeFormat format);

class MobileProductBarcodeScanner extends StatefulWidget {
  const MobileProductBarcodeScanner({super.key, required this.onDetected});

  final ProductBarcodeDetectionCallback onDetected;

  @override
  State<MobileProductBarcodeScanner> createState() =>
      _MobileProductBarcodeScannerState();
}

class _MobileProductBarcodeScannerState
    extends State<MobileProductBarcodeScanner> {
  late final MobileScannerController _controller;

  @override
  void initState() {
    super.initState();

    _controller = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      formats: const [
        BarcodeFormat.ean8,
        BarcodeFormat.ean13,
        BarcodeFormat.upcA,
        BarcodeFormat.upcE,
      ],
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MobileScanner(
      controller: _controller,
      fit: BoxFit.cover,
      onDetect: (capture) {
        for (final barcode in capture.barcodes) {
          final format = _mapFormat(barcode.format);

          if (format == null) {
            continue;
          }

          widget.onDetected(barcode.rawValue, format);
          return;
        }
      },
      errorBuilder: (context, error) {
        return ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.no_photography_outlined, size: 48),
                  const SizedBox(height: 12),
                  const Text('Camera unavailable', textAlign: TextAlign.center),
                  const SizedBox(height: 8),
                  Text(
                    'Allow camera access and try opening the scanner again.',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  ProductBarcodeFormat? _mapFormat(BarcodeFormat format) {
    return switch (format) {
      BarcodeFormat.ean8 => ProductBarcodeFormat.ean8,
      BarcodeFormat.ean13 => ProductBarcodeFormat.ean13,
      BarcodeFormat.upcA => ProductBarcodeFormat.upcA,
      BarcodeFormat.upcE => ProductBarcodeFormat.upcE,
      _ => null,
    };
  }
}
