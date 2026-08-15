import '../entities/weight_entry.dart';

class WeightTrendResult {
  const WeightTrendResult({
    required this.startingWeightKg,
    required this.goalWeightKg,
    required this.latestEntry,
    required this.trendWeightKg,
    required this.distinctMeasurementDays,
  });

  final double startingWeightKg;
  final double goalWeightKg;
  final WeightEntry? latestEntry;
  final double? trendWeightKg;
  final int distinctMeasurementDays;

  double? get latestWeightKg => latestEntry?.weightKg;

  bool get hasMeasurements => latestEntry != null;

  bool get hasReliableTrend => trendWeightKg != null;

  /// Once a reliable trend exists, progress calculations use the trend
  /// instead of reacting to the latest individual measurement.
  double? get progressWeightKg => trendWeightKg ?? latestWeightKg;

  /// Signed change from starting weight.
  ///
  /// Negative = weight decreased.
  /// Positive = weight increased.
  double? get changeFromStartKg {
    final weight = progressWeightKg;

    if (weight == null) {
      return null;
    }

    return weight - startingWeightKg;
  }

  double? get distanceToGoalKg {
    final weight = progressWeightKg;

    if (weight == null) {
      return null;
    }

    return (weight - goalWeightKg).abs();
  }
}

class WeightTrendService {
  const WeightTrendService({
    this.minimumTrendDays = 3,
    this.maximumTrendDays = 7,
  });

  final int minimumTrendDays;
  final int maximumTrendDays;

  WeightTrendResult calculate({
    required double startingWeightKg,
    required double goalWeightKg,
    required List<WeightEntry> entries,
  }) {
    if (startingWeightKg <= 0) {
      throw ArgumentError.value(
        startingWeightKg,
        'startingWeightKg',
        'Starting weight must be greater than zero.',
      );
    }

    if (goalWeightKg <= 0) {
      throw ArgumentError.value(
        goalWeightKg,
        'goalWeightKg',
        'Goal weight must be greater than zero.',
      );
    }

    if (minimumTrendDays <= 0) {
      throw StateError('minimumTrendDays must be greater than zero.');
    }

    if (maximumTrendDays < minimumTrendDays) {
      throw StateError(
        'maximumTrendDays must be greater than or equal to '
        'minimumTrendDays.',
      );
    }

    if (entries.isEmpty) {
      return WeightTrendResult(
        startingWeightKg: startingWeightKg,
        goalWeightKg: goalWeightKg,
        latestEntry: null,
        trendWeightKg: null,
        distinctMeasurementDays: 0,
      );
    }

    final sortedEntries = [...entries]
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

    final latestEntry = sortedEntries.last;

    final dailyEntries = _latestEntryForEachDay(sortedEntries);

    double? trendWeightKg;

    if (dailyEntries.length >= minimumTrendDays) {
      final trendEntries = dailyEntries.length > maximumTrendDays
          ? dailyEntries.sublist(dailyEntries.length - maximumTrendDays)
          : dailyEntries;

      final totalWeight = trendEntries.fold<double>(
        0,
        (sum, entry) => sum + entry.weightKg,
      );

      trendWeightKg = totalWeight / trendEntries.length;
    }

    return WeightTrendResult(
      startingWeightKg: startingWeightKg,
      goalWeightKg: goalWeightKg,
      latestEntry: latestEntry,
      trendWeightKg: trendWeightKg,
      distinctMeasurementDays: dailyEntries.length,
    );
  }

  List<WeightEntry> _latestEntryForEachDay(List<WeightEntry> sortedEntries) {
    final entriesByDay = <DateTime, WeightEntry>{};

    for (final entry in sortedEntries) {
      final day = DateTime(
        entry.measuredAt.year,
        entry.measuredAt.month,
        entry.measuredAt.day,
      );

      final existing = entriesByDay[day];

      if (existing == null || !entry.measuredAt.isBefore(existing.measuredAt)) {
        entriesByDay[day] = entry;
      }
    }

    final dailyEntries = entriesByDay.values.toList()
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

    return dailyEntries;
  }
}
