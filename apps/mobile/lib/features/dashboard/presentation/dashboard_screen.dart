import 'package:flutter/material.dart';

import '../../profile/data/profile_storage.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _firstName;
  bool _isLoadingProfile = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await ProfileStorage.instance.loadProfile();

    if (!mounted) {
      return;
    }

    setState(() {
      _firstName = profile?.firstName;
      _isLoadingProfile = false;
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prana')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Text(
                _isLoadingProfile ? 'Welcome to Prana' : _buildGreeting(),
                key: ValueKey(_isLoadingProfile),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Your health summary',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            const _SummaryCard(
              title: 'Calories',
              value: '0',
              subtitle: 'of 2,000 kcal',
              icon: Icons.local_fire_department_outlined,
            ),
            const SizedBox(height: 16),
            const Row(
              children: [
                Expanded(
                  child: _MetricCard(
                    title: 'Protein',
                    value: '0 g',
                    icon: Icons.fitness_center,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _MetricCard(
                    title: 'Water',
                    value: '0 L',
                    icon: Icons.water_drop_outlined,
                  ),
                ),
              ],
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
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {},
        icon: const Icon(Icons.add),
        label: const Text('Add meal'),
      ),
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
