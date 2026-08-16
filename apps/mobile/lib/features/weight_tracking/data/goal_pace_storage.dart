import 'package:shared_preferences/shared_preferences.dart';

import '../domain/services/weight_trend_service.dart';

class GoalPaceStorage {
  GoalPaceStorage._();

  static final GoalPaceStorage instance = GoalPaceStorage._();

  static const String _lossPaceKey = 'prana_goal_pace_loss_kg_per_week';

  static const String _gainPaceKey = 'prana_goal_pace_gain_kg_per_week';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();

  Future<double?> loadWeeklyPace(WeightGoalDirection direction) async {
    return switch (direction) {
      WeightGoalDirection.lose => _preferences.getDouble(_lossPaceKey),
      WeightGoalDirection.gain => _preferences.getDouble(_gainPaceKey),
      WeightGoalDirection.maintain => Future.value(null),
    };
  }

  Future<void> saveWeeklyPace(
    WeightGoalDirection direction,
    double paceKgPerWeek,
  ) async {
    if (!paceKgPerWeek.isFinite || paceKgPerWeek <= 0) {
      throw ArgumentError.value(
        paceKgPerWeek,
        'paceKgPerWeek',
        'Goal pace must be greater than zero.',
      );
    }

    switch (direction) {
      case WeightGoalDirection.lose:
        await _preferences.setDouble(_lossPaceKey, paceKgPerWeek);

      case WeightGoalDirection.gain:
        await _preferences.setDouble(_gainPaceKey, paceKgPerWeek);

      case WeightGoalDirection.maintain:
        return;
    }
  }
}
