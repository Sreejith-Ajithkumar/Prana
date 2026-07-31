import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../controllers/onboarding_scope.dart';

enum GoalWeightUnit {
  kilograms,
  pounds,
}

class GoalWeightScreen extends StatefulWidget {
  const GoalWeightScreen({super.key});

  @override
  State<GoalWeightScreen> createState() => _GoalWeightScreenState();
}

class _GoalWeightScreenState extends State<GoalWeightScreen> {
  final TextEditingController _goalWeightController =
      TextEditingController();

  GoalWeightUnit _selectedUnit = GoalWeightUnit.kilograms;
  String? _errorText;

  static const double _kilogramsPerPound = 0.45359237;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_goalWeightController.text.isEmpty) {
      final currentWeightKg =
          OnboardingScope.of(context).state.weightKg;

      if (currentWeightKg != null) {
        _goalWeightController.text =
            currentWeightKg.toStringAsFixed(1);
      } else {
        _goalWeightController.text = '70';
      }
    }
  }

  @override
  void dispose() {
    _goalWeightController.dispose();
    super.dispose();
  }

  void _changeUnit(GoalWeightUnit unit) {
    if (unit == _selectedUnit) {
      return;
    }

    final value = double.tryParse(
      _goalWeightController.text.trim(),
    );

    setState(() {
      _errorText = null;

      if (value != null) {
        if (unit == GoalWeightUnit.pounds) {
          final pounds = value / _kilogramsPerPound;
          _goalWeightController.text =
              pounds.toStringAsFixed(1);
        } else {
          final kilograms = value * _kilogramsPerPound;
          _goalWeightController.text =
              kilograms.toStringAsFixed(1);
        }
      }

      _selectedUnit = unit;
    });
  }

  double? _getGoalWeightInKilograms() {
    final enteredWeight = double.tryParse(
      _goalWeightController.text.trim(),
    );

    if (enteredWeight == null) {
      return null;
    }

    if (_selectedUnit == GoalWeightUnit.kilograms) {
      return enteredWeight;
    }

    return enteredWeight * _kilogramsPerPound;
  }

  void _continue() {
    FocusScope.of(context).unfocus();

    final goalWeightKg = _getGoalWeightInKilograms();

    if (goalWeightKg == null) {
      setState(() {
        _errorText = 'Enter a valid goal weight.';
      });
      return;
    }

    if (goalWeightKg < 25 || goalWeightKg > 350) {
      setState(() {
        _errorText =
            _selectedUnit == GoalWeightUnit.kilograms
                ? 'Enter a weight between 25 and 350 kg.'
                : 'Enter a weight between 55 and 772 lb.';
      });
      return;
    }

    OnboardingScope.of(context).setGoalWeight(goalWeightKg);

    context.push('/onboarding/goal');
  }

  void _clearError() {
    if (_errorText == null) {
      return;
    }

    setState(() {
      _errorText = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final suffix =
        _selectedUnit == GoalWeightUnit.kilograms
            ? 'kg'
            : 'lb';

    return Scaffold(
      appBar: AppBar(
        title: const Text('About you'),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(
            AppSpacing.screenPadding,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              LinearProgressIndicator(
                value: 6 / 8,
                borderRadius: BorderRadius.circular(20),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'What is your goal weight?',
                style:
                    Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'Your goal helps us personalize your daily calorie target.',
                style: Theme.of(context)
                    .textTheme
                    .bodyLarge
                    ?.copyWith(
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<GoalWeightUnit>(
                  segments: const [
                    ButtonSegment(
                      value: GoalWeightUnit.kilograms,
                      label: Text('Kilograms'),
                    ),
                    ButtonSegment(
                      value: GoalWeightUnit.pounds,
                      label: Text('Pounds'),
                    ),
                  ],
                  selected: {_selectedUnit},
                  onSelectionChanged: (selection) {
                    _changeUnit(selection.first);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              TextField(
                controller: _goalWeightController,
                keyboardType:
                    const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d{0,3}(\.\d{0,1})?'),
                  ),
                ],
                decoration: InputDecoration(
                  labelText: 'Goal weight',
                  suffixText: suffix,
                  errorText: _errorText,
                ),
                onChanged: (_) => _clearError(),
                onSubmitted: (_) => _continue(),
              ),
              const Spacer(),
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