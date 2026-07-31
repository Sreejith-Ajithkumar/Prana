import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';

import 'package:go_router/go_router.dart';

class NameScreen extends StatefulWidget {
  const NameScreen({super.key});

  @override
  State<NameScreen> createState() => _NameScreenState();
}

class _NameScreenState extends State<NameScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _continue() {
  if (!_formKey.currentState!.validate()) {
    return;
  }

  final firstName = _nameController.text.trim();

  context.push(
    '/onboarding/sex',
    extra: firstName,
  );
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('About you'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.screenPadding),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LinearProgressIndicator(
                  value: 1 / 8,
                  borderRadius: BorderRadius.circular(20),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'What should we call you?',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  'This will be used to personalize your dashboard.',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: AppSpacing.xl),
                TextFormField(
                  controller: _nameController,
                  autofocus: true,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.done,
                  decoration: const InputDecoration(
                    labelText: 'First name',
                    hintText: 'Enter your first name',
                  ),
                  validator: (value) {
                    final name = value?.trim() ?? '';

                    if (name.isEmpty) {
                      return 'Please enter your first name.';
                    }

                    if (name.length < 2) {
                      return 'Name must contain at least two characters.';
                    }

                    return null;
                  },
                  onFieldSubmitted: (_) => _continue(),
                ),
                const Spacer(),
                FilledButton(
                  onPressed: _continue,
                  child: const Text('Next'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}