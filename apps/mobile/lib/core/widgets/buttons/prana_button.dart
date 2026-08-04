import 'package:flutter/material.dart';

import '../../design/animation.dart';
import '../../design/radius.dart';
import '../../design/spacing.dart';

class PranaButton extends StatelessWidget {
  const PranaButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
    this.expand = true,
  });

  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    Widget button = FilledButton(
      onPressed: isLoading ? null : onPressed,
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 56),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(PranaRadius.medium),
        ),
      ),
      child: AnimatedSwitcher(
        duration: PranaAnimation.fast,
        child: isLoading
            ? const SizedBox(
                key: ValueKey('loading'),
                height: 22,
                width: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Row(
                key: const ValueKey('text'),
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon),
                    const SizedBox(width: PranaSpacing.sm),
                  ],
                  Text(text),
                ],
              ),
      ),
    );

    if (expand) {
      return SizedBox(width: double.infinity, child: button);
    }

    return button;
  }
}
