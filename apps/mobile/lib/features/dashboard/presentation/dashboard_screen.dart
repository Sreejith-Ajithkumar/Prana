import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../health/data/repositories/health_connect_data_repository.dart';
import '../../health/domain/services/health_today_activity_service.dart';
import '../../meal_tracking/data/meal_storage.dart';
import '../../meal_tracking/domain/entities/meal_entry.dart';
import '../../nutrition/domain/services/nutrition_service.dart';
import '../../profile/data/profile_storage.dart';
import '../../water_tracking/data/water_storage.dart';
import '../../weight_tracking/presentation/screens/weight_tracking_screen.dart';

typedef HealthTodayActivityLoader =
    Future<HealthTodayActivityResult> Function();

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key, this.activityLoader});

  final HealthTodayActivityLoader? activityLoader;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  late final HealthTodayActivityLoader _activityLoader;

  String? _firstName;
  bool _isLoading = true;
  bool _isActivityLoading = true;
  bool _activityLoadFailed = false;

  HealthTodayActivityResult? _activityResult;

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
    _activityLoader = widget.activityLoader ?? _createDefaultActivityLoader();
    _loadDashboard();
    _loadActivity();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  HealthTodayActivityLoader _createDefaultActivityLoader() {
    if (defaultTargetPlatform != TargetPlatform.android) {
      return () async {
        return const HealthTodayActivityResult(
          status: HealthTodayActivityStatus.unavailable,
        );
      };
    }

    final repository = HealthConnectDataRepository();
    final service = HealthTodayActivityService(repository);

    return () => service.load();
  }

  Future<void> _loadActivity() async {
    if (mounted) {
      setState(() {
        _isActivityLoading = true;
        _activityLoadFailed = false;
      });
    }

    try {
      final result = await _activityLoader();

      if (!mounted) {
        return;
      }

      setState(() {
        _activityResult = result;
        _isActivityLoading = false;
        _activityLoadFailed = false;
      });
    } catch (error, stackTrace) {
      debugPrint('DASHBOARD ACTIVITY ERROR: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) {
        return;
      }

      setState(() {
        _activityResult = null;
        _isActivityLoading = false;
        _activityLoadFailed = true;
      });
    }
  }

  Future<void> _refreshToday() async {
    await Future.wait([_loadDashboard(), _loadActivity()]);
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

  Future<void> _openHealthConnections() async {
    await context.push('/health');

    if (!mounted) {
      return;
    }

    await _loadActivity();
  }

  Future<void> _openProfile() async {
    await context.push('/profile');

    if (!mounted) {
      return;
    }

    await Future.wait([_loadDashboard(), _loadActivity()]);

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
            onRefresh: _refreshToday,
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
                    Text(
                      'Activity today',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    DashboardActivityCard(
                      isLoading: _isActivityLoading,
                      result: _activityResult,
                      hasError: _activityLoadFailed,
                      onManageAccess: _openHealthConnections,
                      onRetry: _loadActivity,
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

class DashboardActivityCard extends StatelessWidget {
  const DashboardActivityCard({
    required this.isLoading,
    required this.result,
    required this.hasError,
    required this.onManageAccess,
    required this.onRetry,
    super.key,
  });

  final bool isLoading;
  final HealthTodayActivityResult? result;
  final bool hasError;
  final VoidCallback onManageAccess;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _buildContent(context, colors),
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, ColorScheme colors) {
    if (isLoading) {
      return const Row(
        key: ValueKey('activity-loading'),
        children: [
          SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          SizedBox(width: 14),
          Expanded(child: Text('Loading activity from Health Connect...')),
        ],
      );
    }

    if (hasError) {
      return _ActivityMessage(
        key: const ValueKey('activity-error'),
        icon: Icons.sync_problem_outlined,
        title: 'Activity could not be refreshed',
        message:
            'Your nutrition targets are unchanged. Try activity sync again.',
        actionLabel: 'Retry',
        onAction: onRetry,
      );
    }

    final currentResult = result;

    if (currentResult == null ||
        currentResult.status == HealthTodayActivityStatus.unavailable) {
      return const _ActivityMessage(
        key: ValueKey('activity-unavailable'),
        icon: Icons.watch_off_outlined,
        title: 'Health activity unavailable',
        message: 'Activity data is not available on this device right now.',
      );
    }

    if (currentResult.status == HealthTodayActivityStatus.accessNeeded) {
      return _ActivityMessage(
        key: const ValueKey('activity-access-needed'),
        icon: Icons.health_and_safety_outlined,
        title: 'Connect activity data',
        message: 'Choose which Health Connect activity data Prana can read.',
        actionLabel: 'Manage Health access',
        onAction: onManageAccess,
      );
    }

    final summary = currentResult.summary;

    if (summary == null) {
      return _ActivityMessage(
        key: const ValueKey('activity-missing-summary'),
        icon: Icons.sync_problem_outlined,
        title: 'Activity could not be refreshed',
        message: 'Try activity sync again.',
        actionLabel: 'Retry',
        onAction: onRetry,
      );
    }

    if (currentResult.hasFullAccess && !summary.hasActivity) {
      return const _ActivityMessage(
        key: ValueKey('activity-empty'),
        icon: Icons.directions_walk_outlined,
        title: 'No activity recorded today yet',
        message:
            'When Health Connect has activity data, your daily summary will appear here.',
        footer:
            'Active energy is informational and does not change your nutrition target.',
      );
    }

    return Column(
      key: const ValueKey('activity-ready'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final singleColumn = constraints.maxWidth < 310;

            final metrics = <Widget>[
              _ActivityMetric(
                icon: Icons.directions_walk_outlined,
                label: 'Steps',
                value: _formatInteger(summary.steps),
                isConnected: currentResult.hasStepsAccess,
              ),
              _ActivityMetric(
                icon: Icons.local_fire_department_outlined,
                label: 'Active energy',
                value: '${summary.activeEnergyKcal.toStringAsFixed(0)} kcal',
                isConnected: currentResult.hasActiveEnergyAccess,
              ),
              _ActivityMetric(
                icon: Icons.fitness_center_outlined,
                label: 'Workouts',
                value:
                    '${summary.workoutCount} '
                    '${summary.workoutCount == 1 ? 'workout' : 'workouts'}',
                isConnected: currentResult.hasWorkoutAccess,
              ),
              _ActivityMetric(
                icon: Icons.timer_outlined,
                label: 'Workout time',
                value: _formatDuration(summary.workoutDuration),
                isConnected: currentResult.hasWorkoutAccess,
              ),
            ];

            if (singleColumn) {
              return Column(
                children: [
                  metrics[0],
                  const SizedBox(height: 16),
                  metrics[1],
                  const SizedBox(height: 16),
                  metrics[2],
                  const SizedBox(height: 16),
                  metrics[3],
                ],
              );
            }

            return Column(
              children: [
                Row(
                  children: [
                    Expanded(child: metrics[0]),
                    const SizedBox(width: 16),
                    Expanded(child: metrics[1]),
                  ],
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(child: metrics[2]),
                    const SizedBox(width: 16),
                    Expanded(child: metrics[3]),
                  ],
                ),
              ],
            );
          },
        ),
        if (currentResult.hasPartialAccess) ...[
          const SizedBox(height: 18),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: colors.secondaryContainer.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.health_and_safety_outlined,
                  size: 20,
                  color: colors.onSecondaryContainer,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Some activity permissions are off. Connected metrics '
                    'still update normally.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colors.onSecondaryContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: FilledButton.tonalIcon(
              onPressed: onManageAccess,
              icon: const Icon(Icons.settings_outlined),
              label: const Text('Manage Health access'),
            ),
          ),
        ],
        const SizedBox(height: 18),
        Divider(color: colors.outlineVariant),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.info_outline, size: 18, color: colors.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Active energy is informational and does not change your '
                'nutrition target.',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
            ),
          ],
        ),
      ],
    );
  }

  static String _formatInteger(int value) {
    final digits = value.abs().toString();
    final buffer = StringBuffer();

    for (var index = 0; index < digits.length; index++) {
      if (index > 0 && (digits.length - index) % 3 == 0) {
        buffer.write(',');
      }

      buffer.write(digits[index]);
    }

    return value < 0 ? '-$buffer' : buffer.toString();
  }

  static String _formatDuration(Duration duration) {
    final totalMinutes = duration.inMinutes;

    if (totalMinutes < 60) {
      return '$totalMinutes min';
    }

    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;

    if (minutes == 0) {
      return '$hours hr';
    }

    return '$hours hr $minutes min';
  }
}

