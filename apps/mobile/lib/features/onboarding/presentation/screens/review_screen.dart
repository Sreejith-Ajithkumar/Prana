import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/buttons/prana_button.dart';
import '../../../../core/widgets/layout/progress_header.dart';
import '../controllers/onboarding_scope.dart';

class ReviewScreen extends StatelessWidget {
  const ReviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = OnboardingScope.of(context);
    final state = controller.state;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(
            AppSpacing.screenPadding,
          ),
          child: Column(
            children: [
              const ProgressHeader(
                progress: 1,
                title: 'Review your profile',
                subtitle:
                    'Please make sure everything looks correct.',
              ),
              Expanded(
                child: ListView(
                  children: [
                    _ReviewCard(
                      title: 'Name',
                      value: state.firstName.isEmpty
                          ? 'Not provided'
                          : state.firstName,
                    ),
                    _ReviewCard(
                      title: 'Biological sex',
                      value: _formatEnumName(
                        state.biologicalSex?.name,
                      ),
                    ),
                    _ReviewCard(
                      title: 'Birthday',
                      value: state.dateOfBirth == null
                          ? 'Not provided'
                          : _formatDate(state.dateOfBirth!),
                    ),
                    _ReviewCard(
                      title: 'Height',
                      value: state.heightCm == null
                          ? 'Not provided'
                          : '${state.heightCm!.toStringAsFixed(1)} cm',
                    ),
                    _ReviewCard(
                      title: 'Current weight',
                      value: state.weightKg == null
                          ? 'Not provided'
                          : '${state.weightKg!.toStringAsFixed(1)} kg',
                    ),
                    _ReviewCard(
                      title: 'Goal weight',
                      value: state.goalWeightKg == null
                          ? 'Not provided'
                          : '${state.goalWeightKg!.toStringAsFixed(1)} kg',
                    ),
                    _ReviewCard(
                      title: 'Health goal',
                      value: _formatEnumName(
                        state.goal?.name,
                      ),
                    ),
                    _ReviewCard(
                      title: 'Activity level',
                      value: _formatEnumName(
                        state.activityLevel?.name,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: context.pop,
                  child: const Text('Edit information'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              PranaButton(
                text: 'Finish setup',
                onPressed: () {
                  context.go('/dashboard');
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }

  static String _formatEnumName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Not provided';
    }

    final result = value.replaceAllMapped(
      RegExp(r'([a-z])([A-Z])'),
      (match) => '${match.group(1)} ${match.group(2)}',
    );

    return result[0].toUpperCase() + result.substring(1);
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.title,
    required this.value,
  });

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(
        bottom: AppSpacing.sm,
      ),
      child: ListTile(
        title: Text(title),
        subtitle: Text(value),
      ),
    );
  }
}