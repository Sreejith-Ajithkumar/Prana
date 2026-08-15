import 'package:flutter/material.dart';

import '../../../profile/data/profile_storage.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../data/weight_storage.dart';
import '../../domain/entities/weight_entry.dart';
import '../../domain/services/weight_trend_service.dart';

class WeightTrackingScreen extends StatefulWidget {
  const WeightTrackingScreen({super.key});

  @override
  State<WeightTrackingScreen> createState() => _WeightTrackingScreenState();
}

class _WeightTrackingScreenState extends State<WeightTrackingScreen> {
  static const WeightTrendService _trendService = WeightTrendService();

  UserProfile? _profile;
  List<WeightEntry> _entries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final profile = await ProfileStorage.instance.loadProfile();
    final entries = await WeightStorage.instance.loadEntries();

    if (!mounted) {
      return;
    }

    setState(() {
      _profile = profile;
      _entries = entries;
      _isLoading = false;
    });
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
    return Scaffold(
      appBar: AppBar(title: const Text('Weight & Progress')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addWeight,
        icon: const Icon(Icons.add),
        label: const Text('Log weight'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                children: [
                  _buildProgressCard(),
                  const SizedBox(height: 16),
                  _buildTrendCard(),
                  const SizedBox(height: 24),
                  Text(
                    'History',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (_entries.isEmpty)
                    _buildEmptyState()
                  else
                    ..._entries.reversed.map(_buildEntryTile),
                ],
              ),
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
                icon: distanceToGoal < 0.05
                    ? Icons.emoji_events_outlined
                    : Icons.flag_outlined,
                title: distanceToGoal < 0.05
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
                '$measuredDays of $minimumDays different measurement days',
                style: Theme.of(context).textTheme.bodyMedium,
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
              style: Theme.of(context).textTheme.bodyMedium,
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
      return '${change.abs().toStringAsFixed(1)} kg down from starting weight';
    }

    if (change > 0.05) {
      return '${change.toStringAsFixed(1)} kg up from starting weight';
    }

    return 'No meaningful change from starting weight';
  }
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
