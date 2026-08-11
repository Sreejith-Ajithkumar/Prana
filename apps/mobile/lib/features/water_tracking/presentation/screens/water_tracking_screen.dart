import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../nutrition/domain/services/nutrition_service.dart';
import '../../../profile/data/profile_storage.dart';
import '../../data/water_storage.dart';
import '../../domain/entities/water_entry.dart';

class WaterTrackingScreen extends StatefulWidget {
  const WaterTrackingScreen({super.key});

  @override
  State<WaterTrackingScreen> createState() => _WaterTrackingScreenState();
}

class _WaterTrackingScreenState extends State<WaterTrackingScreen> {
  final _customAmountController = TextEditingController();

  List<WaterEntry> _entries = [];

  double _targetMl = 0;

  bool _isLoading = true;
  bool _isSaving = false;

  double get _totalMl {
    return _entries.fold(0.0, (total, entry) => total + entry.amountMl);
  }

  double get _remainingMl {
    if (_targetMl <= 0) {
      return 0;
    }

    final remaining = _targetMl - _totalMl;

    return remaining > 0 ? remaining : 0;
  }

  double get _progress {
    if (_targetMl <= 0) {
      return 0;
    }

    return (_totalMl / _targetMl).clamp(0.0, 1.0);
  }

  @override
  void initState() {
    super.initState();
    _loadScreen();
  }

  @override
  void dispose() {
    _customAmountController.dispose();
    super.dispose();
  }

  Future<void> _loadScreen() async {
    try {
      final profile = await ProfileStorage.instance.loadProfile();

      final entries = await WaterStorage.instance.loadEntriesForDate(
        DateTime.now(),
      );

      double targetMl = 0;

      if (profile != null) {
        try {
          final nutritionService = NutritionService();

          final targets = nutritionService.calculate(profile);

          targetMl = targets.waterLitres * 1000;
        } catch (error, stackTrace) {
          debugPrint('WATER TARGET ERROR: $error');

          debugPrintStack(stackTrace: stackTrace);
        }
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _entries = entries;
        _targetMl = targetMl;
        _isLoading = false;
      });
    } catch (error, stackTrace) {
      debugPrint('WATER LOAD ERROR: $error');

      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      setState(() {
        _entries = [];
        _targetMl = 0;
        _isLoading = false;
      });
    }
  }

  Future<void> _addWater(double amountMl) async {
    if (_isSaving || amountMl <= 0) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final now = DateTime.now();

      final entry = WaterEntry(
        id: 'water-${now.microsecondsSinceEpoch}',
        amountMl: amountMl,
        loggedAt: now,
      );

      await WaterStorage.instance.addEntry(entry);

      await _loadScreen();
    } catch (error, stackTrace) {
      debugPrint('WATER SAVE ERROR: $error');

      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We could not save your water entry.')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  Future<void> _addCustomWater() async {
    final amount = double.tryParse(_customAmountController.text.trim());

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid water amount.')),
      );

      return;
    }

    FocusScope.of(context).unfocus();

    await _addWater(amount);

    if (!mounted) {
      return;
    }

    _customAmountController.clear();
  }

  Future<void> _deleteEntry(WaterEntry entry) async {
    try {
      await WaterStorage.instance.deleteEntry(entry.id);

      await _loadScreen();
    } catch (error, stackTrace) {
      debugPrint('WATER DELETE ERROR: $error');

      debugPrintStack(stackTrace: stackTrace);
    }
  }

  String _formatVolume(double amountMl) {
    if (amountMl < 1000) {
      return '${amountMl.toStringAsFixed(0)} mL';
    }

    final litres = amountMl / 1000;

    if (litres == litres.roundToDouble()) {
      return '${litres.toStringAsFixed(0)} L';
    }

    return '${litres.toStringAsFixed(2)} L';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Water')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
                children: [
                  _WaterGoalCard(
                    consumedMl: _totalMl,
                    targetMl: _targetMl,
                    remainingMl: _remainingMl,
                    progress: _progress,
                    formatVolume: _formatVolume,
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Quick add',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      _QuickWaterButton(
                        label: '250 mL',
                        enabled: !_isSaving,
                        onPressed: () {
                          _addWater(250);
                        },
                      ),
                      _QuickWaterButton(
                        label: '500 mL',
                        enabled: !_isSaving,
                        onPressed: () {
                          _addWater(500);
                        },
                      ),
                      _QuickWaterButton(
                        label: '750 mL',
                        enabled: !_isSaving,
                        onPressed: () {
                          _addWater(750);
                        },
                      ),
                      _QuickWaterButton(
                        label: '1 L',
                        enabled: !_isSaving,
                        onPressed: () {
                          _addWater(1000);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Custom amount',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _customAmountController,
                          decoration: const InputDecoration(
                            labelText: 'Water amount',
                            suffixText: 'mL',
                            hintText: '350',
                          ),
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'^\d{0,5}(\.\d{0,1})?'),
                            ),
                          ],
                          onSubmitted: (_) {
                            _addCustomWater();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      SizedBox(
                        width: 90,
                        child: FilledButton(
                          onPressed: _isSaving ? null : _addCustomWater,
                          child: const Text('Add'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Today',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Text(
                        '${_entries.length} '
                        '${_entries.length == 1 ? 'entry' : 'entries'}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (_entries.isEmpty)
                    const _EmptyWaterState()
                  else
                    ..._entries.reversed.map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _WaterEntryCard(
                          entry: entry,
                          onDelete: () {
                            _deleteEntry(entry);
                          },
                        ),
                      ),
                    ),
                ],
              ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(24, 8, 24, 16),
        child: FilledButton(
          onPressed: () {
            context.pop(true);
          },
          child: const Text('Done'),
        ),
      ),
    );
  }
}

