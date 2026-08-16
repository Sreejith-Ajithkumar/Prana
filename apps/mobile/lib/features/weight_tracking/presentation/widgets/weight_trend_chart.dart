import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../domain/entities/weight_entry.dart';

class WeightTrendChart extends StatelessWidget {
  const WeightTrendChart({
    super.key,
    required this.entries,
    required this.goalWeightKg,
    this.minimumTrendDays = 3,
    this.maximumTrendDays = 7,
    this.maximumDisplayedDays = 14,
  });

  final List<WeightEntry> entries;
  final double goalWeightKg;
  final int minimumTrendDays;
  final int maximumTrendDays;
  final int maximumDisplayedDays;

  @override
  Widget build(BuildContext context) {
    final dailyPoints = _buildDailyPoints(entries);

    if (dailyPoints.isEmpty) {
      return const SizedBox.shrink();
    }

    final trendValues = _buildTrendValues(dailyPoints);

    final startIndex = math.max(0, dailyPoints.length - maximumDisplayedDays);

    final displayedPoints = dailyPoints.sublist(startIndex);
    final displayedTrendValues = trendValues.sublist(startIndex);

    final goalDecision = _evaluateGoalRange(
      displayedPoints,
      displayedTrendValues,
      goalWeightKg,
    );

    final colorScheme = Theme.of(context).colorScheme;

    return Semantics(
      image: true,
      label: _buildSemanticLabel(displayedPoints, displayedTrendValues),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 250,
            width: double.infinity,
            child: CustomPaint(
              painter: _WeightTrendChartPainter(
                points: displayedPoints,
                trendValues: displayedTrendValues,
                goalWeightKg: goalWeightKg,
                includeGoalInScale: goalDecision.includeInScale,
                actualColor: colorScheme.onSurfaceVariant,
                trendColor: colorScheme.primary,
                goalColor: colorScheme.tertiary,
                gridColor: colorScheme.outlineVariant,
                textColor: colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 18,
            runSpacing: 8,
            children: [
              _ChartLegendItem(
                color: colorScheme.onSurfaceVariant,
                label: 'Daily weight',
              ),
              _ChartLegendItem(
                color: colorScheme.primary,
                label: 'Trend',
                thick: true,
              ),
              _ChartLegendItem(
                color: colorScheme.tertiary,
                label: 'Goal',
                dashed: true,
              ),
            ],
          ),
          if (!goalDecision.includeInScale) ...[
            const SizedBox(height: 14),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  goalDecision.goalBelowRange
                      ? Icons.arrow_downward
                      : Icons.arrow_upward,
                  size: 18,
                  color: colorScheme.tertiary,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Goal ${goalWeightKg.toStringAsFixed(1)} kg is '
                    '${goalDecision.goalBelowRange ? 'below' : 'above'} '
                    'the current chart range.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  List<_DailyWeightPoint> _buildDailyPoints(List<WeightEntry> entries) {
    final sortedEntries = [...entries]
      ..sort((a, b) => a.measuredAt.compareTo(b.measuredAt));

    final latestByDay = <DateTime, WeightEntry>{};

    for (final entry in sortedEntries) {
      final day = DateTime(
        entry.measuredAt.year,
        entry.measuredAt.month,
        entry.measuredAt.day,
      );

      final existing = latestByDay[day];

      if (existing == null || !entry.measuredAt.isBefore(existing.measuredAt)) {
        latestByDay[day] = entry;
      }
    }

    final points =
        latestByDay.entries
            .map(
              (entry) => _DailyWeightPoint(
                date: entry.key,
                weightKg: entry.value.weightKg,
              ),
            )
            .toList()
          ..sort((a, b) => a.date.compareTo(b.date));

    return points;
  }

  List<double?> _buildTrendValues(List<_DailyWeightPoint> points) {
    final trendValues = <double?>[];

    for (var index = 0; index < points.length; index++) {
      final measurementCount = index + 1;

      if (measurementCount < minimumTrendDays) {
        trendValues.add(null);
        continue;
      }

      final trendStartIndex = math.max(0, measurementCount - maximumTrendDays);

      final trendPoints = points.sublist(trendStartIndex, index + 1);

      final totalWeight = trendPoints.fold<double>(
        0,
        (sum, point) => sum + point.weightKg,
      );

      trendValues.add(totalWeight / trendPoints.length);
    }

    return trendValues;
  }

  _GoalRangeDecision _evaluateGoalRange(
    List<_DailyWeightPoint> points,
    List<double?> trendValues,
    double goalWeight,
  ) {
    final values = <double>[
      ...points.map((point) => point.weightKg),
      ...trendValues.whereType<double>(),
    ];

    var minimum = values.reduce(math.min);
    var maximum = values.reduce(math.max);

    var range = maximum - minimum;

    if (range < 1) {
      final middle = (minimum + maximum) / 2;

      minimum = middle - 0.5;
      maximum = middle + 0.5;
      range = 1;
    }

    final goalBelowRange = goalWeight < minimum;
    final goalAboveRange = goalWeight > maximum;

    final goalDistance = goalBelowRange
        ? minimum - goalWeight
        : goalAboveRange
        ? goalWeight - maximum
        : 0.0;

    final allowedDistance = math.max(2.0, range * 1.5);

    return _GoalRangeDecision(
      includeInScale: goalDistance == 0 || goalDistance <= allowedDistance,
      goalBelowRange: goalBelowRange,
    );
  }

  String _buildSemanticLabel(
    List<_DailyWeightPoint> points,
    List<double?> trendValues,
  ) {
    final latest = points.last;

    double? latestTrend;

    for (final value in trendValues.reversed) {
      if (value != null) {
        latestTrend = value;
        break;
      }
    }

    final buffer = StringBuffer(
      'Weight history chart. '
      'Latest daily weight '
      '${latest.weightKg.toStringAsFixed(1)} kilograms.',
    );

    if (latestTrend != null) {
      buffer.write(
        ' Current trend '
        '${latestTrend.toStringAsFixed(1)} kilograms.',
      );
    }

    buffer.write(
      ' Goal weight '
      '${goalWeightKg.toStringAsFixed(1)} kilograms.',
    );

    return buffer.toString();
  }
}

class _WeightTrendChartPainter extends CustomPainter {
  const _WeightTrendChartPainter({
    required this.points,
    required this.trendValues,
    required this.goalWeightKg,
    required this.includeGoalInScale,
    required this.actualColor,
    required this.trendColor,
    required this.goalColor,
    required this.gridColor,
    required this.textColor,
  });

  final List<_DailyWeightPoint> points;
  final List<double?> trendValues;

  final double goalWeightKg;
  final bool includeGoalInScale;

  final Color actualColor;
  final Color trendColor;
  final Color goalColor;
  final Color gridColor;
  final Color textColor;

  static const double _leftPadding = 46;
  static const double _rightPadding = 12;
  static const double _topPadding = 14;
  static const double _bottomPadding = 34;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      return;
    }

    final plotRect = Rect.fromLTRB(
      _leftPadding,
      _topPadding,
      size.width - _rightPadding,
      size.height - _bottomPadding,
    );

    if (plotRect.width <= 0 || plotRect.height <= 0) {
      return;
    }

    final visibleValues = <double>[
      ...points.map((point) => point.weightKg),
      ...trendValues.whereType<double>(),
    ];

    var minimumWeight = visibleValues.reduce(math.min);
    var maximumWeight = visibleValues.reduce(math.max);

    final initialRange = maximumWeight - minimumWeight;

    if (initialRange < 1) {
      final middle = (maximumWeight + minimumWeight) / 2;

      minimumWeight = middle - 0.5;
      maximumWeight = middle + 0.5;
    }

    if (includeGoalInScale) {
      minimumWeight = math.min(minimumWeight, goalWeightKg);

      maximumWeight = math.max(maximumWeight, goalWeightKg);
    }

    final range = maximumWeight - minimumWeight;

    final verticalPadding = math.max(0.35, range * 0.12);

    minimumWeight -= verticalPadding;
    maximumWeight += verticalPadding;

    _drawGrid(canvas, plotRect, minimumWeight, maximumWeight);

    if (includeGoalInScale) {
      _drawGoalLine(canvas, plotRect, minimumWeight, maximumWeight);
    }

    final actualOffsets = points
        .map(
          (point) => Offset(
            _xForDate(point.date, plotRect),
            _yForWeight(point.weightKg, plotRect, minimumWeight, maximumWeight),
          ),
        )
        .toList();

    _drawActualWeight(canvas, actualOffsets);

    _drawTrend(canvas, plotRect, minimumWeight, maximumWeight);

    _drawDateLabels(canvas, plotRect);
  }

  void _drawGrid(
    Canvas canvas,
    Rect plotRect,
    double minimumWeight,
    double maximumWeight,
  ) {
    const lineCount = 4;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;

    for (var index = 0; index <= lineCount; index++) {
      final fraction = index / lineCount;

      final y = plotRect.top + (plotRect.height * fraction);

      canvas.drawLine(
        Offset(plotRect.left, y),
        Offset(plotRect.right, y),
        gridPaint,
      );

      final weight =
          maximumWeight - ((maximumWeight - minimumWeight) * fraction);

      _paintText(
        canvas,
        weight.toStringAsFixed(1),
        Offset(0, y - 7),
        fontSize: 10,
        maxWidth: _leftPadding - 6,
        textAlign: TextAlign.right,
      );
    }
  }

  void _drawGoalLine(
    Canvas canvas,
    Rect plotRect,
    double minimumWeight,
    double maximumWeight,
  ) {
    final y = _yForWeight(goalWeightKg, plotRect, minimumWeight, maximumWeight);

    final paint = Paint()
      ..color = goalColor
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    _drawDashedLine(
      canvas,
      Offset(plotRect.left, y),
      Offset(plotRect.right, y),
      paint,
    );

    _paintText(
      canvas,
      'Goal ${goalWeightKg.toStringAsFixed(1)}',
      Offset(plotRect.left + 4, y - 17),
      fontSize: 10,
      color: goalColor,
    );
  }

  void _drawActualWeight(Canvas canvas, List<Offset> offsets) {
    if (offsets.isEmpty) {
      return;
    }

    final linePaint = Paint()
      ..color = actualColor
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (offsets.length > 1) {
      final path = Path()..moveTo(offsets.first.dx, offsets.first.dy);

      for (final offset in offsets.skip(1)) {
        path.lineTo(offset.dx, offset.dy);
      }

      canvas.drawPath(path, linePaint);
    }

    final pointPaint = Paint()
      ..color = actualColor
      ..style = PaintingStyle.fill;

    for (final offset in offsets) {
      canvas.drawCircle(offset, 3.5, pointPaint);
    }
  }

  void _drawTrend(
    Canvas canvas,
    Rect plotRect,
    double minimumWeight,
    double maximumWeight,
  ) {
    final trendOffsets = <Offset>[];

    for (var index = 0; index < points.length; index++) {
      final trendValue = trendValues[index];

      if (trendValue == null) {
        continue;
      }

      trendOffsets.add(
        Offset(
          _xForDate(points[index].date, plotRect),
          _yForWeight(trendValue, plotRect, minimumWeight, maximumWeight),
        ),
      );
    }

    if (trendOffsets.isEmpty) {
      return;
    }

    final trendPaint = Paint()
      ..color = trendColor
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    if (trendOffsets.length > 1) {
      final path = Path()..moveTo(trendOffsets.first.dx, trendOffsets.first.dy);

      for (final offset in trendOffsets.skip(1)) {
        path.lineTo(offset.dx, offset.dy);
      }

      canvas.drawPath(path, trendPaint);
    }

    final pointPaint = Paint()
      ..color = trendColor
      ..style = PaintingStyle.fill;

    for (final offset in trendOffsets) {
      canvas.drawCircle(offset, 4, pointPaint);
    }
  }

  void _drawDateLabels(Canvas canvas, Rect plotRect) {
    if (points.isEmpty) {
      return;
    }

    final indexes = <int>{0, points.length ~/ 2, points.length - 1}.toList()
      ..sort();

    for (final index in indexes) {
      final point = points[index];

      final x = _xForDate(point.date, plotRect);

      final label = _formatShortDate(point.date);

      const labelWidth = 44.0;

      final proposedLeft = x - (labelWidth / 2);

      final left = proposedLeft
          .clamp(plotRect.left, plotRect.right - labelWidth)
          .toDouble();

      _paintText(
        canvas,
        label,
        Offset(left, plotRect.bottom + 8),
        fontSize: 10,
        maxWidth: labelWidth,
        textAlign: TextAlign.center,
      );
    }
  }

  double _xForDate(DateTime date, Rect plotRect) {
    if (points.length == 1) {
      return plotRect.center.dx;
    }

    final firstDate = points.first.date;
    final lastDate = points.last.date;

    final totalDays = math.max(1, lastDate.difference(firstDate).inDays);

    final elapsedDays = date.difference(firstDate).inDays;

    final fraction = elapsedDays / totalDays;

    return plotRect.left + (plotRect.width * fraction);
  }

  double _yForWeight(
    double weight,
    Rect plotRect,
    double minimumWeight,
    double maximumWeight,
  ) {
    final range = maximumWeight - minimumWeight;

    if (range <= 0) {
      return plotRect.center.dy;
    }

    final normalized = (weight - minimumWeight) / range;

    return plotRect.bottom - (plotRect.height * normalized);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 6.0;
    const dashGap = 4.0;

    final totalWidth = end.dx - start.dx;

    var x = 0.0;

    while (x < totalWidth) {
      final dashEnd = math.min(x + dashWidth, totalWidth);

      canvas.drawLine(
        Offset(start.dx + x, start.dy),
        Offset(start.dx + dashEnd, end.dy),
        paint,
      );

      x += dashWidth + dashGap;
    }
  }

  void _paintText(
    Canvas canvas,
    String text,
    Offset offset, {
    double fontSize = 11,
    Color? color,
    double? maxWidth,
    TextAlign textAlign = TextAlign.left,
  }) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, color: color ?? textColor),
      ),
      textDirection: TextDirection.ltr,
      textAlign: textAlign,
      maxLines: 1,
    );

    painter.layout(minWidth: 0, maxWidth: maxWidth ?? double.infinity);

    painter.paint(canvas, offset);

    painter.dispose();
  }

  String _formatShortDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '$month/$day';
  }

  @override
  bool shouldRepaint(covariant _WeightTrendChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.trendValues != trendValues ||
        oldDelegate.goalWeightKg != goalWeightKg ||
        oldDelegate.includeGoalInScale != includeGoalInScale ||
        oldDelegate.actualColor != actualColor ||
        oldDelegate.trendColor != trendColor ||
        oldDelegate.goalColor != goalColor ||
        oldDelegate.gridColor != gridColor ||
        oldDelegate.textColor != textColor;
  }
}

