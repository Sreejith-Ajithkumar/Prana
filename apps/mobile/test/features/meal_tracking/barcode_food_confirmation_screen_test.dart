import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/meal_tracking/domain/entities/catalog_food.dart';
import 'package:mobile/features/meal_tracking/presentation/screens/barcode_food_confirmation_screen.dart';

void main() {
  const food = CatalogFood(
    id: '3017620422003',
    name: 'Hazelnut spread',
    brand: 'Example Brand',
    barcode: '3017620422003',
    source: CatalogFoodSource.externalCatalog,
    providerId: 'open-food-facts',
    servingDescription: '15 g',
    servingQuantity: 1,
    servingUnit: 'serving',
    calories: 80,
    proteinGrams: 1,
    carbohydrateGrams: 8.6,
    fatGrams: 4.6,
  );

  testWidgets('shows source barcode serving and nutrition', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: BarcodeFoodConfirmationScreen(food: food)),
    );

    expect(find.text('Hazelnut spread'), findsOneWidget);
    expect(find.text('Example Brand'), findsOneWidget);
    expect(find.text('Open Food Facts'), findsOneWidget);
    expect(find.text('Barcode: 3017620422003'), findsOneWidget);
    expect(find.text('1 serving = 15 g'), findsOneWidget);
    expect(find.text('80 kcal'), findsOneWidget);
  });

  testWidgets('recalculates nutrition when quantity changes', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: BarcodeFoodConfirmationScreen(food: food)),
    );

    await tester.enterText(
      find.byKey(const ValueKey('barcode-food-quantity')),
      '2.5',
    );
    await tester.pump();

    expect(find.text('200 kcal'), findsOneWidget);
    expect(find.text('2.5 g'), findsOneWidget);
    expect(find.text('21.5 g'), findsOneWidget);
    expect(find.text('11.5 g'), findsOneWidget);
  });

  testWidgets('rejects zero quantity', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: BarcodeFoodConfirmationScreen(food: food)),
    );

    await tester.enterText(
      find.byKey(const ValueKey('barcode-food-quantity')),
      '0',
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('barcode-food-quantity-error')),
      findsOneWidget,
    );

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    final confirmButton = find.byKey(const ValueKey('confirm-barcode-food'));

    expect(confirmButton, findsOneWidget);

    final button = tester.widget<FilledButton>(confirmButton);

    expect(button.onPressed, isNull);
  });

  testWidgets('returns a scaled CatalogFood when confirmed', (tester) async {
    CatalogFood? result;

    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: FilledButton(
                onPressed: () async {
                  result = await Navigator.of(context).push<CatalogFood>(
                    MaterialPageRoute(
                      builder: (context) {
                        return const BarcodeFoodConfirmationScreen(food: food);
                      },
                    ),
                  );
                },
                child: const Text('Open'),
              ),
            );
          },
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byKey(const ValueKey('barcode-food-quantity')),
      '2',
    );
    await tester.pump();

    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pumpAndSettle();

    final confirmButton = find.byKey(const ValueKey('confirm-barcode-food'));

    expect(confirmButton, findsOneWidget);

    await tester.tap(confirmButton);
    await tester.pumpAndSettle();

    expect(result, isNotNull);
    expect(result!.calories, 160);
    expect(result!.proteinGrams, 2);
    expect(result!.carbohydrateGrams, 17.2);
    expect(result!.fatGrams, 9.2);
    expect(result!.servingDescription, '2 × 15 g');
    expect(result!.servingQuantity, 2);
    expect(result!.servingUnit, 'serving');
    expect(result!.providerId, 'open-food-facts');
    expect(result!.barcode, '3017620422003');
  });
}
