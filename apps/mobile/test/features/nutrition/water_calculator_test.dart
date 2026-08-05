import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/nutrition/domain/calculators/water_calculator.dart';

void main() {
  group('Water Calculator', () {
    const calculator = WaterCalculator();

    test('calculates daily water target', () {
      final water = calculator.calculate(
        weightKg: 80,
      );

      expect(water, closeTo(2.64, 0.001));
    });

    test('throws for zero weight', () {
      expect(
        () => calculator.calculate(
          weightKg: 0,
        ),
        throwsArgumentError,
      );
    });

    test('throws for negative weight', () {
      expect(
        () => calculator.calculate(
          weightKg: -10,
        ),
        throwsArgumentError,
      );
    });
  });
}