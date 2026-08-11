import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../meal_tracking/data/meal_storage.dart';
import '../../meal_tracking/domain/entities/meal_entry.dart';
import '../../nutrition/domain/services/nutrition_service.dart';
import '../../profile/data/profile_storage.dart';
import '../../water_tracking/data/water_storage.dart';

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
  double _consumedWaterMl = 0;

  double _calorieTarget = 0;
  double _proteinTarget = 0;
  double _carbTarget = 0;
  double _fatTarget = 0;
  double _waterTargetMl = 0;

  String _goalName = '';

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    final today = DateTime.now();

    final profile = await ProfileStorage.instance.loadProfile();

    final meals = await MealStorage.instance.loadMealsForDate(today);

    final waterEntries = await WaterStorage.instance.loadEntriesForDate(today);

    double calories = 0;
    double protein = 0;
    double carbs = 0;
    double fat = 0;
    double waterMl = 0;

    for (final meal in meals) {
      calories += meal.calories;
      protein += meal.proteinGrams;
      carbs += meal.carbohydrateGrams;
      fat += meal.fatGrams;
    }

    for (final entry in waterEntries) {
      waterMl += entry.amountMl;
    }

    double calorieTarget = 0;
    double proteinTarget = 0;
    double carbTarget = 0;
    double fatTarget = 0;
    double waterTargetMl = 0;
    String goalName = '';

    if (profile != null) {
      try {
        const nutritionService = NutritionService();

        final targets = nutritionService.calculate(profile);

        calorieTarget = targets.calories;
        proteinTarget = targets.protein;
        carbTarget = targets.carbohydrates;
        fatTarget = targets.fat;
        waterTargetMl = targets.waterLitres * 1000;

        goalName = _formatGoalName(profile.goal.name);
      } catch (error, stackTrace) {
        debugPrint('DASHBOARD TARGET ERROR: $error');

        debugPrintStack(stackTrace: stackTrace);
      }
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
      _consumedWaterMl = waterMl;

      _calorieTarget = calorieTarget;
      _proteinTarget = proteinTarget;
      _carbTarget = carbTarget;
      _fatTarget = fatTarget;
      _waterTargetMl = waterTargetMl;

      _goalName = goalName;

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

  static String _formatGoalName(String value) {
    return switch (value) {
      'loseWeight' => 'Weight loss',
      'maintainWeight' => 'Maintain weight',
      'gainMuscle' => 'Gain muscle',
      'improveHealth' => 'Improve health',
      _ => 'Personal goal',
    };
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

  Future<void> _openEditMeal(MealEntry meal) async {
    final changed = await context.push<bool>('/meals/edit', extra: meal);

    if (!mounted) {
      return;
    }

    if (changed == true) {
      await _loadDashboard();
    }
  }

  Future<void> _openWaterTracking() async {
    final changed = await context.push<bool>('/water');

    if (!mounted) {
      return;
    }

    if (changed == true) {
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
                  physics: const AlwaysScrollableScrollPhysics(),
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

                    if (_goalName.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Goal: $_goalName',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    _GoalSummaryCard(
                      title: 'Calories',
                      consumed: _consumedCalories,
                      target: _calorieTarget,
                      unit: 'kcal',
                      icon: Icons.local_fire_department_outlined,
                      targetDescription:
                          'Estimated daily calorie target for your current goal.',
                    ),

                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _GoalMetricCard(
                            title: 'Protein',
                            consumed: _consumedProtein,
                            target: _proteinTarget,
                            unit: 'g',
                            icon: Icons.fitness_center,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _GoalMetricCard(
                            title: 'Water',
                            consumed: _consumedWaterMl,
                            target: _waterTargetMl,
                            unit: 'mL',
                            icon: Icons.water_drop_outlined,
                            displayAsLitres: true,
                            onTap: _openWaterTracking,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: _GoalMetricCard(
                            title: 'Carbs',
                            consumed: _consumedCarbs,
                            target: _carbTarget,
                            unit: 'g',
                            icon: Icons.rice_bowl_outlined,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _GoalMetricCard(
                            title: 'Fat',
                            consumed: _consumedFat,
                            target: _fatTarget,
                            unit: 'g',
                            icon: Icons.eco_outlined,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 28),

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
                            onTap: () {
                              _openEditMeal(meal);
                            },
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

class _GoalSummaryCard extends StatelessWidget {
  const _GoalSummaryCard({
    required this.title,
    required this.consumed,
    required this.target,
    required this.unit,
    required this.icon,
    required this.targetDescription,
  });

  final String title;
  final double consumed;
  final double target;
  final String unit;
  final IconData icon;
  final String targetDescription;

  @override
  Widget build(BuildContext context) {
    final hasTarget = target > 0;

    final progress = hasTarget ? (consumed / target).clamp(0.0, 1.0) : 0.0;

    final remaining = hasTarget ? target - consumed : 0.0;

    final disableAnimations = MediaQuery.disableAnimationsOf(context);

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
                    icon,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title),
                      const SizedBox(height: 4),
                      Text(
                        hasTarget
                            ? '${consumed.toStringAsFixed(0)} / '
                                  '${target.toStringAsFixed(0)} $unit'
                            : '${consumed.toStringAsFixed(0)} $unit',
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

              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: progress),
                duration: disableAnimations
                    ? Duration.zero
                    : const Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return LinearProgressIndicator(
                    value: value,
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(20),
                  );
                },
              ),

              const SizedBox(height: 12),

              Text(
                remaining > 0
                    ? '${remaining.toStringAsFixed(0)} $unit remaining to target'
                    : remaining == 0
                    ? 'Daily target reached'
                    : '${remaining.abs().toStringAsFixed(0)} $unit above target',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
              ),

              const SizedBox(height: 6),

              Text(
                targetDescription,
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

class _GoalMetricCard extends StatelessWidget {
  const _GoalMetricCard({
    required this.title,
    required this.consumed,
    required this.target,
    required this.unit,
    required this.icon,
    this.displayAsLitres = false,
    this.onTap,
  });

  final String title;
  final double consumed;
  final double target;
  final String unit;
  final IconData icon;
  final bool displayAsLitres;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasTarget = target > 0;

    final progress = hasTarget ? (consumed / target).clamp(0.0, 1.0) : 0.0;

    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon),
                  const Spacer(),
                  if (onTap != null) const Icon(Icons.chevron_right, size: 20),
                ],
              ),

              const SizedBox(height: 14),

              Text(title),

              const SizedBox(height: 4),

              Text(
                _formatValue(consumed),
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),

              if (hasTarget) ...[
                const SizedBox(height: 2),

                Text(
                  'of ${_formatValue(target)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),

                const SizedBox(height: 12),

                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: progress),
                  duration: disableAnimations
                      ? Duration.zero
                      : const Duration(milliseconds: 650),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, child) {
                    return LinearProgressIndicator(
                      value: value,
                      minHeight: 7,
                      borderRadius: BorderRadius.circular(20),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatValue(double value) {
    if (displayAsLitres) {
      final litres = value / 1000;

      if (litres == litres.roundToDouble()) {
        return '${litres.toStringAsFixed(0)} L';
      }

      return '${litres.toStringAsFixed(2)} L';
    }

    if (value == value.roundToDouble()) {
      return '${value.toStringAsFixed(0)} $unit';
    }

    return '${value.toStringAsFixed(1)} $unit';
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
    return 'P ${meal.proteinGrams.toStringAsFixed(0)} g'
        ' • '
        'C ${meal.carbohydrateGrams.toStringAsFixed(0)} g'
        ' • '
        'F ${meal.fatGrams.toStringAsFixed(0)} g';
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
