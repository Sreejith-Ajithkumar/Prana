import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../controllers/onboarding_scope.dart';
import '../../../../core/widgets/buttons/prana_button.dart';
import '../../../../core/widgets/layout/progress_header.dart';

enum HeightUnit {
  metric,
  imperial,
}

class HeightScreen extends StatefulWidget {
  const HeightScreen({super.key});

  @override
  State<HeightScreen> createState() => _HeightScreenState();
}

class _HeightScreenState extends State<HeightScreen> {
  final _centimetersController = TextEditingController(text: '175');
  final _feetController = TextEditingController(text: '5');
  final _inchesController = TextEditingController(text: '9');

  HeightUnit _selectedUnit = HeightUnit.metric;
  String? _errorText;

  @override
  void dispose() {
    _centimetersController.dispose();
    _feetController.dispose();
    _inchesController.dispose();
    super.dispose();
  }

  void _changeUnit(HeightUnit unit) {
    if (unit == _selectedUnit) {
      return;
    }

    setState(() {
      _errorText = null;

      if (unit == HeightUnit.imperial) {
        _convertCentimetersToImperial();
      } else {
        _convertImperialToCentimeters();
      }

      _selectedUnit = unit;
    });
  }

  void _convertCentimetersToImperial() {
    final centimeters = double.tryParse(
      _centimetersController.text.trim(),
    );

    if (centimeters == null) {
      return;
    }

    final totalInches = centimeters / 2.54;
    final feet = totalInches ~/ 12;
    final inches = (totalInches - feet * 12).round();

    if (inches == 12) {
      _feetController.text = (feet + 1).toString();
      _inchesController.text = '0';
    } else {
      _feetController.text = feet.toString();
      _inchesController.text = inches.toString();
    }
  }

  void _convertImperialToCentimeters() {
    final feet = int.tryParse(_feetController.text.trim());
    final inches = double.tryParse(_inchesController.text.trim());

    if (feet == null || inches == null) {
      return;
    }

    final centimeters = ((feet * 12) + inches) * 2.54;

    _centimetersController.text = centimeters.toStringAsFixed(1);
  }

  double? _getHeightInCentimeters() {
    if (_selectedUnit == HeightUnit.metric) {
      return double.tryParse(
        _centimetersController.text.trim(),
      );
    }

    final feet = int.tryParse(_feetController.text.trim());
    final inches = double.tryParse(_inchesController.text.trim());

    if (feet == null || inches == null) {
      return null;
    }

    if (inches < 0 || inches >= 12) {
      return null;
    }

    return ((feet * 12) + inches) * 2.54;
  }

  void _continue() {
    FocusScope.of(context).unfocus();

    final heightCm = _getHeightInCentimeters();

    if (heightCm == null) {
      setState(() {
        _errorText = _selectedUnit == HeightUnit.metric
            ? 'Enter a valid height.'
            : 'Enter valid feet and inches. Inches must be between 0 and 11.';
      });
      return;
    }

    if (heightCm < 50 || heightCm > 300) {
      setState(() {
        _errorText = 'Enter a height between 50 and 300 cm.';
      });
      return;
    }

    OnboardingScope.of(context).setHeight(heightCm);

    context.push('/onboarding/weight');
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
               const ProgressHeader(
                progress: 4 / 8,
                title: 'How tall are you?',
                subtitle:
                    'We use your height to calculate your daily calorie needs.',
              ),
              SizedBox(
                width: double.infinity,
                child: SegmentedButton<HeightUnit>(
                  segments: const [
                    ButtonSegment(
                      value: HeightUnit.metric,
                      label: Text('Centimeters'),
                    ),
                    ButtonSegment(
                      value: HeightUnit.imperial,
                      label: Text('Feet & inches'),
                    ),
                  ],
                  selected: {_selectedUnit},
                  onSelectionChanged: (selection) {
                    _changeUnit(selection.first);
                  },
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              if (_selectedUnit == HeightUnit.metric)
                TextField(
                  controller: _centimetersController,
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
                    labelText: 'Height',
                    suffixText: 'cm',
                    errorText: _errorText,
                  ),
                  onChanged: (_) => _clearError(),
                  onSubmitted: (_) => _continue(),
                )
              else ...[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _feetController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          LengthLimitingTextInputFormatter(1),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Feet',
                          suffixText: 'ft',
                        ),
                        onChanged: (_) => _clearError(),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: TextField(
                        controller: _inchesController,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.done,
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(
                            RegExp(r'^\d{0,2}(\.\d{0,1})?'),
                          ),
                        ],
                        decoration: const InputDecoration(
                          labelText: 'Inches',
                          suffixText: 'in',
                        ),
                        onChanged: (_) => _clearError(),
                        onSubmitted: (_) => _continue(),
                      ),
                    ),
                  ],
                ),
                if (_errorText != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _errorText!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.error,
                        ),
                  ),
                ],
              ],
              const Spacer(),
              SizedBox(
                width: double.infinity,
                child: PranaButton(
                  text: 'Next',
                  onPressed: _continue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}