import '../../../profile/domain/entities/user_profile.dart';
import '../constants/nutrition_constants.dart';

class MacroCalculator {
  const MacroCalculator();

  ({double protein, double carbohydrates, double fat}) calculate({
    required double calories,
    required double weightKg,
    required HealthGoal goal,
  }) {
    if (calories <= 0) {
      throw ArgumentError.value(
        calories,
        'calories',
        'Calories must be greater than zero.',
      );
    }

    if (weightKg <= 0) {
      throw ArgumentError.value(
        weightKg,
        'weightKg',
        'Weight must be greater than zero.',
      );
    }

    final proteinPerKg = switch (goal) {
      HealthGoal.loseWeight => NutritionConstants.proteinLoseWeight,
      HealthGoal.maintainWeight => NutritionConstants.proteinMaintain,
      HealthGoal.gainMuscle => NutritionConstants.proteinGainMuscle,
      HealthGoal.improveHealth => NutritionConstants.proteinImproveHealth,
    };

    final fatPercentage = switch (goal) {
      HealthGoal.loseWeight => NutritionConstants.fatLoseWeight,
      HealthGoal.maintainWeight => NutritionConstants.fatMaintain,
      HealthGoal.gainMuscle => NutritionConstants.fatGainMuscle,
      HealthGoal.improveHealth => NutritionConstants.fatImproveHealth,
    };

    final protein = weightKg * proteinPerKg;

    final proteinCalories = protein * NutritionConstants.caloriesPerGramProtein;

    final fatCalories = calories * fatPercentage;

    final fat = fatCalories / NutritionConstants.caloriesPerGramFat;

    final carbCalories = calories - proteinCalories - fatCalories;

    if (carbCalories < 0) {
      throw StateError(
        'The calorie target is too low for the current '
        'protein and fat allocation.',
      );
    }

    final carbohydrates =
        carbCalories / NutritionConstants.caloriesPerGramCarbohydrate;

    return (protein: protein, carbohydrates: carbohydrates, fat: fat);
  }
}
