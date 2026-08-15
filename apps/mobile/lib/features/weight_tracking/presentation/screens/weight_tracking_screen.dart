import 'package:flutter/material.dart';

import '../../../profile/data/profile_storage.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../../data/weight_storage.dart';
import '../../domain/entities/weight_entry.dart';

class WeightTrackingScreen extends StatefulWidget {
  const WeightTrackingScreen({super.key});

  @override
  State<WeightTrackingScreen> createState() => _WeightTrackingScreenState();
}

class _WeightTrackingScreenState extends State<WeightTrackingScreen> {
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
    final weight = await showDialog<double>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        String? errorText;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Log weight'),
              content: TextField(
                controller: controller,
                autofocus: true,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: InputDecoration(
                  labelText: 'Weight',
                  suffixText: 'kg',
                  errorText: errorText,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () {
                    final parsed = double.tryParse(controller.text.trim());

                    if (parsed == null || parsed <= 0) {
                      setDialogState(() {
                        errorText = 'Enter a valid weight.';
                      });
                      return;
                    }

                    Navigator.of(context).pop(parsed);
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );

    if (weight == null) {
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

    await _loadData();
  }

  Future<void> _deleteEntry(WeightEntry entry) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Delete weight?'),
          content: Text(
            'Delete ${entry.weightKg.toStringAsFixed(1)} kg '
            'from ${_formatDate(entry.measuredAt)}?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (shouldDelete != true) {
      return;
    }

    await WeightStorage.instance.deleteEntry(entry.id);

    await _loadData();
  }

  String _formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');

    return '${date.year}-$month-$day';
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
                  _buildSummaryCard(),
                  const SizedBox(height: 24),
                  Text(
                    'History',
                    style: Theme.of(context).textTheme.titleLarge,
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

  Widget _buildSummaryCard() {
    final latestWeight = _entries.isNotEmpty
        ? _entries.last.weightKg
        : _profile?.weightKg;

    final goalWeight = _profile?.goalWeightKg;

    final remaining = latestWeight != null && goalWeight != null
        ? (latestWeight - goalWeight).abs()
        : null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current progress',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _SummaryValue(
                    label: _entries.isEmpty
                        ? 'Reference weight'
                        : 'Latest weight',
                    value: latestWeight == null
                        ? '—'
                        : '${latestWeight.toStringAsFixed(1)} kg',
                  ),
                ),
                Expanded(
                  child: _SummaryValue(
                    label: 'Goal weight',
                    value: goalWeight == null
                        ? '—'
                        : '${goalWeight.toStringAsFixed(1)} kg',
                  ),
                ),
              ],
            ),
            if (remaining != null) ...[
              const SizedBox(height: 20),
              Text(
                '${remaining.toStringAsFixed(1)} kg from goal',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ],
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
              style: Theme.of(context).textTheme.titleMedium,
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
        subtitle: Text(_formatDate(entry.measuredAt)),
        trailing: IconButton(
          tooltip: 'Delete',
          onPressed: () => _deleteEntry(entry),
          icon: const Icon(Icons.delete_outline),
        ),
      ),
    );
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
        Text(value, style: Theme.of(context).textTheme.titleLarge),
      ],
    );
  }
}
