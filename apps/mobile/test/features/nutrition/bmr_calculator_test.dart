import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/nutrition/domain/calculators/bmr_calculator.dart';
import 'package:mobile/features/profile/domain/entities/user_profile.dart';

void main() {
  group('BMR Calculator', () {
    const calculator = BmrCalculator();

    test('calculates male BMR correctly', () {
      final bmr = calculator.calculate(
        biologicalSex: BiologicalSex.male,
        age: 30,
        heightCm: 180,
        weightKg: 80,
      );

      expect(bmr, closeTo(1780, 0.001));
    });

    test('calculates female BMR correctly', () {
      final bmr = calculator.calculate(
        biologicalSex: BiologicalSex.female,
        age: 30,
        heightCm: 165,
        weightKg: 60,
      );

      expect(bmr, closeTo(1320.25, 0.001));
    });

    test('throws when age is invalid', () {
      expect(
        () => calculator.calculate(
          biologicalSex: BiologicalSex.male,
          age: 0,
          heightCm: 180,
          weightKg: 80,
        ),
        throwsArgumentError,
      );
    });

    test('throws when height is invalid', () {
      expect(
        () => calculator.calculate(
          biologicalSex: BiologicalSex.male,
          age: 30,
          heightCm: 0,
          weightKg: 80,
        ),
        throwsArgumentError,
      );
    });

    test('throws when weight is invalid', () {
      expect(
        () => calculator.calculate(
          biologicalSex: BiologicalSex.male,
          age: 30,
          heightCm: 180,
          weightKg: 0,
        ),
        throwsArgumentError,
      );
    });

    test('throws for unspecified biological sex', () {
      expect(
        () => calculator.calculate(
          biologicalSex: BiologicalSex.unspecified,
          age: 30,
          heightCm: 180,
          weightKg: 80,
        ),
        throwsUnsupportedError,
      );
    });
  });
}
