import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../controllers/onboarding_scope.dart';
import '../../../../core/widgets/layout/progress_header.dart';

class GoalScreen extends StatefulWidget {
  const GoalScreen({super.key});

  @override
  State<GoalScreen> createState() => _GoalScreenState();
}

class _GoalScreenState extends State<GoalScreen> {
  HealthGoal? _selectedGoal;

  void _selectGoal(HealthGoal goal) {
    setState(() {
      _selectedGoal = goal;
    });
  }

  void _continue() {
    final selectedGoal = _selectedGoal;

    if (selectedGoal == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your health goal.')),
      );
      return;
    }

    OnboardingScope.of(context).setGoal(selectedGoal);

    context.push('/onboarding/activity');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your goal')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProgressHeader(
                progress: 7 / 9,
                title: 'What would you like to achieve?',
                subtitle:
                    'Prana will personalize your nutrition plan based on your goal.',
              ),
              Expanded(
                child: RadioGroup<HealthGoal>(
                  groupValue: _selectedGoal,
                  onChanged: (goal) {
                    if (goal != null) {
                      _selectGoal(goal);
                    }
                  },
                  child: ListView(
                    children: [
                      _GoalOption(
                        title: 'Lose weight',
                        subtitle: 'Create a sustainable calorie deficit.',
                        icon: Icons.trending_down,
                        value: HealthGoal.loseWeight,
                        selectedGoal: _selectedGoal,
                        onSelected: _selectGoal,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _GoalOption(
                        title: 'Maintain weight',
                        subtitle:
                            'Balance your calories and current lifestyle.',
                        icon: Icons.balance,
                        value: HealthGoal.maintainWeight,
                        selectedGoal: _selectedGoal,
                        onSelected: _selectGoal,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _GoalOption(
                        title: 'Gain muscle',
                        subtitle:
                            'Support training with additional energy and protein.',
                        icon: Icons.fitness_center,
                        value: HealthGoal.gainMuscle,
                        selectedGoal: _selectedGoal,
                        onSelected: _selectGoal,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _GoalOption(
                        title: 'Improve overall health',
                        subtitle:
                            'Build balanced nutrition and healthy habits.',
                        icon: Icons.favorite_outline,
                        value: HealthGoal.improveHealth,
                        selectedGoal: _selectedGoal,
                        onSelected: _selectGoal,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _continue,
                  child: const Text('Next'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GoalOption extends StatelessWidget {
  const _GoalOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.selectedGoal,
    required this.onSelected,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final HealthGoal value;
  final HealthGoal? selectedGoal;
  final ValueChanged<HealthGoal> onSelected;

  bool get isSelected => selectedGoal == value;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerLow,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
      child: InkWell(
        onTap: () => onSelected(value),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
        child: Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMedium),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: isSelected
                    ? colorScheme.primary
                    : colorScheme.surfaceContainerHighest,
                foregroundColor: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
                child: Icon(icon),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              Radio<HealthGoal>(value: value),
            ],
          ),
        ),
      ),
    );
  }
}
