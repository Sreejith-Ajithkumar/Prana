import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/meal_tracking/domain/entities/product_barcode.dart';
import 'package:mobile/features/meal_tracking/presentation/screens/barcode_scanner_screen.dart';

void main() {
  testWidgets(
    'returns the first valid barcode and ignores duplicate detections',
    (tester) async {
      ProductBarcode? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) {
              return Scaffold(
                body: FilledButton(
                  onPressed: () async {
                    result = await Navigator.of(context).push<ProductBarcode>(
                      MaterialPageRoute(
                        builder: (context) {
                          return BarcodeScannerScreen(
                            scannerBuilder: (context, onDetected) {
                              return Center(
                                child: FilledButton(
                                  onPressed: () {
                                    onDetected(
                                      '036000291452',
                                      ProductBarcodeFormat.upcA,
                                    );
                                    onDetected(
                                      '4006381333931',
                                      ProductBarcodeFormat.ean13,
                                    );
                                  },
                                  child: const Text('Emit barcode'),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                  child: const Text('Open scanner'),
                ),
              );
            },
          ),
        ),
      );

      await tester.tap(find.text('Open scanner'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Emit barcode'));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.value, '036000291452');
      expect(result!.format, ProductBarcodeFormat.upcA);
      expect(find.text('Open scanner'), findsOneWidget);
    },
  );

  testWidgets('keeps scanning after an invalid barcode', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: BarcodeScannerScreen(
          scannerBuilder: (context, onDetected) {
            return Center(
              child: FilledButton(
                onPressed: () {
                  onDetected('4006381333932', ProductBarcodeFormat.ean13);
                },
                child: const Text('Emit invalid barcode'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Emit invalid barcode'));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('invalid-barcode-message')),
      findsOneWidget,
    );
    expect(find.text('Scan barcode'), findsOneWidget);
  });
}
