import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class OnboardingIntroScreen extends StatelessWidget {
  const OnboardingIntroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              IconButton(
                onPressed: context.pop,
                icon: const Icon(Icons.arrow_back),
              ),
              const Spacer(),
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                  color: AppColors.primaryLight,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.eco_outlined,
                  size: 46,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'Let’s personalize Prana',
                style: Theme.of(context).textTheme.headlineLarge,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'We’ll ask a few questions to create calorie, nutrition, '
                'hydration, and activity targets that match your body and goals.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              const _PrivacyRow(
                icon: Icons.lock_outline,
                text: 'Your information stays private.',
              ),
              const SizedBox(height: AppSpacing.md),
              const _PrivacyRow(
                icon: Icons.timer_outlined,
                text: 'Setup takes about two minutes.',
              ),
              const Spacer(),
              FilledButton(
                onPressed: () {
                  context.go('/onboarding/name');
                },
                child: const Text('Continue'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrivacyRow extends StatelessWidget {
  const _PrivacyRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(text, style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }
}
