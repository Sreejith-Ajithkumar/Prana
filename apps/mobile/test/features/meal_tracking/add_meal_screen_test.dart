import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:mobile/features/meal_tracking/domain/entities/catalog_food.dart';
import 'package:mobile/features/meal_tracking/domain/entities/meal_entry.dart';
import 'package:mobile/features/meal_tracking/presentation/screens/add_meal_screen.dart';

void main() {
  testWidgets('records a catalog food as recent only after saving the meal', (
    tester,
  ) async {
    const banana = CatalogFood(
      id: 'banana',
      name: 'Banana',
      servingDescription: '1 medium banana',
      servingQuantity: 1,
      servingUnit: 'banana',
      calories: 105,
      proteinGrams: 1.3,
      carbohydrateGrams: 27,
      fatGrams: 0.4,
    );

    MealEntry? savedMeal;
    CatalogFood? recordedRecentFood;

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            return const Scaffold(body: Center(child: Text('Home')));
          },
        ),
        GoRoute(
          path: '/add',
          builder: (context, state) {
            return AddMealScreen(
              searchFoodAction: () async => banana,
              saveMealAction: (meal) async {
                savedMeal = meal;
              },
              recordRecentFoodAction: (food) async {
                recordedRecentFood = food;
              },
            );
          },
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));

    await tester.pumpAndSettle();

    router.push('/add');
    await tester.pumpAndSettle();

    expect(recordedRecentFood, isNull);

    await tester.tap(find.text('Search food database'));
    await tester.pumpAndSettle();

    // Selecting/browsing a catalog food alone must not make it recent.
    expect(recordedRecentFood, isNull);

    final saveButton = find.widgetWithText(FilledButton, 'Save meal');

    // Save meal is initially outside the built viewport of the ListView.
    await tester.scrollUntilVisible(
      saveButton,
      400,
      scrollable: find.byType(Scrollable).first,
    );

    await tester.tap(saveButton);
    await tester.pumpAndSettle();

    expect(savedMeal, isNotNull);
    expect(savedMeal!.foods.single.name, 'Banana');

    expect(recordedRecentFood, isNotNull);
    expect(recordedRecentFood!.identityKey, banana.identityKey);

    expect(find.text('Home'), findsOneWidget);
  });
}
