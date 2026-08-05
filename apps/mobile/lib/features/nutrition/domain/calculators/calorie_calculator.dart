import '../../../profile/domain/entities/user_profile.dart';
import '../constants/nutrition_constants.dart';

/// Calculates the recommended daily calorie target.
///
/// The calorie target starts from the user's estimated
/// Total Daily Energy Expenditure (TDEE) and applies a
/// goal-based adjustment.
class CalorieCalculator {
  const CalorieCalculator();

  double calculate({required double tdee, required HealthGoal goal}) {
    if (tdee <= 0) {
      throw ArgumentError.value(
        tdee,
        'tdee',
        'TDEE must be greater than zero.',
      );
    }

    return switch (goal) {
      HealthGoal.loseWeight => tdee - NutritionConstants.weightLossCalories,

      HealthGoal.maintainWeight =>
        tdee + NutritionConstants.maintenanceCalories,

      HealthGoal.gainMuscle => tdee + NutritionConstants.muscleGainCalories,

      HealthGoal.improveHealth =>
        tdee + NutritionConstants.improveHealthCalories,
    };
  }
}
