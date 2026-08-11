import '../../../profile/domain/entities/user_profile.dart';

import '../calculators/bmi_calculator.dart';
import '../calculators/bmr_calculator.dart';
import '../calculators/calorie_calculator.dart';
import '../calculators/macro_calculator.dart';
import '../calculators/tdee_calculator.dart';
import '../calculators/water_calculator.dart';

import '../models/nutrition_targets.dart';

class NutritionService {
  const NutritionService({
    this.bmiCalculator = const BmiCalculator(),
    this.bmrCalculator = const BmrCalculator(),
    this.tdeeCalculator = const TdeeCalculator(),
    this.calorieCalculator = const CalorieCalculator(),
    this.macroCalculator = const MacroCalculator(),
    this.waterCalculator = const WaterCalculator(),
  });

  final BmiCalculator bmiCalculator;
  final BmrCalculator bmrCalculator;
  final TdeeCalculator tdeeCalculator;
  final CalorieCalculator calorieCalculator;
  final MacroCalculator macroCalculator;
  final WaterCalculator waterCalculator;

  NutritionTargets calculate(UserProfile profile) {
    final bmi = bmiCalculator.calculate(
      heightCm: profile.heightCm,
      weightKg: profile.weightKg,
    );

    final bmiCategory = bmiCalculator.category(bmi);

    final bmr = bmrCalculator.calculate(
      biologicalSex: profile.biologicalSex,
      age: profile.age,
      heightCm: profile.heightCm,
      weightKg: profile.weightKg,
    );

    final tdee = tdeeCalculator.calculate(
      bmr: bmr,
      activityLevel: profile.activityLevel,
    );

    final calories = calorieCalculator.calculate(
      tdee: tdee,
      goal: profile.goal,
    );

    final macros = macroCalculator.calculate(
      calories: calories,
      weightKg: profile.weightKg,
      goal: profile.goal,
    );

    final water = waterCalculator.calculate(weightKg: profile.weightKg);

    return NutritionTargets(
      bmi: bmi,
      bmiCategory: bmiCategory,
      bmr: bmr,
      tdee: tdee,
      calories: calories,
      protein: macros.protein,
      carbohydrates: macros.carbohydrates,
      fat: macros.fat,
      waterLitres: water,
    );
  }
}
