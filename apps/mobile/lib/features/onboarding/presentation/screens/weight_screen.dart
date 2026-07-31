import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../controllers/onboarding_scope.dart';

enum WeightUnit {
  kilograms,
  pounds,
}

class WeightScreen extends StatefulWidget {
  const WeightScreen({super.key});

  @override
  State<WeightScreen> createState() => _WeightScreenState();
}

class _WeightScreenState extends State<WeightScreen> {
  final _weightController = TextEditingController(text: '75');

  WeightUnit _selectedUnit = WeightUnit.kilograms;
  String? _errorText;

  static const double _kilogramsPerPound = 0.45359237;

  @override
  void dispose() {
    _weightController.dispose();
    super.dispose();
  }

  void _changeUnit(WeightUnit unit) {
    if (unit == _selectedUnit) {
      return;
    }

    final currentValue = double.tryParse(
      _weightController.text.trim(),
    );

    setState(() {
      _errorText = null;

      if (currentValue != null) {
        if (unit == WeightUnit.pounds) {
          final pounds = currentValue / _kilogramsPerPound;
          _weightController.text = pounds.toStringAsFixed(1);
        } else {
          final kilograms = currentValue * _kilogramsPerPound;
          _weightController.text = kilograms.toStringAsFixed(1);
        }
      }

      _selectedUnit = unit;
    });
  }

  double? _getWeightInKilograms() {
    final enteredWeight = double.tryParse(
      _weightController.text.trim(),
    );

    if (enteredWeight == null) {
      return null;
    }

    if (_selectedUnit == WeightUnit.kilograms) {
      return enteredWeight;
    }

    return enteredWeight * _kilogramsPerPound;
  }

  void _continue() {
    FocusScope.of(context).unfocus();

    final weightKg = _getWeightInKilograms();

    if (weightKg == null) {
      setState(() {
        _errorText = 'Enter a valid weight.';
      });
      return;
    }

    if (weightKg < 25 || weightKg > 350) {
      setState(() {
        _errorText = _selectedUnit == WeightUnit.kilograms
            ? 'Enter a weight between 25 and 350 kg.'
            : 'Enter a weight between 55 and 772 lb.';
      });
      return;
    }

    OnboardingScope.of(context).setWeight(weightKg);

    context.push('/onboarding/goal-weight');
  }

  void _clearError() {
    if (_errorText != null) {
      setState(() {
        _errorText = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final suffix =
        _selectedUnit == WeightUnit.kilograms ? 'kg' : 'lb';

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
                value: 5 / 8,
                borderRadius: BorderRadius.circular(20),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                'What is your current weight?',
                style: Theme.of(context).textTheme.headlineMedium,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                'This helps us calculate your metabolism and daily energy needs.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
              const SizedBox(height: AppSpacing.xl),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<WeightUnit>(
                  segments: const [
                    ButtonSegment(
                      value: WeightUnit.kilograms,
                      label: Text('Kilograms'),
                    ),
                    ButtonSegment(
                      value: WeightUnit.pounds,
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
                controller: _weightController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                textInputAction: TextInputAction.done,
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d{0,3}(\.\d{0,1})?'),
                  ),
                ],
                decoration: InputDecoration(
                  labelText: 'Weight',
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