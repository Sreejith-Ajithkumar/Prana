import 'package:flutter/material.dart';

import '../../nutrition/domain/models/nutrition_targets.dart';
import '../../nutrition/domain/services/nutrition_service.dart';
import '../../profile/data/profile_storage.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _firstName;
  NutritionTargets? _targets;

  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    try {
      final profile = await ProfileStorage.instance.loadProfile();

      if (profile == null) {
        throw StateError('No saved user profile was found.');
      }

      final targets = const NutritionService().calculate(profile);

      if (!mounted) {
        return;
      }

      setState(() {
        _firstName = profile.firstName;
        _targets = targets;
        _isLoading = false;
      });
    } on UnsupportedError {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage =
            'A male or female calculation basis is currently required '
            'to estimate nutrition targets.';
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = 'We could not calculate your nutrition targets.';
        _isLoading = false;
      });
    }
  }

  String _buildGreeting() {
    final hour = DateTime.now().hour;

    final greeting = switch (hour) {
      < 12 => 'Good morning',
      < 17 => 'Good afternoon',
      _ => 'Good evening',
    };

    final firstName = _firstName?.trim();

    if (firstName == null || firstName.isEmpty) {
      return greeting;
    }

    return '$greeting, $firstName 👋';
  }

  String _formatCategory(String value) {
    final formatted = value.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );

    return formatted[0].toUpperCase() + formatted.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prana')),
      body: SafeArea(child: _buildBody(context)),
      floatingActionButton: _targets == null
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                // Meal logging will be implemented in Sprint 5.
              },
              icon: const Icon(Icons.add),
              label: const Text('Add meal'),
            ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return _DashboardError(message: _errorMessage!, onRetry: _loadDashboard);
    }

    final targets = _targets;

    if (targets == null) {
      return _DashboardError(
        message: 'Nutrition targets are unavailable.',
        onRetry: _loadDashboard,
      );
    }

    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(_buildGreeting(), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 4),
        Text(
          'Your health summary',
          style: Theme.of(
            context,
          ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 24),

        _SummaryCard(
          title: 'Calories',
          value: '0',
          subtitle: 'of ${targets.calories.round()} kcal',
          icon: Icons.local_fire_department_outlined,
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Protein',
                value: '0 / ${targets.protein.round()} g',
                icon: Icons.fitness_center,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _MetricCard(
                title: 'Water',
                value: '0 / ${targets.waterLitres.toStringAsFixed(1)} L',
                icon: Icons.water_drop_outlined,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'Carbs',
                value: '0 / ${targets.carbohydrates.round()} g',
                icon: Icons.rice_bowl_outlined,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _MetricCard(
                title: 'Fat',
                value: '0 / ${targets.fat.round()} g',
                icon: Icons.eco_outlined,
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        _SummaryCard(
          title: 'BMI',
          value: targets.bmi.toStringAsFixed(1),
          subtitle: _formatCategory(targets.bmiCategory.name),
          icon: Icons.monitor_weight_outlined,
        ),

        const SizedBox(height: 24),

        Text(
          'Today',
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),

        const SizedBox(height: 12),

        const _EmptyState(),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: colors.primaryContainer,
              child: Icon(icon, color: colors.onPrimaryContainer),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(subtitle),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  final String title;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon),
            const SizedBox(height: 16),
            Text(title),
            const SizedBox(height: 4),
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          children: [
            Icon(
              Icons.restaurant_menu,
              size: 48,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 16),
            Text(
              'No meals logged yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            const Text(
              'Add your first meal to start tracking calories and nutrition.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            FilledButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}
