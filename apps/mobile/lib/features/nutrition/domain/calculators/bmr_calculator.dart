import 'package:mobile/features/profile/domain/entities/user_profile.dart';

/// Calculates Basal Metabolic Rate using the
/// Mifflin-St Jeor equation.
class BmrCalculator {
  const BmrCalculator();

  double calculate({
    required BiologicalSex biologicalSex,
    required int age,
    required double heightCm,
    required double weightKg,
  }) {
    if (age <= 0) {
      throw ArgumentError.value(
        age,
        'age',
        'Age must be greater than zero.',
      );
    }

    if (heightCm <= 0) {
      throw ArgumentError.value(
        heightCm,
        'heightCm',
        'Height must be greater than zero.',
      );
    }

    if (weightKg <= 0) {
      throw ArgumentError.value(
        weightKg,
        'weightKg',
        'Weight must be greater than zero.',
      );
    }

    final base =
        (10 * weightKg) +
        (6.25 * heightCm) -
        (5 * age);

    return switch (biologicalSex) {
      BiologicalSex.male => base + 5,
      BiologicalSex.female => base - 161,
      BiologicalSex.unspecified => throw UnsupportedError(
          'A calculation basis is required to estimate BMR.',
        ),
    };
  }
}