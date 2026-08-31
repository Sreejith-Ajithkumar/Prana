import '../entities/barcode_lookup_result.dart';
import '../entities/product_barcode.dart';

abstract class BarcodeFoodProvider {
  String get providerId;

  Future<BarcodeLookupResult> lookup(ProductBarcode barcode);

  void close() {}
}
