/// Centralized constants used throughout the Nutrition Engine.
///
/// These values are based on commonly used nutrition guidelines.
/// They can be adjusted in future versions if we support
/// personalized or clinician-configurable targets.
class NutritionConstants {
  const NutritionConstants._();

  // -----------------------------
  // Activity Multipliers (TDEE)
  // -----------------------------

  static const double sedentaryMultiplier = 1.20;

  static const double lightlyActiveMultiplier = 1.375;

  static const double moderatelyActiveMultiplier = 1.55;

  static const double veryActiveMultiplier = 1.725;

  static const double athleteMultiplier = 1.90;

  // -----------------------------
  // Daily Calorie Adjustments
  // -----------------------------

  /// Default calorie deficit for weight loss.
  static const int weightLossCalories = 500;

  /// No calorie adjustment.
  static const int maintenanceCalories = 0;

  /// Conservative calorie surplus for muscle gain.
  static const int muscleGainCalories = 250;

  /// Improve health defaults to maintenance calories.
  static const int improveHealthCalories = 0;

  // -----------------------------
  // BMI
  // -----------------------------

  static const double healthyBmiMin = 18.5;

  static const double healthyBmiMax = 24.9;

  // -----------------------------
  // Water Intake
  // -----------------------------

  /// Recommended litres of water per kilogram.
  static const double waterLitresPerKg = 0.033;

  // -----------------------------
  // Protein (grams per kg)
  // -----------------------------

  static const double proteinLoseWeight = 2.0;

  static const double proteinMaintain = 1.4;

  static const double proteinGainMuscle = 2.2;

  static const double proteinImproveHealth = 1.2;

  // -----------------------------
  // Fat (% of calories)
  // -----------------------------

  static const double fatLoseWeight = 0.30;

  static const double fatMaintain = 0.30;

  static const double fatGainMuscle = 0.25;

  static const double fatImproveHealth = 0.30;

  // -----------------------------
  // Calories per gram
  // -----------------------------

  static const int caloriesPerGramProtein = 4;
  static const int caloriesPerGramCarbohydrate = 4;
  static const int caloriesPerGramFat = 9;
}
