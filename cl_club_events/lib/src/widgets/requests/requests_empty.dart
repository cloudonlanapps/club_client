import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// What a Requests sheet tab shows when it has nothing to list.
class RequestsEmpty extends StatelessWidget {
  const RequestsEmpty({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Text(message, style: ShadTheme.of(context).textTheme.muted),
    ),
  );
}
