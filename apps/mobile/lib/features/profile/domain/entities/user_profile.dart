enum BiologicalSex {
  male,
  female,
  unspecified,
}

enum ActivityLevel {
  sedentary,
  lightlyActive,
  moderatelyActive,
  veryActive,
  athlete,
}

enum HealthGoal {
  loseWeight,
  maintainWeight,
  gainMuscle,
  improveHealth,
}

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
}
