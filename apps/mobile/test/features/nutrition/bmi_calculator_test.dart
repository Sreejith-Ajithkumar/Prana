import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/nutrition/domain/calculators/bmi_calculator.dart';
import 'package:mobile/features/nutrition/domain/models/bmi_category.dart';

void main() {
  group('BMI Calculator', () {
    const calculator = BmiCalculator();

    test('calculates BMI correctly', () {
      final bmi = calculator.calculate(
        heightCm: 180,
        weightKg: 80,
      );

      expect(bmi, closeTo(24.691, 0.001));
    });

    test('returns Healthy category', () {
      expect(
        calculator.category(24.7),
        BmiCategory.healthy,
      );
    });

    test('returns Underweight category', () {
      expect(
        calculator.category(17.5),
        BmiCategory.underweight,
      );
    });

    test('returns Overweight category', () {
      expect(
        calculator.category(27.2),
        BmiCategory.overweight,
      );
    });

    test('returns Obesity category', () {
      expect(
        calculator.category(33.8),
        BmiCategory.obesity,
      );
    });
  });
}