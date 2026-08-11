import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/nutrition/domain/calculators/macro_calculator.dart';
import 'package:mobile/features/profile/domain/entities/user_profile.dart';

void main() {
  group('Macro Calculator', () {
    const calculator = MacroCalculator();

    test('calculates macros for weight loss', () {
      final macros = calculator.calculate(
        calories: 2000,
        weightKg: 80,
        goal: HealthGoal.loseWeight,
      );

      expect(macros.protein, closeTo(160, 0.1));
      expect(macros.fat, closeTo(66.67, 0.1));
      expect(macros.carbohydrates, closeTo(190, 0.1));
    });

    test('calculates macros for maintenance', () {
      final macros = calculator.calculate(
        calories: 2500,
        weightKg: 80,
        goal: HealthGoal.maintainWeight,
      );

      expect(macros.protein, closeTo(112, 0.1));
      expect(macros.fat, closeTo(83.33, 0.1));
      expect(macros.carbohydrates, closeTo(325.5, 0.1));
    });

    test('throws for zero calories', () {
      expect(
        () => calculator.calculate(
          calories: 0,
          weightKg: 80,
          goal: HealthGoal.maintainWeight,
        ),
        throwsArgumentError,
      );
    });

    test('throws for negative calories', () {
      expect(
        () => calculator.calculate(
          calories: -100,
          weightKg: 80,
          goal: HealthGoal.maintainWeight,
        ),
        throwsArgumentError,
      );
    });
  });
}
