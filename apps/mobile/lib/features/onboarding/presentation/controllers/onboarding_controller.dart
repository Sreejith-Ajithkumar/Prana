import 'package:flutter/foundation.dart';

import '../../../profile/domain/entities/user_profile.dart';
import 'onboarding_state.dart';

class OnboardingController extends ChangeNotifier {
  OnboardingState _state = const OnboardingState();

  OnboardingState get state => _state;

  void setFirstName(String value) {
    _state = _state.copyWith(firstName: value);
    notifyListeners();
  }

  void setBiologicalSex(BiologicalSex value) {
    _state = _state.copyWith(biologicalSex: value);
    notifyListeners();
  }

  void setDateOfBirth(DateTime value) {
    _state = _state.copyWith(dateOfBirth: value);
    notifyListeners();
  }

  void setHeight(double value) {
    _state = _state.copyWith(heightCm: value);
    notifyListeners();
  }

  void setWeight(double value) {
    _state = _state.copyWith(weightKg: value);
    notifyListeners();
  }

  void setGoalWeight(double value) {
    _state = _state.copyWith(goalWeightKg: value);
    notifyListeners();
  }

  void setActivityLevel(ActivityLevel value) {
    _state = _state.copyWith(activityLevel: value);
    notifyListeners();
  }

  void setGoal(HealthGoal value) {
    _state = _state.copyWith(goal: value);
    notifyListeners();
  }

  void reset() {
    _state = const OnboardingState();
    notifyListeners();
  }

  UserProfile buildProfile() {
    final currentState = state;

    if (currentState.firstName.trim().isEmpty ||
        currentState.dateOfBirth == null ||
        currentState.biologicalSex == null ||
        currentState.heightCm == null ||
        currentState.weightKg == null ||
        currentState.goalWeightKg == null ||
        currentState.activityLevel == null ||
        currentState.goal == null) {
      throw StateError('The onboarding profile is incomplete.');
    }

    return UserProfile(
      firstName: currentState.firstName.trim(),
      dateOfBirth: currentState.dateOfBirth!,
      biologicalSex: currentState.biologicalSex!,
      heightCm: currentState.heightCm!,
      weightKg: currentState.weightKg!,
      goalWeightKg: currentState.goalWeightKg!,
      activityLevel: currentState.activityLevel!,
      goal: currentState.goal!,
    );
  }
}
