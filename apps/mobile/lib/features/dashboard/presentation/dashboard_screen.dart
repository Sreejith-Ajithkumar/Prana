import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../meal_tracking/data/meal_storage.dart';
import '../../meal_tracking/domain/entities/meal_entry.dart';
import '../../nutrition/domain/services/nutrition_service.dart';
import '../../profile/data/profile_storage.dart';
import '../../water_tracking/data/water_storage.dart';
import '../../weight_tracking/presentation/screens/weight_tracking_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  String? _firstName;
  bool _isLoading = true;

  int _progressRevision = 0;

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
    _tabController = TabController(length: 2, vsync: this);
    _loadDashboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

    return '$greeting, $firstName \u{1F44B}';
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

  Future<void> _openProfile() async {
    await context.push('/profile');

    if (!mounted) {
      return;
    }

    await _loadDashboard();

    if (!mounted) {
      return;
    }

    setState(() {
      _progressRevision++;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Prana'),
        actions: [
          IconButton(
            tooltip: 'Profile',
            onPressed: _openProfile,
            icon: const Icon(Icons.person_outline),
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorSize: TabBarIndicatorSize.label,
          dividerColor: Colors.transparent,
          labelStyle: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          tabs: const [
            Tab(text: 'Today'),
            Tab(text: 'Progress'),
          ],
        ),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildTodayTab(),
                  WeightTrackingScreen(
                    key: ValueKey('progress-$_progressRevision'),
                    embedded: true,
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildTodayTab() {
    return Stack(
      children: [
        Positioned.fill(
          child: RefreshIndicator(
            onRefresh: _loadDashboard,
            child: LayoutBuilder(
              builder: (context, viewportConstraints) {
                final horizontalPadding = viewportConstraints.maxWidth < 370
                    ? 16.0
                    : 20.0;

                return ListView(
                  key: const PageStorageKey<String>('dashboard-today-scroll'),
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    24,
                    horizontalPadding,
                    132,
                  ),
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
                      AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Text(
                          'Goal: $_goalName',
                          key: ValueKey(_goalName),
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
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
                    _MetricGrid(
                      protein: _GoalMetricCard(
                        title: 'Protein',
                        consumed: _consumedProtein,
                        target: _proteinTarget,
                        unit: 'g',
                        icon: Icons.fitness_center,
                        metricType: _MetricType.protein,
                      ),
                      water: _GoalMetricCard(
                        title: 'Water',
                        consumed: _consumedWaterMl,
                        target: _waterTargetMl,
                        unit: 'mL',
                        icon: Icons.water_drop_outlined,
                        displayAsLitres: true,
                        metricType: _MetricType.water,
                        onTap: _openWaterTracking,
                      ),
                      carbs: _GoalMetricCard(
                        title: 'Carbs',
                        consumed: _consumedCarbs,
                        target: _carbTarget,
                        unit: 'g',
                        icon: Icons.rice_bowl_outlined,
                        metricType: _MetricType.carbs,
                      ),
                      fat: _GoalMetricCard(
                        title: 'Fat',
                        consumed: _consumedFat,
                        target: _fatTarget,
                        unit: 'g',
                        icon: Icons.eco_outlined,
                        metricType: _MetricType.fat,
                      ),
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
                );
              },
            ),
          ),
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: SafeArea(
            top: false,
            child: FloatingActionButton.extended(
              heroTag: 'dashboard-add-meal',
              onPressed: _openAddMeal,
              icon: const Icon(Icons.add),
              label: const Text('Add meal'),
            ),
          ),
        ),
      ],
    );
  }
}

enum _MetricType { calories, protein, water, carbs, fat }

enum _GoalProgressState { normal, approaching, reached, above }

_GoalProgressState _getProgressState({
  required double consumed,
  required double target,
}) {
  if (target <= 0) {
    return _GoalProgressState.normal;
  }

  final ratio = consumed / target;

  if (ratio < 0.75) {
    return _GoalProgressState.normal;
  }

  if (ratio < 1.0) {
    return _GoalProgressState.approaching;
  }

  if (ratio <= 1.10) {
    return _GoalProgressState.reached;
  }

  return _GoalProgressState.above;
}

Color _progressColor(
  BuildContext context,
  _GoalProgressState state, {
  required _MetricType metricType,
}) {
  final colors = Theme.of(context).colorScheme;

  return switch (state) {
    _GoalProgressState.normal => colors.primary,
    _GoalProgressState.approaching => colors.tertiary,
    _GoalProgressState.reached => colors.primary,
    _GoalProgressState.above =>
      metricType == _MetricType.water || metricType == _MetricType.protein
          ? colors.primary
          : colors.error,
  };
}

String _progressLabel(
  _GoalProgressState state, {
  required _MetricType metricType,
}) {
  return switch (state) {
    _GoalProgressState.normal => 'On track',
    _GoalProgressState.approaching => 'Approaching target',
    _GoalProgressState.reached => 'Target reached',
    _GoalProgressState.above =>
      metricType == _MetricType.water || metricType == _MetricType.protein
          ? 'Target reached'
          : 'Above target',
  };
}

IconData _progressIcon(_GoalProgressState state) {
  return switch (state) {
    _GoalProgressState.normal => Icons.trending_up,
    _GoalProgressState.approaching => Icons.timelapse,
    _GoalProgressState.reached => Icons.check_circle_outline,
    _GoalProgressState.above => Icons.info_outline,
  };
}

class _MetricGrid extends StatelessWidget {
  const _MetricGrid({
    required this.protein,
    required this.water,
    required this.carbs,
    required this.fat,
  });

  final Widget protein;
  final Widget water;
  final Widget carbs;
  final Widget fat;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        /*
         * Once the available content width gets too small,
         * showing two metric cards side by side becomes
         * cramped. Switch to a single-column layout instead.
         */
        final useSingleColumn = constraints.maxWidth < 330;

        if (useSingleColumn) {
          return Column(
            children: [
              protein,
              const SizedBox(height: 12),
              water,
              const SizedBox(height: 12),
              carbs,
              const SizedBox(height: 12),
              fat,
            ],
          );
        }

        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: protein),
                const SizedBox(width: 12),
                Expanded(child: water),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: carbs),
                const SizedBox(width: 12),
                Expanded(child: fat),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _AnimatedMetricText extends StatelessWidget {
  const _AnimatedMetricText({
    required this.value,
    required this.formatter,
    required this.style,
  });

  final double value;
  final String Function(double value) formatter;

  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: value),
      duration: disableAnimations
          ? Duration.zero
          : const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, animatedValue, child) {
        return SizedBox(
          width: double.infinity,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(formatter(animatedValue), maxLines: 1, style: style),
          ),
        );
      },
    );
  }
}

