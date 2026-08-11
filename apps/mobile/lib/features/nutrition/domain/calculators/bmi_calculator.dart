import '../models/bmi_category.dart';

/// Calculates Body Mass Index (BMI).
///
/// Formula:
/// BMI = weight (kg) / height² (m²)
///
/// Reference:
/// World Health Organization (WHO)
class BmiCalculator {
  const BmiCalculator();

  /// Returns the calculated BMI.
  double calculate({required double heightCm, required double weightKg}) {
    assert(heightCm > 0);
    assert(weightKg > 0);

    final heightMeters = heightCm / 100;

    return weightKg / (heightMeters * heightMeters);
  }

  /// Returns the BMI category.
  BmiCategory category(double bmi) {
    if (bmi < 18.5) {
      return BmiCategory.underweight;
    }

    if (bmi < 25) {
      return BmiCategory.healthy;
    }

    if (bmi < 30) {
      return BmiCategory.overweight;
    }

    return BmiCategory.obesity;
  }

  /// Returns the minimum healthy weight (kg)
  /// for the given height.
  double healthyWeightMin(double heightCm) {
    final heightMeters = heightCm / 100;
    return 18.5 * heightMeters * heightMeters;
  }

  /// Returns the maximum healthy weight (kg)
  /// for the given height.
  double healthyWeightMax(double heightCm) {
    final heightMeters = heightCm / 100;
    return 24.9 * heightMeters * heightMeters;
  }
}
