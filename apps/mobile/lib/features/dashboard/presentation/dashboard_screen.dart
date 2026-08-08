import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../meal_tracking/data/meal_storage.dart';
import '../../meal_tracking/domain/entities/meal_entry.dart';
import '../../profile/data/profile_storage.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? _firstName;
  bool _isLoading = true;

  List<MealEntry> _todayMeals = [];

  double _consumedCalories = 0;
  double _consumedProtein = 0;
  double _consumedCarbs = 0;
  double _consumedFat = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
      });
    }

    final profile = await ProfileStorage.instance.loadProfile();

    final meals = await MealStorage.instance.loadMealsForDate(DateTime.now());

    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;

    for (final meal in meals) {
      calories += meal.calories;
      protein += meal.proteinGrams;
      carbs += meal.carbohydrateGrams;
      fat += meal.fatGrams;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _firstName = profile?.firstName;
      _todayMeals = meals;

      _consumedCalories = calories;
      _consumedProtein = protein;
      _consumedCarbs = carbs;
      _consumedFat = fat;

      _isLoading = false;
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

  Future<void> _openEditMeal(MealEntry meal) async {
    final changed = await context.push<bool>('/meals/edit', extra: meal);

    if (!mounted) {
      return;
    }

    if (changed == true) {
      await _loadDashboard();
    }
  }

  Future<void> _openAddMeal() async {
    final added = await context.push<bool>('/meals/add');

    if (!mounted) {
      return;
    }

    if (added == true) {
      await _loadDashboard();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Prana')),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : RefreshIndicator(
                onRefresh: _loadDashboard,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
                  children: [
                    Text(
                      _buildGreeting(),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Your health summary',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 24),
                    _SummaryCard(
                      title: 'Calories',
                      value: _consumedCalories.toStringAsFixed(0),
                      subtitle: 'consumed today',
                      icon: Icons.local_fire_department_outlined,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _MetricCard(
                            title: 'Protein',
                            value: '${_consumedProtein.toStringAsFixed(0)} g',
                            icon: Icons.fitness_center,
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Expanded(
                          child: _MetricCard(
                            title: 'Water',
                            value: '0 L',
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
                            value: '${_consumedCarbs.toStringAsFixed(0)} g',
                            icon: Icons.rice_bowl_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _MetricCard(
                            title: 'Fat',
                            value: '${_consumedFat.toStringAsFixed(0)} g',
                            icon: Icons.eco_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Today',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                        if (_todayMeals.isNotEmpty)
                          Text(
                            '${_todayMeals.length} '
                            '${_todayMeals.length == 1 ? 'meal' : 'meals'}',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (_todayMeals.isEmpty)
                      const _EmptyState()
                    else
                      ..._todayMeals.map(
                        (meal) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _MealCard(
                            meal: meal,
                            onTap: () => _openEditMeal(meal),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openAddMeal,
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

class _MealCard extends StatelessWidget {
  const _MealCard({required this.meal, required this.onTap});

  final MealEntry meal;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(child: Icon(_mealIcon(meal.type.name))),
        title: Text(_formatMealType(meal.type.name)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              meal.foods.map((food) => food.name).join(', '),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _buildMacroSummary(meal),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '${meal.calories.toStringAsFixed(0)} kcal',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            const Icon(Icons.chevron_right, size: 20),
          ],
        ),
      ),
    );
  }

  static String _buildMacroSummary(MealEntry meal) {
    final protein = meal.proteinGrams.toStringAsFixed(0);

    final carbs = meal.carbohydrateGrams.toStringAsFixed(0);

    final fat = meal.fatGrams.toStringAsFixed(0);

    return 'P $protein g • C $carbs g • F $fat g';
  }

  static String _formatMealType(String value) {
    if (value.isEmpty) {
      return 'Meal';
    }

    return value[0].toUpperCase() + value.substring(1);
  }

  static IconData _mealIcon(String value) {
    return switch (value) {
      'breakfast' => Icons.free_breakfast_outlined,
      'lunch' => Icons.lunch_dining_outlined,
      'dinner' => Icons.dinner_dining_outlined,
      'snack' => Icons.cookie_outlined,
      _ => Icons.restaurant_outlined,
    };
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