class _AnimatedConsumedTargetText extends StatelessWidget {
  const _AnimatedConsumedTargetText({
    required this.consumed,
    required this.target,
    required this.unit,
    required this.style,
  });

  final double consumed;
  final double target;
  final String unit;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    final duration = disableAnimations
        ? Duration.zero
        : const Duration(milliseconds: 650);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: consumed),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, animatedConsumed, child) {
        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: target),
          duration: duration,
          curve: Curves.easeOutCubic,
          builder: (context, animatedTarget, child) {
            final text = target > 0
                ? '${animatedConsumed.toStringAsFixed(0)} / '
                      '${animatedTarget.toStringAsFixed(0)} $unit'
                : '${animatedConsumed.toStringAsFixed(0)} $unit';

            return SizedBox(
              width: double.infinity,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(text, maxLines: 1, style: style),
              ),
            );
          },
        );
      },
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

    final state = _getProgressState(consumed: consumed, target: target);

    final stateColor = _progressColor(
      context,
      state,
      metricType: _MetricType.calories,
    );

    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(22),
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

                const SizedBox(width: 16),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title),
                      const SizedBox(height: 4),
                      _AnimatedConsumedTargetText(
                        consumed: consumed,
                        target: target,
                        unit: unit,
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
                tween: Tween<double>(begin: 0, end: progress),
                duration: disableAnimations
                    ? Duration.zero
                    : const Duration(milliseconds: 650),
                curve: Curves.easeOutCubic,
                builder: (context, value, child) {
                  return LinearProgressIndicator(
                    value: value,
                    color: stateColor,
                    backgroundColor: stateColor.withValues(alpha: 0.15),
                    minHeight: 10,
                    borderRadius: BorderRadius.circular(20),
                  );
                },
              ),

              const SizedBox(height: 12),

              Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 6,
                runSpacing: 4,
                children: [
                  Icon(_progressIcon(state), size: 18, color: stateColor),
                  Text(
                    _progressLabel(state, metricType: _MetricType.calories),
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: stateColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

              AnimatedSwitcher(
                duration: disableAnimations
                    ? Duration.zero
                    : const Duration(milliseconds: 300),
                child: Text(
                  remaining > 0
                      ? '${remaining.toStringAsFixed(0)} $unit remaining to target'
                      : remaining == 0
                      ? 'Daily target reached'
                      : '${remaining.abs().toStringAsFixed(0)} $unit above target',
                  key: ValueKey(remaining.toStringAsFixed(0)),
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
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
    required this.metricType,
    this.displayAsLitres = false,
    this.onTap,
  });

  final String title;
  final double consumed;
  final double target;
  final String unit;
  final IconData icon;
  final _MetricType metricType;
  final bool displayAsLitres;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final hasTarget = target > 0;

    final progress = hasTarget ? (consumed / target).clamp(0.0, 1.0) : 0.0;

    final state = _getProgressState(consumed: consumed, target: target);

    final stateColor = _progressColor(context, state, metricType: metricType);

    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 155;

        final cardPadding = compact ? 14.0 : 16.0;

        return Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.all(cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(icon, size: compact ? 22 : 24),
                      const Spacer(),
                      if (onTap != null)
                        const Icon(Icons.chevron_right, size: 20),
                    ],
                  ),

                  const SizedBox(height: 14),

                  Text(
                    title,
                    style: compact
                        ? Theme.of(context).textTheme.bodyLarge
                        : null,
                  ),

                  const SizedBox(height: 4),

                  _AnimatedMetricText(
                    value: consumed,
                    formatter: _formatValue,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),

                  if (hasTarget) ...[
                    const SizedBox(height: 2),

                    _AnimatedMetricText(
                      value: target,
                      formatter: (value) {
                        return 'of ${_formatValue(value)}';
                      },
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const SizedBox(height: 12),

                    TweenAnimationBuilder<double>(
                      tween: Tween<double>(begin: 0, end: progress),
                      duration: disableAnimations
                          ? Duration.zero
                          : const Duration(milliseconds: 650),
                      curve: Curves.easeOutCubic,
                      builder: (context, value, child) {
                        return LinearProgressIndicator(
                          value: value,
                          color: stateColor,
                          backgroundColor: stateColor.withValues(alpha: 0.15),
                          minHeight: 7,
                          borderRadius: BorderRadius.circular(20),
                        );
                      },
                    ),

                    const SizedBox(height: 10),

                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: 1),
                          child: Icon(
                            _progressIcon(state),
                            size: 14,
                            color: stateColor,
                          ),
                        ),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            _progressLabel(state, metricType: metricType),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: stateColor,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
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
        ' \u2022 '
        'C ${meal.carbohydrateGrams.toStringAsFixed(0)} g'
        ' \u2022 '
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
