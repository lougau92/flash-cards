import 'package:flutter/material.dart'
    show
        Align,
        Alignment,
        BorderRadius,
        BoxDecoration,
        BuildContext,
        Column,
        Container,
        CrossAxisAlignment,
        EdgeInsets,
        StatelessWidget,
        Text,
        TextButton,
        TextStyle,
        Theme,
        VoidCallback,
        Widget;

class ModelLoadMessage extends StatelessWidget {
  const ModelLoadMessage({
    super.key,
    required this.message,
    required this.actionLabel,
    required this.onPressed,
  });

  final String message;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(onPressed: onPressed, child: Text(actionLabel)),
            ),
          ],
        ),
      );
}
