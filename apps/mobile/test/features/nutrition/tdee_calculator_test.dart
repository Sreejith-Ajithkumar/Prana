import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/nutrition/domain/calculators/tdee_calculator.dart';
import 'package:mobile/features/profile/domain/entities/user_profile.dart';

void main() {
  group('TDEE Calculator', () {
    const calculator = TdeeCalculator();

    test('calculates sedentary TDEE correctly', () {
      final result = calculator.calculate(
        bmr: 1800,
        activityLevel: ActivityLevel.sedentary,
      );

      expect(result, closeTo(2160, 0.001));
    });

    test('calculates lightly active TDEE correctly', () {
      final result = calculator.calculate(
        bmr: 1800,
        activityLevel: ActivityLevel.lightlyActive,
      );

      expect(result, closeTo(2475, 0.001));
    });

    test('calculates moderately active TDEE correctly', () {
      final result = calculator.calculate(
        bmr: 1800,
        activityLevel: ActivityLevel.moderatelyActive,
      );

      expect(result, closeTo(2790, 0.001));
    });

    test('calculates very active TDEE correctly', () {
      final result = calculator.calculate(
        bmr: 1800,
        activityLevel: ActivityLevel.veryActive,
      );

      expect(result, closeTo(3105, 0.001));
    });

    test('calculates athlete TDEE correctly', () {
      final result = calculator.calculate(
        bmr: 1800,
        activityLevel: ActivityLevel.athlete,
      );

      expect(result, closeTo(3420, 0.001));
    });

    test('throws when BMR is zero', () {
      expect(
        () => calculator.calculate(
          bmr: 0,
          activityLevel: ActivityLevel.sedentary,
        ),
        throwsArgumentError,
      );
    });

    test('throws when BMR is negative', () {
      expect(
        () => calculator.calculate(
          bmr: -100,
          activityLevel: ActivityLevel.sedentary,
        ),
        throwsArgumentError,
      );
    });
  });
}

