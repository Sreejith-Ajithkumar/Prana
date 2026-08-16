import 'weight_trend_service.dart';

class GoalPaceResult {
  const GoalPaceResult({
    required this.goalDirection,
    required this.currentWeightKg,
    required this.goalWeightKg,
    required this.weeklyPaceKg,
    required this.fromDate,
    required this.remainingKg,
    required this.estimatedWeeksRemaining,
    required this.estimatedDaysRemaining,
    required this.estimatedTargetDate,
    required this.goalReached,
  });

  final WeightGoalDirection goalDirection;

  final double currentWeightKg;
  final double goalWeightKg;

  /// Selected pace in kilograms per week.
  ///
  /// Null for a maintenance goal because there is no directional
  /// target-date calculation.
  final double? weeklyPaceKg;

  final DateTime fromDate;

  /// Remaining directional weight change.
  ///
  /// This becomes zero once the goal has been reached or passed.
  final double remainingKg;

  final double? estimatedWeeksRemaining;
  final int? estimatedDaysRemaining;
  final DateTime? estimatedTargetDate;

  final bool goalReached;

  bool get hasEstimate {
    return estimatedTargetDate != null;
  }
}

class GoalPaceService {
  const GoalPaceService();

  static const double _goalToleranceKg = 0.05;

  GoalPaceResult calculate({
    required WeightGoalDirection goalDirection,
    required double currentWeightKg,
    required double goalWeightKg,
    required double? weeklyPaceKg,
    required DateTime fromDate,
  }) {
    _validateWeight(currentWeightKg, 'currentWeightKg');

    _validateWeight(goalWeightKg, 'goalWeightKg');

    if (goalDirection == WeightGoalDirection.maintain) {
      final distance = (currentWeightKg - goalWeightKg).abs();

      final goalReached = distance <= _goalToleranceKg;

      return GoalPaceResult(
        goalDirection: goalDirection,
        currentWeightKg: currentWeightKg,
        goalWeightKg: goalWeightKg,
        weeklyPaceKg: null,
        fromDate: fromDate,
        remainingKg: goalReached ? 0 : distance,
        estimatedWeeksRemaining: null,
        estimatedDaysRemaining: null,
        estimatedTargetDate: null,
        goalReached: goalReached,
      );
    }

    if (weeklyPaceKg == null || !weeklyPaceKg.isFinite || weeklyPaceKg <= 0) {
      throw ArgumentError.value(
        weeklyPaceKg,
        'weeklyPaceKg',
        'Weekly pace must be greater than zero for '
            'weight-loss or weight-gain goals.',
      );
    }

    final rawRemainingKg = switch (goalDirection) {
      WeightGoalDirection.lose => currentWeightKg - goalWeightKg,
      WeightGoalDirection.gain => goalWeightKg - currentWeightKg,
      WeightGoalDirection.maintain => 0.0,
    };

    final goalReached = rawRemainingKg <= _goalToleranceKg;

    if (goalReached) {
      return GoalPaceResult(
        goalDirection: goalDirection,
        currentWeightKg: currentWeightKg,
        goalWeightKg: goalWeightKg,
        weeklyPaceKg: weeklyPaceKg,
        fromDate: fromDate,
        remainingKg: 0,
        estimatedWeeksRemaining: null,
        estimatedDaysRemaining: null,
        estimatedTargetDate: null,
        goalReached: true,
      );
    }

    final remainingKg = rawRemainingKg;

    final estimatedWeeksRemaining = remainingKg / weeklyPaceKg;

    final estimatedDaysRemaining = (estimatedWeeksRemaining * 7).ceil();

    final startDateUtc = DateTime.utc(
      fromDate.year,
      fromDate.month,
      fromDate.day,
    );

    final targetDateUtc = startDateUtc.add(
      Duration(days: estimatedDaysRemaining),
    );

    final estimatedTargetDate = DateTime(
      targetDateUtc.year,
      targetDateUtc.month,
      targetDateUtc.day,
    );

    return GoalPaceResult(
      goalDirection: goalDirection,
      currentWeightKg: currentWeightKg,
      goalWeightKg: goalWeightKg,
      weeklyPaceKg: weeklyPaceKg,
      fromDate: fromDate,
      remainingKg: remainingKg,
      estimatedWeeksRemaining: estimatedWeeksRemaining,
      estimatedDaysRemaining: estimatedDaysRemaining,
      estimatedTargetDate: estimatedTargetDate,
      goalReached: false,
    );
  }

  void _validateWeight(double value, String name) {
    if (!value.isFinite || value <= 0) {
      throw ArgumentError.value(
        value,
        name,
        'Weight must be greater than zero.',
      );
    }
  }
}
