enum ProductBarcodeFormat { ean8, ean13, upcA, upcE }

class ProductBarcode {
  const ProductBarcode({required this.value, required this.format});

  /// Validated digits exactly as represented by the scanned symbology.
  final String value;
  final ProductBarcodeFormat format;

  String get formatLabel {
    return switch (format) {
      ProductBarcodeFormat.ean8 => 'EAN-8',
      ProductBarcodeFormat.ean13 => 'EAN-13',
      ProductBarcodeFormat.upcA => 'UPC-A',
      ProductBarcodeFormat.upcE => 'UPC-E',
    };
  }
}
