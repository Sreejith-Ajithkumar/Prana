import '../domain/repositories/barcode_food_provider.dart';
import 'open_food_facts_barcode_provider.dart';

BarcodeFoodProvider createBarcodeFoodProvider() {
  return OpenFoodFactsBarcodeProvider();
}
