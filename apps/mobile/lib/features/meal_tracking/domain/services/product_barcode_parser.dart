import '../entities/product_barcode.dart';

/// Validates retail product barcodes before Prana accepts a camera detection.
///
/// Phase 8E deliberately stops at a validated barcode value. Provider lookup
/// belongs to Phase 8F.
class ProductBarcodeParser {
  const ProductBarcodeParser();

  ProductBarcode? tryParse({
    required String? rawValue,
    required ProductBarcodeFormat format,
  }) {
    if (rawValue == null) {
      return null;
    }

    final value = rawValue.trim();

    if (!RegExp(r'^\d+$').hasMatch(value)) {
      return null;
    }

    final isValid = switch (format) {
      ProductBarcodeFormat.ean8 =>
        value.length == 8 && _hasValidGtinChecksum(value),
      ProductBarcodeFormat.ean13 =>
        value.length == 13 && _hasValidGtinChecksum(value),
      ProductBarcodeFormat.upcA =>
        value.length == 12 && _hasValidGtinChecksum(value),
      ProductBarcodeFormat.upcE => _hasValidUpcE(value),
    };

    if (!isValid) {
      return null;
    }

    return ProductBarcode(value: value, format: format);
  }

  bool _hasValidUpcE(String value) {
    if (value.length != 8) {
      return false;
    }

    final numberSystem = value[0];

    if (numberSystem != '0' && numberSystem != '1') {
      return false;
    }

    final expanded = _expandUpcE(value);

    return expanded != null && _hasValidGtinChecksum(expanded);
  }

  String? _expandUpcE(String value) {
    final lastPayloadDigit = value[6];

    return switch (lastPayloadDigit) {
      '0' || '1' || '2' =>
        '${value.substring(0, 3)}$lastPayloadDigit'
            '0000'
            '${value.substring(3, 6)}'
            '${value[7]}',
      '3' =>
        '${value.substring(0, 4)}'
            '00000'
            '${value.substring(4, 6)}'
            '${value[7]}',
      '4' =>
        '${value.substring(0, 5)}'
            '00000'
            '${value[5]}'
            '${value[7]}',
      '5' || '6' || '7' || '8' || '9' =>
        '${value.substring(0, 6)}'
            '0000'
            '$lastPayloadDigit'
            '${value[7]}',
      _ => null,
    };
  }

  bool _hasValidGtinChecksum(String value) {
    if (value.length < 2) {
      return false;
    }

    final checkDigit = int.parse(value[value.length - 1]);
    final payload = value.substring(0, value.length - 1);

    var sum = 0;
    var distanceFromRight = 0;

    for (var index = payload.length - 1; index >= 0; index--) {
      final digit = int.parse(payload[index]);
      final weight = distanceFromRight.isEven ? 3 : 1;

      sum += digit * weight;
      distanceFromRight++;
    }

    final expectedCheckDigit = (10 - (sum % 10)) % 10;

    return checkDigit == expectedCheckDigit;
  }
}
