import 'package:flutter_test/flutter_test.dart';

import 'package:mobile/features/nutrition/domain/models/bmi_category.dart';
import 'package:mobile/features/nutrition/domain/services/nutrition_service.dart';
import 'package:mobile/features/profile/domain/entities/user_profile.dart';

void main() {
  group('NutritionService', () {
    const service = NutritionService();

    test('calculates complete nutrition targets for weight loss', () {
      final now = DateTime.now();

      final profile = UserProfile(
        firstName: 'Test User',
        dateOfBirth: DateTime(
          now.year - 30,
          now.month,
          now.day,
        ),
        biologicalSex: BiologicalSex.male,
        heightCm: 180,
        weightKg: 80,
        goalWeightKg: 72,
        activityLevel: ActivityLevel.moderatelyActive,
        goal: HealthGoal.loseWeight,
      );

      final targets = service.calculate(profile);

      expect(profile.age, 30);

      expect(
        targets.bmi,
        closeTo(24.691, 0.001),
      );

      expect(
        targets.bmiCategory,
        BmiCategory.healthy,
      );

      expect(
        targets.bmr,
        closeTo(1780, 0.001),
      );

      expect(
        targets.tdee,
        closeTo(2759, 0.001),
      );

      expect(
        targets.calories,
        closeTo(2259, 0.001),
      );

      expect(
        targets.protein,
        closeTo(160, 0.001),
      );

      expect(
        targets.fat,
        closeTo(75.3, 0.01),
      );

      expect(
        targets.carbohydrates,
        closeTo(235.325, 0.01),
      );

      expect(
        targets.waterLitres,
        closeTo(2.64, 0.001),
      );
    });

    test('calculates maintenance targets for female profile', () {
      final now = DateTime.now();

      final profile = UserProfile(
        firstName: 'Test User',
        dateOfBirth: DateTime(
          now.year - 30,
          now.month,
          now.day,
        ),
        biologicalSex: BiologicalSex.female,
        heightCm: 165,
        weightKg: 60,
        goalWeightKg: 60,
        activityLevel: ActivityLevel.sedentary,
        goal: HealthGoal.maintainWeight,
      );

      final targets = service.calculate(profile);

      expect(
        targets.bmi,
        closeTo(22.039, 0.001),
      );

      expect(
        targets.bmiCategory,
        BmiCategory.healthy,
      );

      expect(
        targets.bmr,
        closeTo(1320.25, 0.001),
      );

      expect(
        targets.tdee,
        closeTo(1584.3, 0.001),
      );

      expect(
        targets.calories,
        closeTo(1584.3, 0.001),
      );

      expect(
        targets.protein,
        closeTo(84, 0.001),
      );

      expect(
        targets.fat,
        closeTo(52.81, 0.01),
      );

      expect(
        targets.carbohydrates,
        closeTo(193.25, 0.01),
      );

      expect(
        targets.waterLitres,
        closeTo(1.98, 0.001),
      );
    });

    test('throws when biological sex is unspecified', () {
      final now = DateTime.now();

      final profile = UserProfile(
        firstName: 'Test User',
        dateOfBirth: DateTime(
          now.year - 30,
          now.month,
          now.day,
        ),
        biologicalSex: BiologicalSex.unspecified,
        heightCm: 180,
        weightKg: 80,
        goalWeightKg: 75,
        activityLevel: ActivityLevel.moderatelyActive,
        goal: HealthGoal.maintainWeight,
      );

      expect(
        () => service.calculate(profile),
        throwsUnsupportedError,
      );
    });
  });
}

