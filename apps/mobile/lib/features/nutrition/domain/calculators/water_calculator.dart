import '../constants/nutrition_constants.dart';

/// Estimates a starting daily fluid target.
///
/// This is a general wellness estimate for healthy adults.
/// Actual needs may vary with activity, climate, health conditions,
/// pregnancy, breastfeeding, diet, and clinician recommendations.
class WaterCalculator {
  const WaterCalculator();

  double calculate({required double weightKg}) {
    if (weightKg <= 0) {
      throw ArgumentError.value(
        weightKg,
        'weightKg',
        'Weight must be greater than zero.',
      );
    }

    return weightKg * NutritionConstants.waterLitresPerKg;
  }
}
