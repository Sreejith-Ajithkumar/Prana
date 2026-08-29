import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/meal_tracking/domain/entities/product_barcode.dart';
import 'package:mobile/features/meal_tracking/domain/services/product_barcode_parser.dart';

void main() {
  group('ProductBarcodeParser', () {
    const parser = ProductBarcodeParser();

    test('accepts a valid EAN-13 barcode', () {
      final barcode = parser.tryParse(
        rawValue: '4006381333931',
        format: ProductBarcodeFormat.ean13,
      );

      expect(barcode?.value, '4006381333931');
      expect(barcode?.formatLabel, 'EAN-13');
    });

    test('accepts a valid EAN-8 barcode', () {
      final barcode = parser.tryParse(
        rawValue: '96385074',
        format: ProductBarcodeFormat.ean8,
      );

      expect(barcode?.value, '96385074');
    });

    test('accepts a valid UPC-A barcode', () {
      final barcode = parser.tryParse(
        rawValue: '036000291452',
        format: ProductBarcodeFormat.upcA,
      );

      expect(barcode?.value, '036000291452');
      expect(barcode?.formatLabel, 'UPC-A');
    });

    test('accepts a valid UPC-E barcode after expansion validation', () {
      final barcode = parser.tryParse(
        rawValue: '07832309',
        format: ProductBarcodeFormat.upcE,
      );

      expect(barcode?.value, '07832309');
      expect(barcode?.formatLabel, 'UPC-E');
    });

    test('trims surrounding whitespace', () {
      final barcode = parser.tryParse(
        rawValue: ' 4006381333931 ',
        format: ProductBarcodeFormat.ean13,
      );

      expect(barcode?.value, '4006381333931');
    });

    test('rejects an invalid checksum', () {
      final barcode = parser.tryParse(
        rawValue: '4006381333932',
        format: ProductBarcodeFormat.ean13,
      );

      expect(barcode, isNull);
    });

    test('rejects non-numeric values', () {
      final barcode = parser.tryParse(
        rawValue: '400638ABC3931',
        format: ProductBarcodeFormat.ean13,
      );

      expect(barcode, isNull);
    });

    test('rejects a value with the wrong length for its format', () {
      final barcode = parser.tryParse(
        rawValue: '036000291452',
        format: ProductBarcodeFormat.ean13,
      );

      expect(barcode, isNull);
    });

    test('rejects UPC-E with an unsupported number system', () {
      final barcode = parser.tryParse(
        rawValue: '27832309',
        format: ProductBarcodeFormat.upcE,
      );

      expect(barcode, isNull);
    });
  });
}
