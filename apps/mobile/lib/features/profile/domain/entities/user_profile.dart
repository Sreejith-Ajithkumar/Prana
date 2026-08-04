enum BiologicalSex { male, female, unspecified }

enum ActivityLevel {
  sedentary,
  lightlyActive,
  moderatelyActive,
  veryActive,
  athlete,
}

enum HealthGoal { loseWeight, maintainWeight, gainMuscle, improveHealth }

class UserProfile {
  const UserProfile({
    required this.firstName,
    required this.dateOfBirth,
    required this.biologicalSex,
    required this.heightCm,
    required this.weightKg,
    required this.goalWeightKg,
    required this.activityLevel,
    required this.goal,
  });

  final String firstName;
  final DateTime dateOfBirth;
  final BiologicalSex biologicalSex;
  final double heightCm;
  final double weightKg;
  final double goalWeightKg;
  final ActivityLevel activityLevel;
  final HealthGoal goal;

  int get age {
    final now = DateTime.now();
    var years = now.year - dateOfBirth.year;

    final birthdayHasNotOccurred =
        now.month < dateOfBirth.month ||
        (now.month == dateOfBirth.month && now.day < dateOfBirth.day);

    if (birthdayHasNotOccurred) {
      years--;
    }

    return years;
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'dateOfBirth': dateOfBirth.toIso8601String(),
      'biologicalSex': biologicalSex.name,
      'heightCm': heightCm,
      'weightKg': weightKg,
      'goalWeightKg': goalWeightKg,
      'activityLevel': activityLevel.name,
      'goal': goal.name,
    };
  }

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      firstName: json['firstName'] as String,
      dateOfBirth: DateTime.parse(json['dateOfBirth'] as String),
      biologicalSex: BiologicalSex.values.byName(
        json['biologicalSex'] as String,
      ),
      heightCm: (json['heightCm'] as num).toDouble(),
      weightKg: (json['weightKg'] as num).toDouble(),
      goalWeightKg: (json['goalWeightKg'] as num).toDouble(),
      activityLevel: ActivityLevel.values.byName(
        json['activityLevel'] as String,
      ),
      goal: HealthGoal.values.byName(json['goal'] as String),
    );
  }
}
