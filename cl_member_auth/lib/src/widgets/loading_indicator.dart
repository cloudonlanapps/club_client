import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Centered spinner with an optional message. Used during auth loading states.
class LoadingIndicator extends StatelessWidget {
  const LoadingIndicator({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(message!, style: theme.textTheme.p),
          ],
        ],
      ),
    );
  }
}
