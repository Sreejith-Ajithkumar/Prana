import 'package:flutter/material.dart';

class CalculationInfoSheet extends StatelessWidget {
  const CalculationInfoSheet({
    super.key,
    required this.title,
    required this.description,
    required this.formula,
    required this.calculation,
    required this.result,
    this.reference,
  });

  final String title;
  final String description;
  final String formula;
  final String calculation;
  final String result;
  final String? reference;

  static Future<void> show(
    BuildContext context, {
    required String title,
    required String description,
    required String formula,
    required String calculation,
    required String result,
    String? reference,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return CalculationInfoSheet(
          title: title,
          description: description,
          formula: formula,
          calculation: calculation,
          result: result,
          reference: reference,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 12),
            Text(description),
            const SizedBox(height: 24),
            _InfoSection(title: 'Formula', value: formula),
            _InfoSection(title: 'Your calculation', value: calculation),
            _InfoSection(title: 'Estimated result', value: result),
            if (reference != null)
              _InfoSection(title: 'Method', value: reference!),
            const SizedBox(height: 8),
            Text(
              'This value is an estimate and may differ from your actual needs.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({required this.title, required this.value});

  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          SelectableText(value),
        ],
      ),
    );
  }
}
