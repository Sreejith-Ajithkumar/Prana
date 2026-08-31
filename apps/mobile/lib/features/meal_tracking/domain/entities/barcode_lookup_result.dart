import 'catalog_food.dart';
import 'product_barcode.dart';

sealed class BarcodeLookupResult {
  const BarcodeLookupResult({required this.barcode});

  final ProductBarcode barcode;
}

final class BarcodeLookupSuccess extends BarcodeLookupResult {
  const BarcodeLookupSuccess({required super.barcode, required this.food});

  final CatalogFood food;
}

final class BarcodeLookupNotFound extends BarcodeLookupResult {
  const BarcodeLookupNotFound({required super.barcode});
}

final class BarcodeLookupIncomplete extends BarcodeLookupResult {
  const BarcodeLookupIncomplete({required super.barcode, this.productName});

  final String? productName;
}

final class BarcodeLookupUnavailable extends BarcodeLookupResult {
  const BarcodeLookupUnavailable({required super.barcode});
}