class _ActivityMetric extends StatelessWidget {
  const _ActivityMetric({
    required this.icon,
    required this.label,
    required this.value,
    required this.isConnected,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isConnected;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    final avatarBackground = isConnected
        ? colors.secondaryContainer
        : colors.surfaceContainerHighest;

    final avatarForeground = isConnected
        ? colors.onSecondaryContainer
        : colors.onSurfaceVariant;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 20,
          backgroundColor: avatarBackground,
          child: Icon(icon, size: 20, color: avatarForeground),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isConnected ? value : '—',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isConnected ? null : colors.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
              ),
              const SizedBox(height: 3),
              Text(
                isConnected ? 'Connected' : 'Not connected',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: isConnected ? colors.primary : colors.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ActivityMessage extends StatelessWidget {
  const _ActivityMessage({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.footer,
    super.key,
  });

  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final String? footer;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              backgroundColor: colors.secondaryContainer,
              child: Icon(icon, color: colors.onSecondaryContainer),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        if (actionLabel != null && onAction != null) ...[
          const SizedBox(height: 16),
          FilledButton.tonal(onPressed: onAction, child: Text(actionLabel!)),
        ],
        if (footer != null) ...[
          const SizedBox(height: 16),
          Text(
            footer!,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant),
          ),
        ],
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
