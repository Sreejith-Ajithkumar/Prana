import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/meal_tracking/presentation/screens/global_food_search_screen.dart';

void main() {
  testWidgets('worldwide search renders initial interface', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: GlobalFoodSearchScreen(),
      ),
    );

    expect(find.text('Search worldwide'), findsOneWidget);

    expect(
      find.byKey(const ValueKey('global-food-query')),
      findsOneWidget,
    );

    expect(
      find.byKey(const ValueKey('global-food-submit')),
      findsOneWidget,
    );

    expect(
      find.text('Enter a food and tap Search.'),
      findsOneWidget,
    );
  });
}