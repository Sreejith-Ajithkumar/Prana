import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/nutrition/domain/calculators/calorie_calculator.dart';
import 'package:mobile/features/profile/domain/entities/user_profile.dart';

void main() {
  group('Calorie Calculator', () {
    const calculator = CalorieCalculator();

    test('uses maximum 500 kcal deficit for sufficiently high TDEE', () {
      final calories = calculator.calculate(
        tdee: 2500,
        goal: HealthGoal.loseWeight,
        biologicalSex: BiologicalSex.male,
      );

      expect(calories, closeTo(2000, 0.001));
    });

    test('limits weight loss deficit to 20 percent for lower TDEE', () {
      final calories = calculator.calculate(
        tdee: 1520,
        goal: HealthGoal.loseWeight,
        biologicalSex: BiologicalSex.female,
      );

      expect(calories, closeTo(1216, 0.001));
    });

    test('respects female weight loss calorie guardrail', () {
      final calories = calculator.calculate(
        tdee: 1450,
        goal: HealthGoal.loseWeight,
        biologicalSex: BiologicalSex.female,
      );

      expect(calories, closeTo(1200, 0.001));
    });

    test('respects male weight loss calorie guardrail', () {
      final calories = calculator.calculate(
        tdee: 1700,
        goal: HealthGoal.loseWeight,
        biologicalSex: BiologicalSex.male,
      );

      expect(calories, closeTo(1500, 0.001));
    });

    test('never raises weight loss target above TDEE', () {
      final calories = calculator.calculate(
        tdee: 1100,
        goal: HealthGoal.loseWeight,
        biologicalSex: BiologicalSex.female,
      );

      expect(calories, closeTo(1100, 0.001));
    });

    test('calculates maintenance calories', () {
      final calories = calculator.calculate(
        tdee: 2500,
        goal: HealthGoal.maintainWeight,
        biologicalSex: BiologicalSex.male,
      );

      expect(calories, closeTo(2500, 0.001));
    });

    test('calculates muscle gain calories', () {
      final calories = calculator.calculate(
        tdee: 2500,
        goal: HealthGoal.gainMuscle,
        biologicalSex: BiologicalSex.male,
      );

      expect(calories, closeTo(2750, 0.001));
    });

    test('calculates improve health calories', () {
      final calories = calculator.calculate(
        tdee: 2500,
        goal: HealthGoal.improveHealth,
        biologicalSex: BiologicalSex.female,
      );

      expect(calories, closeTo(2500, 0.001));
    });

    test('throws when TDEE is zero', () {
      expect(
        () => calculator.calculate(
          tdee: 0,
          goal: HealthGoal.maintainWeight,
          biologicalSex: BiologicalSex.female,
        ),
        throwsArgumentError,
      );
    });

    test('throws when TDEE is negative', () {
      expect(
        () => calculator.calculate(
          tdee: -100,
          goal: HealthGoal.maintainWeight,
          biologicalSex: BiologicalSex.female,
        ),
        throwsArgumentError,
      );
    });

    test('throws for unspecified biological sex during weight loss', () {
      expect(
        () => calculator.calculate(
          tdee: 2000,
          goal: HealthGoal.loseWeight,
          biologicalSex: BiologicalSex.unspecified,
        ),
        throwsUnsupportedError,
      );
    });
  });
}
