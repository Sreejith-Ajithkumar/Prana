import 'package:flutter/material.dart';

import '../../../profile/data/profile_storage.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../data/goal_pace_storage.dart';
import '../../data/weight_storage.dart';
import '../../domain/entities/weight_entry.dart';
import '../../domain/services/goal_pace_service.dart';
import '../../domain/services/recent_weight_pace_service.dart';
import '../../domain/services/weight_trend_service.dart';
import '../widgets/weight_trend_chart.dart';

class WeightTrackingScreen extends StatefulWidget {
  const WeightTrackingScreen({super.key, this.embedded = false});

  final bool embedded;

  @override
  State<WeightTrackingScreen> createState() => _WeightTrackingScreenState();
}

class _WeightTrackingScreenState extends State<WeightTrackingScreen>
    with AutomaticKeepAliveClientMixin {
  static const WeightTrendService _trendService = WeightTrendService();

  static const GoalPaceService _goalPaceService = GoalPaceService();

  static const RecentWeightPaceService _recentPaceService =
      RecentWeightPaceService();

  UserProfile? _profile;
  List<WeightEntry> _entries = [];

  double? _weeklyPaceKg;

  bool _isLoading = true;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profile = await ProfileStorage.instance.loadProfile();

    final entries = await WeightStorage.instance.loadEntries();

    double? weeklyPaceKg;

    if (profile != null) {
      final trendResult = _trendService.calculate(
        startingWeightKg: profile.weightKg,
        goalWeightKg: profile.goalWeightKg,
        entries: entries,
      );

      final direction = trendResult.goalDirection;

      if (direction != WeightGoalDirection.maintain) {
        final storedPace = await GoalPaceStorage.instance.loadWeeklyPace(
          direction,
        );

        weeklyPaceKg = _validatedPace(storedPace, direction);
      }
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _profile = profile;
      _entries = entries;
      _weeklyPaceKg = weeklyPaceKg;
      _isLoading = false;
    });
  }

  double _validatedPace(double? pace, WeightGoalDirection direction) {
    final config = _paceConfig(direction);

    if (pace == null || pace < config.minimum || pace > config.maximum) {
      return config.defaultValue;
    }

    return pace;
  }

  Future<void> _saveGoalPace(
    WeightGoalDirection direction,
    double value,
  ) async {
    await GoalPaceStorage.instance.saveWeeklyPace(direction, value);
  }

  Future<void> _addWeight() async {
    String input = '';
    String? errorText;

    final weight = await showDialog<double>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            void saveWeight() {
              final normalizedInput = input.trim().replaceAll(',', '.');

              final parsed = double.tryParse(normalizedInput);

              if (parsed == null || parsed <= 0) {
                setDialogState(() {
                  errorText = 'Enter a valid weight.';
                });

                return;
              }

              Navigator.of(dialogContext).pop(parsed);
            }

            return AlertDialog(
              title: const Text('Log weight'),
              content: TextField(
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                decoration: InputDecoration(
                  labelText: 'Weight',
                  suffixText: 'kg',
                  errorText: errorText,
                  helperText: 'Enter your current measured weight.',
                ),
                onChanged: (value) {
                  input = value;

                  if (errorText != null) {
                    setDialogState(() {
                      errorText = null;
                    });
                  }
                },
                onSubmitted: (_) {
                  saveWeight();
                },
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Cancel'),
                ),
                FilledButton(onPressed: saveWeight, child: const Text('Save')),
              ],
            );
          },
        );
      },
    );

    if (weight == null || !mounted) {
      return;
    }

    final now = DateTime.now();

    final entry = WeightEntry(
      id: now.microsecondsSinceEpoch.toString(),
      weightKg: weight,
      measuredAt: now,
      source: WeightSource.manual,
    );

    await WeightStorage.instance.addEntry(entry);

    if (!mounted) {
      return;
    }

    await _loadData();
  }

  Future<void> _deleteEntry(WeightEntry entry) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete weight?'),
          content: Text(
            'Delete ${entry.weightKg.toStringAsFixed(1)} kg '
            'from ${_formatDateTime(entry.measuredAt)}?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(dialogContext).pop(true);
              },
              style: TextButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true || !mounted) {
      return;
    }

    await WeightStorage.instance.deleteEntry(entry.id);

    if (!mounted) {
      return;
    }

    await _loadData();
  }

  WeightTrendResult? _calculateTrend() {
    final profile = _profile;

    if (profile == null) {
      return null;
    }

    return _trendService.calculate(
      startingWeightKg: profile.weightKg,
      goalWeightKg: profile.goalWeightKg,
      entries: _entries,
    );
  }

  String _formatDateTime(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');

    final day = date.day.toString().padLeft(2, '0');

    final hour = date.hour.toString().padLeft(2, '0');

    final minute = date.minute.toString().padLeft(2, '0');

    return '${date.year}-$month-$day $hour:$minute';
  }

  String _formatTargetDate(DateTime date) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];

    return '${months[date.month - 1]} '
        '${date.day}, ${date.year}';
  }

  String _formatWeight(double? value) {
    if (value == null) {
      return '--';
    }

    return '${value.toStringAsFixed(1)} kg';
  }

  String _formatSource(WeightSource source) {
    return switch (source) {
      WeightSource.manual => 'Manual',
      WeightSource.appleHealth => 'Apple Health',
      WeightSource.healthConnect => 'Health Connect',
      WeightSource.smartScale => 'Smart scale',
      WeightSource.unknown => 'Unknown source',
    };
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final content = _buildContent();

    if (widget.embedded) {
      return Stack(
        children: [
          Positioned.fill(child: content),
          if (!_isLoading)
            Positioned(
              right: 16,
              bottom: 16,
              child: SafeArea(
                top: false,
                child: FloatingActionButton.extended(
                  heroTag: 'progress-log-weight',
                  onPressed: _addWeight,
                  icon: const Icon(Icons.add),
                  label: const Text('Log weight'),
                ),
              ),
            ),
        ],
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Weight & Progress')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'weight-screen-log-weight',
        onPressed: _addWeight,
        icon: const Icon(Icons.add),
        label: const Text('Log weight'),
      ),
      body: content,
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _loadData,
      child: ListView(
        key: const PageStorageKey<String>('weight-progress-scroll'),
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.fromLTRB(16, 16, 16, widget.embedded ? 132 : 112),
        children: [
          _buildProgressCard(),
          const SizedBox(height: 16),
          _buildGoalProgressCard(),
          const SizedBox(height: 16),
          _buildGoalPaceCard(),
          const SizedBox(height: 16),
          _buildTrendCard(),
          const SizedBox(height: 16),
          _buildChartCard(),
          const SizedBox(height: 24),
          Text(
            'History',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (_entries.isEmpty)
            _buildEmptyState()
          else
            ..._entries.reversed.map(_buildEntryTile),
        ],
      ),
    );
  }

  Widget _buildProgressCard() {
    final profile = _profile;
    final result = _calculateTrend();

    if (profile == null || result == null) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('Profile information is unavailable.'),
        ),
      );
    }

    final changeFromStart = result.changeFromStartKg;

    final distanceToGoal = result.distanceToGoalKg;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your progress',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            LayoutBuilder(
              builder: (context, constraints) {
                const spacing = 16.0;

                final columnCount = constraints.maxWidth >= 520
                    ? 3
                    : constraints.maxWidth >= 260
                    ? 2
                    : 1;

                final itemWidth =
                    (constraints.maxWidth - (spacing * (columnCount - 1))) /
                    columnCount;

                return Wrap(
                  spacing: spacing,
                  runSpacing: 20,
                  children: [
                    SizedBox(
                      width: itemWidth,
                      child: _SummaryValue(
                        label: 'Starting weight',
                        value: _formatWeight(profile.weightKg),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _SummaryValue(
                        label: 'Latest weight',
                        value: _formatWeight(result.latestWeightKg),
                      ),
                    ),
                    SizedBox(
                      width: itemWidth,
                      child: _SummaryValue(
                        label: 'Goal weight',
                        value: _formatWeight(profile.goalWeightKg),
                      ),
                    ),
                  ],
                );
              },
            ),
            if (changeFromStart != null) ...[
              const SizedBox(height: 24),
              _ProgressMessage(
                icon: _changeIcon(changeFromStart),
                title: _changeFromStartText(changeFromStart),
                subtitle: result.hasReliableTrend
                    ? 'Based on your weight trend'
                    : 'Based on your latest measurement',
              ),
            ],
            if (distanceToGoal != null) ...[
              const SizedBox(height: 12),
              _ProgressMessage(
                icon: result.hasReachedGoal
                    ? Icons.emoji_events_outlined
                    : Icons.flag_outlined,
                title: result.hasReachedGoal
                    ? 'Goal weight reached'
                    : '${distanceToGoal.toStringAsFixed(1)} kg to goal',
                subtitle: result.hasReliableTrend
                    ? 'Using your trend weight'
                    : 'Using your latest measurement',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildGoalProgressCard() {
    final result = _calculateTrend();

    if (result == null || !result.hasMeasurements) {
      return const SizedBox.shrink();
    }

    if (result.goalDirection == WeightGoalDirection.maintain) {
      final distance = result.distanceToGoalKg ?? 0;

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.track_changes_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Goal progress',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              if (result.hasReachedGoal)
                const _ProgressMessage(
                  icon: Icons.check_circle_outline,
                  title: 'At maintenance target',
                  subtitle:
                      'Your current progress weight is close to your target.',
                )
              else
                _ProgressMessage(
                  icon: Icons.balance_outlined,
                  title:
                      '${distance.toStringAsFixed(1)} kg from maintenance target',
                  subtitle:
                      'Your goal is to remain close to your target weight.',
                ),
            ],
          ),
        ),
      );
    }

    final percentage = result.progressPercentage ?? 0;

    final fraction = result.progressFraction ?? 0;

    final rawProgressKg = result.progressTowardGoalKg ?? 0;

    final displayedProgressKg = rawProgressKg < 0 ? 0.0 : rawProgressKg;

    final distanceToGoal = result.distanceToGoalKg ?? 0;

    final movingAwayFromGoal = rawProgressKg < 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.track_changes_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Goal progress',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Text(
                  '${percentage.toStringAsFixed(0)}%',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            LinearProgressIndicator(
              value: fraction,
              minHeight: 10,
              borderRadius: BorderRadius.circular(999),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _SummaryValue(
                    label: 'Progress',
                    value: '${displayedProgressKg.toStringAsFixed(1)} kg',
                  ),
                ),
                Expanded(
                  child: _SummaryValue(
                    label: result.hasReachedGoal ? 'Status' : 'Remaining',
                    value: result.hasReachedGoal
                        ? 'Reached'
                        : '${distanceToGoal.toStringAsFixed(1)} kg',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Start ${result.startingWeightKg.toStringAsFixed(1)} kg',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
                Text(
                  'Goal ${result.goalWeightKg.toStringAsFixed(1)} kg',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            if (movingAwayFromGoal) ...[
              const SizedBox(height: 16),
              const _ProgressNotice(
                icon: Icons.info_outline,
                text:
                    'Your recent weight is currently moving away from '
                    'your goal. Goal progress stays at 0% until your '
                    'progress weight moves back toward the target.',
              ),
            ],
            if (result.hasReachedGoal) ...[
              const SizedBox(height: 16),
              const _ProgressNotice(
                icon: Icons.emoji_events_outlined,
                text:
                    'You have reached or passed your selected goal '
                    'weight. You can maintain this goal or choose a '
                    'new target from your profile.',
              ),
            ],
            const SizedBox(height: 14),
            Text(
              result.hasReliableTrend
                  ? 'Goal progress is based on your weight trend rather '
                        'than a single weigh-in.'
                  : 'Until a reliable trend is available, goal progress '
                        'uses your latest measurement.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGoalPaceCard() {
    final result = _calculateTrend();

    if (result == null) {
      return const SizedBox.shrink();
    }

    if (result.goalDirection == WeightGoalDirection.maintain) {
      return _buildMaintenancePaceCard(result);
    }

    final config = _paceConfig(result.goalDirection);

    final pace = (_weeklyPaceKg ?? config.defaultValue)
        .clamp(config.minimum, config.maximum)
        .toDouble();

    final currentWeight = result.progressWeightKg ?? result.startingWeightKg;

    final paceResult = _goalPaceService.calculate(
      goalDirection: result.goalDirection,
      currentWeightKg: currentWeight,
      goalWeightKg: result.goalWeightKg,
      weeklyPaceKg: pace,
      fromDate: DateTime.now(),
    );

    final recentPaceResult = _recentPaceService.calculate(
      goalDirection: result.goalDirection,
      plannedPaceKgPerWeek: pace,
      entries: _entries,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Goal pace',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),

            if (paceResult.goalReached) ...[
              Text(
                'Goal reached',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'No target date estimate is needed while your '
                'progress weight is at or beyond your selected goal.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ] else ...[
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Planned pace',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  Text(
                    '${pace.toStringAsFixed(2)} kg/week',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              Slider(
                value: pace,
                min: config.minimum,
                max: config.maximum,
                divisions: config.divisions,
                label: '${pace.toStringAsFixed(2)} kg/week',
                onChanged: (value) {
                  setState(() {
                    _weeklyPaceKg = value;
                  });
                },
                onChangeEnd: (value) {
                  _saveGoalPace(result.goalDirection, value);
                },
              ),

              Row(
                children: [
                  Text('Slower', style: Theme.of(context).textTheme.bodySmall),
                  const Spacer(),
                  Text('Faster', style: Theme.of(context).textTheme.bodySmall),
                ],
              ),

              const SizedBox(height: 22),

              Text(
                'Estimated target date',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 4),

              Text(
                paceResult.estimatedTargetDate == null
                    ? '--'
                    : _formatTargetDate(paceResult.estimatedTargetDate!),
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: _SummaryValue(
                      label: 'Remaining',
                      value: '${paceResult.remainingKg.toStringAsFixed(1)} kg',
                    ),
                  ),
                  Expanded(
                    child: _SummaryValue(
                      label: 'Estimated time',
                      value: paceResult.estimatedWeeksRemaining == null
                          ? '--'
                          : '${paceResult.estimatedWeeksRemaining!.toStringAsFixed(1)} weeks',
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              _ProgressNotice(
                icon: Icons.info_outline,
                text: result.hasReliableTrend
                    ? 'This estimate uses your current weight trend. '
                          'The date will move as your trend and selected '
                          'pace change.'
                    : result.hasMeasurements
                    ? 'This estimate currently uses your latest '
                          'measurement. Once Prana has a reliable trend, '
                          'the estimate will use that instead.'
                    : 'This estimate currently uses your starting '
                          'weight. It will become more useful after you '
                          'begin logging measurements.',
              ),

              const SizedBox(height: 12),

              Text(
                'Target dates are planning estimates. Real weight '
                'change may not follow a perfectly steady weekly pace.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],

            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 20),

            _buildRecentPaceSection(recentPaceResult),
          ],
        ),
      ),
    );
  }

  Widget _buildMaintenancePaceCard(WeightTrendResult trendResult) {
    final recentPaceResult = _recentPaceService.calculate(
      goalDirection: WeightGoalDirection.maintain,
      plannedPaceKgPerWeek: null,
      entries: _entries,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calendar_month_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Goal pace',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              'Maintenance goal',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'A target date is not needed for a maintenance '
              'goal. Prana will focus on how closely your trend '
              'stays around your target weight.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 20),
            _buildMaintenanceRecentPace(recentPaceResult),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentPaceSection(RecentWeightPaceResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.speed_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              'Recent pace',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 18),

        if (!result.hasReliablePace)
          _buildRecentPacePending(result)
        else
          _buildReliableRecentPace(result),
      ],
    );
  }

  Widget _buildRecentPacePending(RecentWeightPaceResult result) {
    final requiredDays = _recentPaceService.minimumSpanDays;

    final daysRemaining = (requiredDays - result.measurementSpanDays).clamp(
      0,
      requiredDays,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'More data needed',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _SummaryValue(
                label: 'Measurement days',
                value: '${result.distinctMeasurementDays}',
              ),
            ),
            Expanded(
              child: _SummaryValue(
                label: 'History span',
                value: '${result.measurementSpanDays} days',
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),
        _ProgressNotice(
          icon: Icons.hourglass_empty_outlined,
          text: daysRemaining > 0
              ? 'Prana waits for at least $requiredDays days of '
                    'history before comparing your recent pace with '
                    'your plan. About $daysRemaining more '
                    '${daysRemaining == 1 ? 'day' : 'days'} of span '
                    'are needed.'
              : 'Prana also needs measurements on at least '
                    '${_recentPaceService.minimumMeasurementDays} '
                    'different days before estimating recent pace.',
        ),
        const SizedBox(height: 12),
        Text(
          'Short-term weight changes can be heavily affected by '
          'normal fluctuations, so Prana avoids turning only a few '
          'days of measurements into a weekly pace.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildReliableRecentPace(RecentWeightPaceResult result) {
    final recentPace = result.goalDirectedPaceKgPerWeek ?? 0;

    final plannedPace = result.plannedPaceKgPerWeek ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: _SummaryValue(
                label: 'Planned pace',
                value: '${plannedPace.toStringAsFixed(2)} kg/week',
              ),
            ),
            Expanded(
              child: _SummaryValue(
                label: 'Recent pace',
                value: _recentPaceValueText(result),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        _ProgressMessage(
          icon: _recentPaceStatusIcon(result.status),
          title: _recentPaceStatusTitle(result.status),
          subtitle: _recentPaceStatusSubtitle(
            result.status,
            recentPace,
            plannedPace,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Based on ${result.distinctMeasurementDays} measurement '
          'days across ${result.measurementSpanDays} days of recent '
          'history.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Recent pace is informational and does not automatically '
          'change your nutrition targets or planned pace.',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }

  Widget _buildMaintenanceRecentPace(RecentWeightPaceResult result) {
    if (!result.hasReliablePace) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.speed_outlined,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 12),
              Text(
                'Recent drift',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildRecentPacePending(result),
        ],
      );
    }

    final change = result.actualWeightChangeKgPerWeek ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.speed_outlined,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 12),
            Text(
              'Recent drift',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 18),
        Text(
          _maintenanceDriftText(change),
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          'Based on ${result.distinctMeasurementDays} measurement '
          'days across ${result.measurementSpanDays} days.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 16),
        const _ProgressNotice(
          icon: Icons.info_outline,
          text:
              'For a maintenance goal, Prana tracks whether your '
              'weight is drifting up or down rather than comparing '
              'you with a planned weekly pace.',
        ),
      ],
    );
  }

  String _recentPaceValueText(RecentWeightPaceResult result) {
    final value = result.goalDirectedPaceKgPerWeek;

    if (value == null) {
      return '--';
    }

    if (result.status == PaceComparisonStatus.movingAwayFromGoal) {
      return '${value.abs().toStringAsFixed(2)} kg/week away';
    }

    return '${value.abs().toStringAsFixed(2)} kg/week';
  }

  String _recentPaceStatusTitle(PaceComparisonStatus status) {
    return switch (status) {
      PaceComparisonStatus.closeToPlan => 'Close to plan',
      PaceComparisonStatus.slowerThanPlan => 'Slower than plan',
      PaceComparisonStatus.fasterThanPlan => 'Faster than plan',
      PaceComparisonStatus.movingAwayFromGoal => 'Moving away from goal',
      PaceComparisonStatus.insufficientData => 'More data needed',
      PaceComparisonStatus.notApplicable => 'No pace comparison',
    };
  }

  String _recentPaceStatusSubtitle(
    PaceComparisonStatus status,
    double recentPace,
    double plannedPace,
  ) {
    return switch (status) {
      PaceComparisonStatus.closeToPlan =>
        'Your recent trend is reasonably close to your '
            'selected weekly pace.',

      PaceComparisonStatus.slowerThanPlan =>
        'Your recent trend is progressing more slowly than '
            'your selected ${plannedPace.toStringAsFixed(2)} kg/week pace.',

      PaceComparisonStatus.fasterThanPlan =>
        'Your recent trend is progressing faster than your '
            'selected ${plannedPace.toStringAsFixed(2)} kg/week pace.',

      PaceComparisonStatus.movingAwayFromGoal =>
        'Your recent trend is moving about '
            '${recentPace.abs().toStringAsFixed(2)} kg/week away '
            'from your selected goal direction.',

      PaceComparisonStatus.insufficientData =>
        'Keep logging measurements to build a reliable comparison.',

      PaceComparisonStatus.notApplicable =>
        'A directional pace comparison is not needed.',
    };
  }

  IconData _recentPaceStatusIcon(PaceComparisonStatus status) {
    return switch (status) {
      PaceComparisonStatus.closeToPlan => Icons.check_circle_outline,

      PaceComparisonStatus.slowerThanPlan => Icons.trending_down,

      PaceComparisonStatus.fasterThanPlan => Icons.trending_up,

      PaceComparisonStatus.movingAwayFromGoal => Icons.swap_vert,

      PaceComparisonStatus.insufficientData => Icons.hourglass_empty_outlined,

      PaceComparisonStatus.notApplicable => Icons.horizontal_rule,
    };
  }

  String _maintenanceDriftText(double weightChangeKgPerWeek) {
    const stableTolerance = 0.01;

    if (weightChangeKgPerWeek > stableTolerance) {
      return '${weightChangeKgPerWeek.toStringAsFixed(2)} '
          'kg/week upward';
    }

    if (weightChangeKgPerWeek < -stableTolerance) {
      return '${weightChangeKgPerWeek.abs().toStringAsFixed(2)} '
          'kg/week downward';
    }

    return 'Approximately stable';
  }

  Widget _buildTrendCard() {
    final result = _calculateTrend();

    if (result == null) {
      return const SizedBox.shrink();
    }

    if (!result.hasMeasurements) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.show_chart,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No weight trend yet',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Log measurements on at least 3 different days '
                      'to begin building your weight trend.',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (!result.hasReliableTrend) {
      final minimumDays = _trendService.minimumTrendDays;

      final measuredDays = result.distinctMeasurementDays;

      final progress = (measuredDays / minimumDays).clamp(0.0, 1.0);

      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.show_chart,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Weight trend',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'More data needed',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text(
                '$measuredDays of $minimumDays '
                'different measurement days',
              ),
              const SizedBox(height: 14),
              LinearProgressIndicator(value: progress),
              const SizedBox(height: 14),
              Text(
                'Daily weight can fluctuate. Prana waits for '
                'measurements across multiple days before showing '
                'a trend.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    final usedDays =
        result.distinctMeasurementDays > _trendService.maximumTrendDays
        ? _trendService.maximumTrendDays
        : result.distinctMeasurementDays;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.show_chart,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Text(
                  'Weight trend',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            Text(
              _formatWeight(result.trendWeightKg),
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              'Based on $usedDays recent measurement '
              '${usedDays == 1 ? 'day' : 'days'}',
            ),
            const SizedBox(height: 16),
            Text(
              'Prana uses the latest measurement from each day '
              'and averages up to 7 recent measurement days. '
              'This helps reduce the effect of normal day-to-day '
              'weight fluctuations.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartCard() {
    final profile = _profile;

    if (profile == null || _entries.isEmpty) {
      return const SizedBox.shrink();
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.insights_outlined,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Weight history',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Daily measurements and your rolling weight trend.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 20),
            WeightTrendChart(
              entries: _entries,
              goalWeightKg: profile.goalWeightKg,
              minimumTrendDays: _trendService.minimumTrendDays,
              maximumTrendDays: _trendService.maximumTrendDays,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.monitor_weight_outlined, size: 40),
            const SizedBox(height: 12),
            Text(
              'No weight measurements yet',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Log your weight over time to see progress and trends.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEntryTile(WeightEntry entry) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(child: Icon(Icons.monitor_weight_outlined)),
        title: Text('${entry.weightKg.toStringAsFixed(1)} kg'),
        subtitle: Text(
          '${_formatDateTime(entry.measuredAt)} | '
          '${_formatSource(entry.source)}',
        ),
        trailing: IconButton(
          tooltip: 'Delete',
          onPressed: () {
            _deleteEntry(entry);
          },
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }

  static IconData _changeIcon(double change) {
    if (change < -0.05) {
      return Icons.trending_down;
    }

    if (change > 0.05) {
      return Icons.trending_up;
    }

    return Icons.trending_flat;
  }

  static String _changeFromStartText(double change) {
    if (change < -0.05) {
      return '${change.abs().toStringAsFixed(1)} kg '
          'down from starting weight';
    }

    if (change > 0.05) {
      return '${change.toStringAsFixed(1)} kg '
          'up from starting weight';
    }

    return 'No meaningful change from starting weight';
  }

  static _PaceConfig _paceConfig(WeightGoalDirection direction) {
    return switch (direction) {
      WeightGoalDirection.lose => const _PaceConfig(
        minimum: 0.1,
        maximum: 0.9,
        defaultValue: 0.4,
        divisions: 8,
      ),

      WeightGoalDirection.gain => const _PaceConfig(
        minimum: 0.1,
        maximum: 0.5,
        defaultValue: 0.25,
        divisions: 8,
      ),

      WeightGoalDirection.maintain => const _PaceConfig(
        minimum: 0,
        maximum: 0,
        defaultValue: 0,
        divisions: 1,
      ),
    };
  }
}

class _PaceConfig {
  const _PaceConfig({
    required this.minimum,
    required this.maximum,
    required this.defaultValue,
    required this.divisions,
  });

  final double minimum;
  final double maximum;
  final double defaultValue;
  final int divisions;
}

class _SummaryValue extends StatelessWidget {
  const _SummaryValue({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
      ],
    );
  }
}

class _ProgressMessage extends StatelessWidget {
  const _ProgressMessage({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  final IconData icon;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 22, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ProgressNotice extends StatelessWidget {
  const _ProgressNotice({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(text, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}
