import 'bmi_category.dart';

class NutritionTargets {
  const NutritionTargets({
    required this.bmi,
    required this.bmiCategory,
    required this.bmr,
    required this.tdee,
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    required this.waterLitres,
  });

  final double bmi;
  final BmiCategory bmiCategory;

  final double bmr;
  final double tdee;

  final double calories;

  final double protein;
  final double carbohydrates;
  final double fat;

  final double waterLitres;
}
