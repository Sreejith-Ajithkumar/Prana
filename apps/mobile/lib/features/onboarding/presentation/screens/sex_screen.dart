import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';

class SexScreen extends StatelessWidget {
  const SexScreen({
    required this.firstName,
    super.key,
  });

  final String firstName;

  @override
  Widget build(BuildContext context) {
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
                'Thanks, $firstName',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'What is your biological sex?',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: AppSpacing.xl),
              ListTile(
                title: const Text('Male'),
                onTap: () {},
              ),
              ListTile(
                title: const Text('Female'),
                onTap: () {},
              ),
              ListTile(
                title: const Text('Prefer not to say'),
                onTap: () {},
              ),
              const Spacer(),
              FilledButton(
                onPressed: context.pop,
                child: const Text('Back'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}