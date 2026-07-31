import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../profile/domain/entities/user_profile.dart';
import '../controllers/onboarding_scope.dart';

class SexScreen extends StatelessWidget {
  const SexScreen({super.key});

  void _selectSex(
    BuildContext context,
    BiologicalSex biologicalSex,
  ) {
    final controller = OnboardingScope.of(context);

    controller.setBiologicalSex(biologicalSex);

    context.push('/onboarding/birthday');
  }

  @override
  Widget build(BuildContext context) {
    final controller = OnboardingScope.of(context);
    final firstName = controller.state.firstName;

    return Scaffold(
      appBar: AppBar(
        title: const Text('About you'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: 2 / 8,
                borderRadius: BorderRadius.circular(20),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                firstName.isEmpty ? 'Tell us about you' : 'Thanks, $firstName',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'What is your biological sex?',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: AppSpacing.xl),
              _SexOption(
                label: 'Male',
                onTap: () {
                  _selectSex(
                    context,
                    BiologicalSex.male,
                  );
                },
              ),
              _SexOption(
                label: 'Female',
                onTap: () {
                  _selectSex(
                    context,
                    BiologicalSex.female,
                  );
                },
              ),
              _SexOption(
                label: 'Prefer not to say',
                onTap: () {
                  _selectSex(
                    context,
                    BiologicalSex.unspecified,
                  );
                },
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    context.pop();
                  },
                  child: const Text('Back'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SexOption extends StatelessWidget {
  const _SexOption({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.lg,
            ),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              label,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
      ),
    );
  }
}