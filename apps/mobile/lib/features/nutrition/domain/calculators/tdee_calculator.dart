import '../../../profile/domain/entities/user_profile.dart';
import '../constants/nutrition_constants.dart';

/// Calculates Total Daily Energy Expenditure (TDEE).
///
/// Formula:
/// TDEE = BMR × Activity Multiplier
///
/// Activity multipliers are based on commonly used nutrition
/// and fitness guidelines.
class TdeeCalculator {
  const TdeeCalculator();

  double calculate({
    required double bmr,
    required ActivityLevel activityLevel,
  }) {
    if (bmr <= 0) {
      throw ArgumentError.value(bmr, 'bmr', 'BMR must be greater than zero.');
    }

    final multiplier = switch (activityLevel) {
      ActivityLevel.sedentary => NutritionConstants.sedentaryMultiplier,

      ActivityLevel.lightlyActive => NutritionConstants.lightlyActiveMultiplier,

      ActivityLevel.moderatelyActive =>
        NutritionConstants.moderatelyActiveMultiplier,

      ActivityLevel.veryActive => NutritionConstants.veryActiveMultiplier,

      ActivityLevel.athlete => NutritionConstants.athleteMultiplier,
    };

    return bmr * multiplier;
  }
}
