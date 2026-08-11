import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/nutrition/domain/calculators/calorie_calculator.dart';
import 'package:mobile/features/profile/domain/entities/user_profile.dart';

void main() {
  group('Calorie Calculator', () {
    const calculator = CalorieCalculator();

    test('calculates weight loss calories', () {
      final calories = calculator.calculate(
        tdee: 2500,
        goal: HealthGoal.loseWeight,
      );

      expect(calories, 2000);
    });

    test('calculates maintenance calories', () {
      final calories = calculator.calculate(
        tdee: 2500,
        goal: HealthGoal.maintainWeight,
      );

      expect(calories, 2500);
    });

    test('calculates muscle gain calories', () {
      final calories = calculator.calculate(
        tdee: 2500,
        goal: HealthGoal.gainMuscle,
      );

      expect(calories, 2750);
    });

    test('calculates improve health calories', () {
      final calories = calculator.calculate(
        tdee: 2500,
        goal: HealthGoal.improveHealth,
      );

      expect(calories, 2500);
    });

    test('throws when TDEE is zero', () {
      expect(
        () => calculator.calculate(tdee: 0, goal: HealthGoal.maintainWeight),
        throwsArgumentError,
      );
    });

    test('throws when TDEE is negative', () {
      expect(
        () => calculator.calculate(tdee: -100, goal: HealthGoal.maintainWeight),
        throwsArgumentError,
      );
    });
  });
}
