import 'dart:math' as math;

import '../../../profile/domain/entities/user_profile.dart';
import '../constants/nutrition_constants.dart';

/// Calculates Prana's estimated daily calorie target.
///
/// The calculation starts with estimated Total Daily Energy
/// Expenditure (TDEE) and applies a goal-based adjustment.
///
/// Weight-loss targets include additional application-level
/// guardrails to avoid automatically producing unusually
/// aggressive calorie restrictions.
class CalorieCalculator {
  const CalorieCalculator();

  double calculate({
    required double tdee,
    required HealthGoal goal,
    required BiologicalSex biologicalSex,
  }) {
    if (tdee <= 0) {
      throw ArgumentError.value(
        tdee,
        'tdee',
        'TDEE must be greater than zero.',
      );
    }

    return switch (goal) {
      HealthGoal.loseWeight => _calculateWeightLossTarget(
          tdee: tdee,
          biologicalSex: biologicalSex,
        ),
      HealthGoal.maintainWeight =>
        tdee + NutritionConstants.maintenanceCalories,
      HealthGoal.gainMuscle =>
        tdee + NutritionConstants.muscleGainCalories,
      HealthGoal.improveHealth =>
        tdee + NutritionConstants.improveHealthCalories,
    };
  }

  double _calculateWeightLossTarget({
    required double tdee,
    required BiologicalSex biologicalSex,
  }) {
    final percentageDeficit =
        tdee * NutritionConstants.maximumWeightLossDeficitFraction;

    final deficit = math.min(
      NutritionConstants.weightLossCalories,
      percentageDeficit,
    );

    final calculatedTarget = tdee - deficit;

    final minimumTarget = switch (biologicalSex) {
      BiologicalSex.female =>
        NutritionConstants.minimumFemaleWeightLossCalories,
      BiologicalSex.male =>
        NutritionConstants.minimumMaleWeightLossCalories,
      BiologicalSex.unspecified => throw UnsupportedError(
          'A calculation basis is required to estimate '
          'a weight-loss calorie target.',
        ),
    };

    // Never force a calorie floor above estimated maintenance.
    //
    // For unusually low estimated TDEE values, Prana therefore
    // falls back toward maintenance rather than recommending
    // an automatic calorie surplus or an aggressive restriction.
    return math.min(
      tdee,
      math.max(
        calculatedTarget,
        minimumTarget,
      ),
    );
  }
}