import 'package:flutter/material.dart';

import '../../design/radius.dart';
import '../../design/spacing.dart';

class ProgressHeader extends StatelessWidget {
  const ProgressHeader({
    super.key,
    required this.progress,
    required this.title,
    required this.subtitle,
  });

  final double progress;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: progress,
          borderRadius: BorderRadius.circular(
            PranaRadius.large,
          ),
        ),

        const SizedBox(
          height: PranaSpacing.xl,
        ),

        Text(
          title,
          style: Theme.of(context).textTheme.headlineMedium,
        ),

        const SizedBox(
          height: PranaSpacing.sm,
        ),

        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurfaceVariant,
              ),
        ),

        const SizedBox(
          height: PranaSpacing.xl,
        ),
      ],
    );
  }
}