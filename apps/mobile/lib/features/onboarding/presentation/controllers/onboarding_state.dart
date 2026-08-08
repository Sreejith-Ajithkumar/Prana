import '../../../profile/domain/entities/user_profile.dart';

class OnboardingState {
  const OnboardingState({
    this.firstName = '',
    this.dateOfBirth,
    this.biologicalSex,
    this.heightCm,
    this.weightKg,
    this.goalWeightKg,
    this.activityLevel,
    this.goal,
  });

  final String firstName;
  final DateTime? dateOfBirth;
  final BiologicalSex? biologicalSex;
  final double? heightCm;
  final double? weightKg;
  final double? goalWeightKg;
  final ActivityLevel? activityLevel;
  final HealthGoal? goal;

  OnboardingState copyWith({
    String? firstName,
    DateTime? dateOfBirth,
    BiologicalSex? biologicalSex,
    double? heightCm,
    double? weightKg,
    double? goalWeightKg,
    ActivityLevel? activityLevel,
    HealthGoal? goal,
  }) {
    return OnboardingState(
      firstName: firstName ?? this.firstName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      biologicalSex: biologicalSex ?? this.biologicalSex,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      goalWeightKg: goalWeightKg ?? this.goalWeightKg,
      activityLevel: activityLevel ?? this.activityLevel,
      goal: goal ?? this.goal,
    );
  }
}