class _DailyWeightPoint {
  const _DailyWeightPoint({required this.date, required this.weightKg});

  final DateTime date;
  final double weightKg;
}

class _GoalRangeDecision {
  const _GoalRangeDecision({
    required this.includeInScale,
    required this.goalBelowRange,
  });

  final bool includeInScale;
  final bool goalBelowRange;
}

class _ChartLegendItem extends StatelessWidget {
  const _ChartLegendItem({
    required this.color,
    required this.label,
    this.thick = false,
    this.dashed = false,
  });

  final Color color;
  final String label;
  final bool thick;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 24,
          height: 10,
          child: CustomPaint(
            painter: _LegendPainter(color: color, thick: thick, dashed: dashed),
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _LegendPainter extends CustomPainter {
  const _LegendPainter({
    required this.color,
    required this.thick,
    required this.dashed,
  });

  final Color color;
  final bool thick;
  final bool dashed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = thick ? 3 : 1.5
      ..strokeCap = StrokeCap.round;

    final y = size.height / 2;

    if (!dashed) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);

      return;
    }

    const dashWidth = 5.0;
    const gap = 3.0;

    var x = 0.0;

    while (x < size.width) {
      canvas.drawLine(
        Offset(x, y),
        Offset(math.min(x + dashWidth, size.width), y),
        paint,
      );

      x += dashWidth + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _LegendPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.thick != thick ||
        oldDelegate.dashed != dashed;
  }
}