class _WaterGoalCard extends StatelessWidget {
  const _WaterGoalCard({
    required this.consumedMl,
    required this.targetMl,
    required this.remainingMl,
    required this.progress,
    required this.formatVolume,
  });

  final double consumedMl;
  final double targetMl;
  final double remainingMl;
  final double progress;
  final String Function(double) formatVolume;

  @override
  Widget build(BuildContext context) {
    final hasTarget = targetMl > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.primaryContainer,
                  child: Icon(
                    Icons.water_drop_outlined,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Water today'),
                      const SizedBox(height: 4),
                      Text(
                        hasTarget
                            ? '${formatVolume(consumedMl)} / ${formatVolume(targetMl)}'
                            : formatVolume(consumedMl),
                        style: Theme.of(context).textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (hasTarget) ...[
              const SizedBox(height: 20),
              LinearProgressIndicator(
                value: progress,
                minHeight: 10,
                borderRadius: BorderRadius.circular(20),
              ),
              const SizedBox(height: 12),
              Text(
                remainingMl > 0
                    ? '${formatVolume(remainingMl)} remaining'
                    : 'Daily water goal reached',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Estimated daily hydration target based on your profile.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _QuickWaterButton extends StatelessWidget {
  const _QuickWaterButton({
    required this.label,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      child: FilledButton.tonalIcon(
        onPressed: enabled ? onPressed : null,
        icon: const Icon(Icons.add),
        label: Text(label),
      ),
    );
  }
}

class _WaterEntryCard extends StatelessWidget {
  const _WaterEntryCard({required this.entry, required this.onDelete});

  final WaterEntry entry;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final time = TimeOfDay.fromDateTime(entry.loggedAt);

    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Icon(
            Icons.local_drink_outlined,
            color: Theme.of(context).colorScheme.onPrimaryContainer,
          ),
        ),
        title: Text('${entry.amountMl.toStringAsFixed(0)} mL'),
        subtitle: Text(time.format(context)),
        trailing: IconButton(
          tooltip: 'Delete water entry',
          onPressed: onDelete,
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
  }
}

class _EmptyWaterState extends StatelessWidget {
  const _EmptyWaterState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.water_drop_outlined,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No water logged yet',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Use a quick-add button or enter a custom amount to start tracking your water.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
