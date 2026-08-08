import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/buttons/prana_button.dart';
import '../../../../core/widgets/layout/progress_header.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../controllers/onboarding_scope.dart';

class ActivityLevelScreen extends StatefulWidget {
  const ActivityLevelScreen({super.key});

  @override
  State<ActivityLevelScreen> createState() => _ActivityLevelScreenState();
}

class _ActivityLevelScreenState extends State<ActivityLevelScreen> {
  ActivityLevel? _selectedLevel;

  void _selectLevel(ActivityLevel level) {
    setState(() {
      _selectedLevel = level;
    });
  }

  void _continue() {
    final selectedLevel = _selectedLevel;

    if (selectedLevel == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your activity level.')),
      );
      return;
    }

    OnboardingScope.of(context).setActivityLevel(selectedLevel);

    context.push('/onboarding/review');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Activity level')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const ProgressHeader(
                progress: 8 / 9,
                title: 'How active are you?',
                subtitle:
                    'Choose the option that best matches your usual week.',
              ),
              Expanded(
                child: RadioGroup<ActivityLevel>(
                  groupValue: _selectedLevel,
                  onChanged: (value) {
                    if (value != null) {
                      _selectLevel(value);
                    }
                  },
                  child: ListView(
                    children: [
                      _ActivityOption(
                        title: 'Mostly sitting',
                        subtitle: 'Little or no planned exercise.',
                        icon: Icons.weekend_outlined,
                        value: ActivityLevel.sedentary,
                        selectedLevel: _selectedLevel,
                        onSelected: _selectLevel,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ActivityOption(
                        title: 'Lightly active',
                        subtitle: 'Light exercise 1–3 days per week.',
                        icon: Icons.directions_walk,
                        value: ActivityLevel.lightlyActive,
                        selectedLevel: _selectedLevel,
                        onSelected: _selectLevel,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ActivityOption(
                        title: 'Moderately active',
                        subtitle: 'Exercise 3–5 days per week.',
                        icon: Icons.directions_run,
                        value: ActivityLevel.moderatelyActive,
                        selectedLevel: _selectedLevel,
                        onSelected: _selectLevel,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ActivityOption(
                        title: 'Very active',
                        subtitle: 'Hard exercise most days.',
                        icon: Icons.fitness_center,
                        value: ActivityLevel.veryActive,
                        selectedLevel: _selectedLevel,
                        onSelected: _selectLevel,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      _ActivityOption(
                        title: 'Athlete',
                        subtitle:
                            'Intense training or a highly physical lifestyle.',
                        icon: Icons.sports_gymnastics,
                        value: ActivityLevel.athlete,
                        selectedLevel: _selectedLevel,
                        onSelected: _selectLevel,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              PranaButton(text: 'Next', onPressed: _continue),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActivityOption extends StatelessWidget {
  const _ActivityOption({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.selectedLevel,
    required this.onSelected,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final ActivityLevel value;
  final ActivityLevel? selectedLevel;
  final ValueChanged<ActivityLevel> onSelected;

  bool get isSelected => selectedLevel == value;

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
              CircleAvatar(child: Icon(icon)),
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
              Radio<ActivityLevel>(value: value),
            ],
          ),
        ),
      ),
    );
  }
}
