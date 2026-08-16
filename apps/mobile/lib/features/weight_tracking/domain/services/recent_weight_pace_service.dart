import 'dart:math' as math;

import '../entities/weight_entry.dart';
import 'weight_trend_service.dart';

enum PaceComparisonStatus {
  insufficientData,
  movingAwayFromGoal,
  slowerThanPlan,
  closeToPlan,
  fasterThanPlan,
  notApplicable,
}

class RecentWeightPaceResult {
  const RecentWeightPaceResult({
    required this.goalDirection,
    required this.plannedPaceKgPerWeek,
    required this.distinctMeasurementDays,
    required this.measurementSpanDays,
    required this.actualWeightChangeKgPerWeek,
    required this.goalDirectedPaceKgPerWeek,
    required this.status,
  });

  final WeightGoalDirection goalDirection;

  /// User-selected planned pace.
  ///
  /// Null for maintenance goals.
  final double? plannedPaceKgPerWeek;

  final int distinctMeasurementDays;
  final int measurementSpanDays;

  /// Signed body-weight change.
  ///
  /// Negative means body weight is trending down.
  /// Positive means body weight is trending up.
  final double? actualWeightChangeKgPerWeek;

  /// Pace expressed in the direction of the user's goal.
  ///
  /// Weight loss:
  /// positive = moving toward goal
  /// negative = moving away from goal
  ///
  /// Weight gain:
  /// positive = moving toward goal
  /// negative = moving away from goal
  ///
  /// Null for maintenance goals.
  final double? goalDirectedPaceKgPerWeek;

  final PaceComparisonStatus status;

  bool get hasReliablePace {
    return actualWeightChangeKgPerWeek != null;
  }

  double? get paceDifferenceKgPerWeek {
    final actual = goalDirectedPaceKgPerWeek;
    final planned = plannedPaceKgPerWeek;

    if (actual == null || planned == null) {
      return null;
    }

    return actual - planned;
  }
}

class RecentWeightPaceService {
  const RecentWeightPaceService({
    this.minimumMeasurementDays = 3,
    this.minimumSpanDays = 14,
    this.maximumLookbackDays = 28,
    this.closeToPlanToleranceFraction = 0.20,
  });

  final int minimumMeasurementDays;
  final int minimumSpanDays;
  final int maximumLookbackDays;

  /// 0.20 means actual pace within ±20% of plan is considered close.
  final double closeToPlanToleranceFraction;

  RecentWeightPaceResult calculate({
    required WeightGoalDirection goalDirection,
    required double? plannedPaceKgPerWeek,
    required List<WeightEntry> entries,
  }) {
    _validateConfiguration();

    if (goalDirection != WeightGoalDirection.maintain) {
      if (plannedPaceKgPerWeek == null ||
          !plannedPaceKgPerWeek.isFinite ||
          plannedPaceKgPerWeek <= 0) {
        throw ArgumentError.value(
          plannedPaceKgPerWeek,
          'plannedPaceKgPerWeek',
          'Planned pace must be greater than zero '
              'for directional weight goals.',
        );
      }
    }

    final dailyEntries = _latestEntryForEachDay(entries);

    if (dailyEntries.isEmpty) {
      return _insufficientResult(
        goalDirection: goalDirection,
        plannedPaceKgPerWeek: plannedPaceKgPerWeek,
        distinctMeasurementDays: 0,
        measurementSpanDays: 0,
      );
    }

    final recentEntries = _recentEntries(dailyEntries);

    final spanDays = recentEntries.length < 2
        ? 0
        : _calendarDayUtc(
            recentEntries.last.measuredAt,
          ).difference(_calendarDayUtc(recentEntries.first.measuredAt)).inDays;

    final enoughData =
        recentEntries.length >= minimumMeasurementDays &&
        spanDays >= minimumSpanDays;

    if (!enoughData) {
      if (goalDirection == WeightGoalDirection.maintain) {
        return RecentWeightPaceResult(
          goalDirection: goalDirection,
          plannedPaceKgPerWeek: null,
          distinctMeasurementDays: recentEntries.length,
          measurementSpanDays: spanDays,
          actualWeightChangeKgPerWeek: null,
          goalDirectedPaceKgPerWeek: null,
          status: PaceComparisonStatus.notApplicable,
        );
      }

      return _insufficientResult(
        goalDirection: goalDirection,
        plannedPaceKgPerWeek: plannedPaceKgPerWeek,
        distinctMeasurementDays: recentEntries.length,
        measurementSpanDays: spanDays,
      );
    }

    final weightChangeKgPerWeek = _calculateRegressionPace(recentEntries);

    if (goalDirection == WeightGoalDirection.maintain) {
      return RecentWeightPaceResult(
        goalDirection: goalDirection,
        plannedPaceKgPerWeek: null,
        distinctMeasurementDays: recentEntries.length,
        measurementSpanDays: spanDays,
        actualWeightChangeKgPerWeek: weightChangeKgPerWeek,
        goalDirectedPaceKgPerWeek: null,
        status: PaceComparisonStatus.notApplicable,
      );
    }

    final goalDirectedPaceKgPerWeek = switch (goalDirection) {
      WeightGoalDirection.lose => -weightChangeKgPerWeek,
      WeightGoalDirection.gain => weightChangeKgPerWeek,
      WeightGoalDirection.maintain => 0.0,
    };

    final plannedPace = plannedPaceKgPerWeek!;

    final status = _compareWithPlan(
      actualGoalDirectedPaceKgPerWeek: goalDirectedPaceKgPerWeek,
      plannedPaceKgPerWeek: plannedPace,
    );

    return RecentWeightPaceResult(
      goalDirection: goalDirection,
      plannedPaceKgPerWeek: plannedPace,
      distinctMeasurementDays: recentEntries.length,
      measurementSpanDays: spanDays,
      actualWeightChangeKgPerWeek: weightChangeKgPerWeek,
      goalDirectedPaceKgPerWeek: goalDirectedPaceKgPerWeek,
      status: status,
    );
  }

