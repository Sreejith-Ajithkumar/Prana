import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../data/profile_storage.dart';
import '../../domain/entities/user_profile.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key, required this.profile});

  final UserProfile profile;

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _firstNameController;

  late final TextEditingController _heightController;

  late final TextEditingController _weightController;

  late final TextEditingController _goalWeightController;

  late DateTime _dateOfBirth;
  late BiologicalSex _biologicalSex;
  late ActivityLevel _activityLevel;
  late HealthGoal _goal;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();

    final profile = widget.profile;

    _firstNameController = TextEditingController(text: profile.firstName);

    _heightController = TextEditingController(
      text: _formatEditableNumber(profile.heightCm),
    );

    _weightController = TextEditingController(
      text: _formatEditableNumber(profile.weightKg),
    );

    _goalWeightController = TextEditingController(
      text: _formatEditableNumber(profile.goalWeightKg),
    );

    _dateOfBirth = profile.dateOfBirth;
    _biologicalSex = profile.biologicalSex;
    _activityLevel = profile.activityLevel;
    _goal = profile.goal;
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    _goalWeightController.dispose();

    super.dispose();
  }

  Future<void> _selectDateOfBirth() async {
    final now = DateTime.now();

    final selectedDate = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth,
      firstDate: DateTime(now.year - 120),
      lastDate: DateTime(now.year - 13, now.month, now.day),
    );

    if (selectedDate == null || !mounted) {
      return;
    }

    setState(() {
      _dateOfBirth = selectedDate;
    });
  }

  Future<void> _saveProfile() async {
    if (_isSaving) {
      return;
    }

    final form = _formKey.currentState;

    if (form == null || !form.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      final updatedProfile = UserProfile(
        firstName: _firstNameController.text.trim(),
        dateOfBirth: _dateOfBirth,
        biologicalSex: _biologicalSex,
        heightCm: double.parse(_heightController.text.trim()),
        weightKg: double.parse(_weightController.text.trim()),
        goalWeightKg: double.parse(_goalWeightController.text.trim()),
        activityLevel: _activityLevel,
        goal: _goal,
      );

      await ProfileStorage.instance.saveProfile(updatedProfile);

      if (!mounted) {
        return;
      }

      context.pop(true);
    } catch (_) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('We could not save your profile. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  String? _validateText(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return 'Enter $fieldName.';
    }

    return null;
  }

  String? _validatePositiveNumber(String? value, String fieldName) {
    final number = double.tryParse(value?.trim() ?? '');

    if (number == null) {
      return 'Enter a valid $fieldName.';
    }

    if (number <= 0) {
      return '$fieldName must be greater than zero.';
    }

    return null;
  }

  String get _formattedDateOfBirth {
    final month = _dateOfBirth.month.toString().padLeft(2, '0');

    final day = _dateOfBirth.day.toString().padLeft(2, '0');

    return '${_dateOfBirth.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit profile & goals')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            children: [
              Text(
                'Personal information',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _firstNameController,
                decoration: const InputDecoration(labelText: 'First name'),
                validator: (value) {
                  return _validateText(value, 'your first name');
                },
              ),

              const SizedBox(height: 16),

              InkWell(
                onTap: _selectDateOfBirth,
                borderRadius: BorderRadius.circular(12),
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Date of birth',
                    suffixIcon: Icon(Icons.calendar_today_outlined),
                  ),
                  child: Text(_formattedDateOfBirth),
                ),
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<BiologicalSex>(
                initialValue: _biologicalSex,
                decoration: const InputDecoration(
                  labelText: 'Calculation basis',
                ),
                items: BiologicalSex.values.map((sex) {
                  return DropdownMenuItem(
                    value: sex,
                    child: Text(_formatBiologicalSex(sex)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _biologicalSex = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _heightController,
                decoration: const InputDecoration(
                  labelText: 'Height',
                  suffixText: 'cm',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d{0,3}(\.\d{0,1})?'),
                  ),
                ],
                validator: (value) {
                  return _validatePositiveNumber(value, 'height');
                },
              ),

              const SizedBox(height: 24),

              Text(
                'Weight',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 6),

              Text(
                'For now, this is the reference weight used for your nutrition calculations. Weight history and trend tracking will be added separately.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _weightController,
                decoration: const InputDecoration(
                  labelText: 'Reference weight',
                  suffixText: 'kg',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d{0,3}(\.\d{0,1})?'),
                  ),
                ],
                validator: (value) {
                  return _validatePositiveNumber(value, 'weight');
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _goalWeightController,
                decoration: const InputDecoration(
                  labelText: 'Goal weight',
                  suffixText: 'kg',
                ),
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(
                    RegExp(r'^\d{0,3}(\.\d{0,1})?'),
                  ),
                ],
                validator: (value) {
                  return _validatePositiveNumber(value, 'goal weight');
                },
              ),

              const SizedBox(height: 24),

              Text(
                'Goals & activity',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<HealthGoal>(
                initialValue: _goal,
                decoration: const InputDecoration(labelText: 'Health goal'),
                items: HealthGoal.values.map((goal) {
                  return DropdownMenuItem(
                    value: goal,
                    child: Text(_formatGoal(goal)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _goal = value;
                  });
                },
              ),

              const SizedBox(height: 16),

              DropdownButtonFormField<ActivityLevel>(
                initialValue: _activityLevel,
                decoration: const InputDecoration(labelText: 'Activity level'),
                items: ActivityLevel.values.map((activity) {
                  return DropdownMenuItem(
                    value: activity,
                    child: Text(_formatActivityLevel(activity)),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }

                  setState(() {
                    _activityLevel = value;
                  });
                },
              ),

              const SizedBox(height: 24),

              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.auto_graph_outlined,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          'After saving, Prana will recalculate your estimated calorie, macro, and hydration targets from this profile.',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 32),

              FilledButton(
                onPressed: _isSaving ? null : _saveProfile,
                child: _isSaving
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Save changes'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatEditableNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.toStringAsFixed(0);
    }

    return value.toStringAsFixed(1);
  }

  static String _formatBiologicalSex(BiologicalSex value) {
    return switch (value) {
      BiologicalSex.male => 'Male',
      BiologicalSex.female => 'Female',
      BiologicalSex.unspecified => 'Not specified',
    };
  }

  static String _formatGoal(HealthGoal value) {
    return switch (value) {
      HealthGoal.loseWeight => 'Weight loss',
      HealthGoal.maintainWeight => 'Maintain weight',
      HealthGoal.gainMuscle => 'Gain muscle',
      HealthGoal.improveHealth => 'Improve health',
    };
  }

  static String _formatActivityLevel(ActivityLevel value) {
    return switch (value) {
      ActivityLevel.sedentary => 'Sedentary',
      ActivityLevel.lightlyActive => 'Lightly active',
      ActivityLevel.moderatelyActive => 'Moderately active',
      ActivityLevel.veryActive => 'Very active',
      ActivityLevel.athlete => 'Athlete',
    };
  }
}
