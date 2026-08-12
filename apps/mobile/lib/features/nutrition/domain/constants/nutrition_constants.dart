/// Centralized constants used throughout the Nutrition Engine.
///
/// These values support Prana's estimate-based nutrition targets.
/// They should not be treated as individualized medical prescriptions.
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
  // Weight-loss calorie policy
  // -----------------------------

  /// Maximum absolute calorie deficit Prana will apply automatically.
  static const double weightLossCalories = 500;

  /// Prana product guardrail:
  /// the automatic deficit cannot exceed 20% of estimated TDEE.
  ///
  /// This is an application safety policy rather than a universal
  /// clinical prescription.
  static const double maximumWeightLossDeficitFraction = 0.20;

  /// Application-level lower guardrails for automatically generated
  /// weight-loss targets.
  ///
  /// Targets requiring more aggressive restriction should be
  /// individualized with an appropriately qualified professional.
  static const double minimumFemaleWeightLossCalories = 1200;
  static const double minimumMaleWeightLossCalories = 1500;

  /// No calorie adjustment for maintenance.
  static const double maintenanceCalories = 0;

  /// Conservative calorie surplus for muscle gain.
  static const double muscleGainCalories = 250;

  /// Improve-health currently defaults to estimated maintenance.
  static const double improveHealthCalories = 0;

  // -----------------------------
  // BMI
  // -----------------------------

  static const double healthyBmiMin = 18.5;
  static const double healthyBmiMax = 24.9;

  // -----------------------------
  // Water Intake
  // -----------------------------

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
