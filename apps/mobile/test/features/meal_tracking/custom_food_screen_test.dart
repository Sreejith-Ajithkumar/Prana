import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/meal_tracking/domain/entities/catalog_food.dart';
import 'package:mobile/features/meal_tracking/domain/entities/custom_food_draft.dart';
import 'package:mobile/features/meal_tracking/domain/repositories/custom_food_repository.dart';
import 'package:mobile/features/meal_tracking/presentation/screens/custom_food_screen.dart';

void main() {
  testWidgets('creates a custom food from the editor form', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repository = FakeCustomFoodRepository();

    await tester.pumpWidget(
      MaterialApp(home: CustomFoodScreen(repository: repository)),
    );

    await tester.enterText(
      find.byKey(const ValueKey('custom-food-name')),
      'Homemade smoothie',
    );
    await tester.enterText(
      find.byKey(const ValueKey('custom-food-calories')),
      '280',
    );
    await tester.enterText(
      find.byKey(const ValueKey('custom-food-protein')),
      '25',
    );
    await tester.enterText(
      find.byKey(const ValueKey('custom-food-carbs')),
      '35',
    );
    await tester.enterText(find.byKey(const ValueKey('custom-food-fat')), '6');

    await tester.tap(find.text('Save custom food'));
    await tester.pumpAndSettle();

    expect(repository.createdDraft, isNotNull);
    expect(repository.createdDraft!.name, 'Homemade smoothie');
    expect(repository.createdDraft!.calories, 280);
  });

  testWidgets('deletes an existing custom food after confirmation', (
    tester,
  ) async {
    final repository = FakeCustomFoodRepository();
    final food = _customFood();

    await tester.pumpWidget(
      MaterialApp(
        home: CustomFoodScreen(food: food, repository: repository),
      ),
    );

    await tester.tap(find.byTooltip('Delete custom food'));
    await tester.pumpAndSettle();

    expect(find.text('Delete custom food?'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, 'Delete'));
    await tester.pumpAndSettle();

    expect(repository.deletedIdentityKey, food.identityKey);
  });
}

CatalogFood _customFood() {
  return const CatalogFood(
    id: 'custom-1',
    name: 'Custom oats',
    servingDescription: '1 bowl',
    servingQuantity: 1,
    servingUnit: 'bowl',
    calories: 350,
    proteinGrams: 20,
    carbohydrateGrams: 40,
    fatGrams: 10,
    source: CatalogFoodSource.custom,
    providerId: 'prana-custom',
  );
}

class FakeCustomFoodRepository implements CustomFoodRepository {
  CustomFoodDraft? createdDraft;
  String? deletedIdentityKey;

  @override
  Future<CatalogFood> createCustomFood(CustomFoodDraft draft) async {
    createdDraft = draft;

    return draft.toCatalogFood(id: 'custom-created');
  }

  @override
  Future<CatalogFood> updateCustomFood(
    String identityKey,
    CustomFoodDraft draft,
  ) async {
    return draft.toCatalogFood(id: 'custom-updated');
  }

  @override
  Future<void> deleteCustomFood(String identityKey) async {
    deletedIdentityKey = identityKey;
  }

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
