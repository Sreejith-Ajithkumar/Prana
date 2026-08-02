import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_spacing.dart';
import '../controllers/onboarding_scope.dart';
import '../../../../core/widgets/layout/progress_header.dart';

class DateOfBirthScreen extends StatefulWidget {
  const DateOfBirthScreen({
    super.key,
  });

  @override
  State<DateOfBirthScreen> createState() => _DateOfBirthScreenState();
}

class _DateOfBirthScreenState extends State<DateOfBirthScreen> {
  DateTime? selectedDate;

  Future<void> _pickDate() async {
    final now = DateTime.now();

    final result = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
    );

    if (result != null) {
      setState(() {
        selectedDate = result;
      });
    }
  }

  void _continue() {
    if (selectedDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your birthday.'),
        ),
      );
      return;
    }

    final controller = OnboardingScope.of(context);

    controller.setDateOfBirth(selectedDate!);

    context.push('/onboarding/height');
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
                  progress: 3 / 8,
                  title: 'When is your birthday?',
                  subtitle:
                      'Your age helps us calculate your calorie needs.',
                ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _pickDate,
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: Text(
                    selectedDate == null
                        ? 'Select birthday'
                        : _formatDate(selectedDate!),
                  ),
                ),
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
    );
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year}';
  }
}