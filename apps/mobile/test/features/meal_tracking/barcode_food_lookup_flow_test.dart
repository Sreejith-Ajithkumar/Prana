import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/meal_tracking/domain/entities/barcode_lookup_result.dart';
import 'package:mobile/features/meal_tracking/domain/entities/catalog_food.dart';
import 'package:mobile/features/meal_tracking/domain/entities/product_barcode.dart';
import 'package:mobile/features/meal_tracking/domain/entities/recent_food_reference.dart';
import 'package:mobile/features/meal_tracking/domain/repositories/barcode_food_provider.dart';
import 'package:mobile/features/meal_tracking/domain/repositories/food_preferences_repository.dart';
import 'package:mobile/features/meal_tracking/domain/repositories/food_repository.dart';
import 'package:mobile/features/meal_tracking/presentation/screens/food_search_screen.dart';

void main() {
  testWidgets('scans and renders a global barcode lookup result', (
    tester,
  ) async {
    const barcode = ProductBarcode(
      value: '3017620422003',
      format: ProductBarcodeFormat.ean13,
    );

    const food = CatalogFood(
      id: '3017620422003',
      name: 'Global cereal',
      brand: 'Example Brand',
      barcode: '3017620422003',
      source: CatalogFoodSource.externalCatalog,
      providerId: 'open-food-facts',
      servingDescription: '30 g',
      servingQuantity: 1,
      servingUnit: 'serving',
      calories: 120,
      proteinGrams: 3,
      carbohydrateGrams: 22,
      fatGrams: 2,
    );

    final provider = FakeBarcodeFoodProvider(
      result: const BarcodeLookupSuccess(barcode: barcode, food: food),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FoodSearchScreen(
          repository: const EmptyFoodRepository(),
          preferencesRepository: FakeFoodPreferencesRepository(),
          barcodeFoodProvider: provider,
          barcodeScanAction: (context) async => barcode,
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Scan barcode'));
    await tester.pumpAndSettle();

    expect(provider.lookups, [barcode.value]);
    expect(
      find.byKey(const ValueKey('barcode-lookup-success')),
      findsOneWidget,
    );
    expect(find.text('Global cereal'), findsOneWidget);
    expect(find.text('Example Brand'), findsOneWidget);
    expect(find.text('Data: Open Food Facts'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Use food'), findsOneWidget);
  });

  testWidgets('shows a friendly not-found state', (tester) async {
    const barcode = ProductBarcode(
      value: '4006381333931',
      format: ProductBarcodeFormat.ean13,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: FoodSearchScreen(
          repository: const EmptyFoodRepository(),
          preferencesRepository: FakeFoodPreferencesRepository(),
          barcodeFoodProvider: FakeBarcodeFoodProvider(
            result: const BarcodeLookupNotFound(barcode: barcode),
          ),
          barcodeScanAction: (context) async => barcode,
        ),
      ),
    );

    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(OutlinedButton, 'Scan barcode'));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('barcode-lookup-not-found')),
      findsOneWidget,
    );
    expect(find.textContaining('product was not found'), findsOneWidget);
  });
}

class FakeBarcodeFoodProvider implements BarcodeFoodProvider {
  FakeBarcodeFoodProvider({required this.result});

  final BarcodeLookupResult result;
  final List<String> lookups = [];

  @override
  String get providerId => 'fake-provider';

  @override
  Future<BarcodeLookupResult> lookup(ProductBarcode barcode) async {
    lookups.add(barcode.value);
    return result;
  }

  @override
  void close() {}
}

class EmptyFoodRepository implements FoodRepository {
  const EmptyFoodRepository();

  @override
  Future<List<CatalogFood>> searchFoods(String query) async {
    return const [];
  }

  @override
  Future<CatalogFood?> findFoodById(String id) async {
    return null;
  }

  @override
  Future<CatalogFood?> findFoodByIdentity(String identityKey) async {
    return null;
  }
}

class FakeFoodPreferencesRepository implements FoodPreferencesRepository {
  @override
  Future<Set<String>> loadFavoriteIdentityKeys() async {
    return <String>{};
  }

  @override
  Future<List<RecentFoodReference>> loadRecents() async {
    return const [];
  }

  @override
  Future<void> recordRecent(String identityKey, {DateTime? usedAt}) async {}

  @override
  Future<void> setFavorite(
    String identityKey, {
    required bool isFavorite,
  }) async {}
}