  List<WeightEntry> _latestEntryForEachDay(List<WeightEntry> entries) {
    final sortedEntries = [...entries]
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

    final latestByDay = <DateTime, WeightEntry>{};

    for (final entry in sortedEntries) {
      final day = _calendarDayUtc(entry.measuredAt);

      final existing = latestByDay[day];

      if (existing == null || !entry.measuredAt.isBefore(existing.measuredAt)) {
        latestByDay[day] = entry;
      }
    }

    final dailyEntries = latestByDay.values.toList()
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

    return dailyEntries;
  }

  List<WeightEntry> _recentEntries(List<WeightEntry> entries) {
    if (entries.isEmpty) {
      return [];
    }

    final latestDay = _calendarDayUtc(entries.last.measuredAt);

    final cutoffDay = latestDay.subtract(Duration(days: maximumLookbackDays));

    return entries.where((entry) {
      final entryDay = _calendarDayUtc(entry.measuredAt);

      return !entryDay.isBefore(cutoffDay);
    }).toList();
  }

  double _calculateRegressionPace(List<WeightEntry> entries) {
    final firstDay = _calendarDayUtc(entries.first.measuredAt);

    final xValues = entries
        .map(
          (entry) => _calendarDayUtc(
            entry.measuredAt,
          ).difference(firstDay).inDays.toDouble(),
        )
        .toList();

    final yValues = entries.map((entry) => entry.weightKg).toList();

    final xMean = xValues.reduce((a, b) => a + b) / xValues.length;

    final yMean = yValues.reduce((a, b) => a + b) / yValues.length;

    var numerator = 0.0;
    var denominator = 0.0;

    for (var index = 0; index < entries.length; index++) {
      final xDifference = xValues[index] - xMean;

      final yDifference = yValues[index] - yMean;

      numerator += xDifference * yDifference;

      denominator += math.pow(xDifference, 2).toDouble();
    }

    if (denominator == 0) {
      return 0;
    }

    final changeKgPerDay = numerator / denominator;

    return changeKgPerDay * 7;
  }

  PaceComparisonStatus _compareWithPlan({
    required double actualGoalDirectedPaceKgPerWeek,
    required double plannedPaceKgPerWeek,
  }) {
    const movingAwayTolerance = 0.01;

    if (actualGoalDirectedPaceKgPerWeek < -movingAwayTolerance) {
      return PaceComparisonStatus.movingAwayFromGoal;
    }

    final lowerBound =
        plannedPaceKgPerWeek * (1 - closeToPlanToleranceFraction);

    final upperBound =
        plannedPaceKgPerWeek * (1 + closeToPlanToleranceFraction);

    if (actualGoalDirectedPaceKgPerWeek < lowerBound) {
      return PaceComparisonStatus.slowerThanPlan;
    }

    if (actualGoalDirectedPaceKgPerWeek > upperBound) {
      return PaceComparisonStatus.fasterThanPlan;
    }

    return PaceComparisonStatus.closeToPlan;
  }

  RecentWeightPaceResult _insufficientResult({
    required WeightGoalDirection goalDirection,
    required double? plannedPaceKgPerWeek,
    required int distinctMeasurementDays,
    required int measurementSpanDays,
  }) {
    return RecentWeightPaceResult(
      goalDirection: goalDirection,
      plannedPaceKgPerWeek: plannedPaceKgPerWeek,
      distinctMeasurementDays: distinctMeasurementDays,
      measurementSpanDays: measurementSpanDays,
      actualWeightChangeKgPerWeek: null,
      goalDirectedPaceKgPerWeek: null,
      status: PaceComparisonStatus.insufficientData,
    );
  }

  DateTime _calendarDayUtc(DateTime date) {
    return DateTime.utc(date.year, date.month, date.day);
  }

  void _validateConfiguration() {
    if (minimumMeasurementDays < 2) {
      throw StateError('minimumMeasurementDays must be at least 2.');
    }

    if (minimumSpanDays <= 0) {
      throw StateError('minimumSpanDays must be greater than zero.');
    }

    if (maximumLookbackDays < minimumSpanDays) {
      throw StateError(
        'maximumLookbackDays must be greater than or equal '
        'to minimumSpanDays.',
      );
    }

    if (closeToPlanToleranceFraction < 0 || closeToPlanToleranceFraction >= 1) {
      throw StateError('closeToPlanToleranceFraction must be between 0 and 1.');
    }
  }
}
