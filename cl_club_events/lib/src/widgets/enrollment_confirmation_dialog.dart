import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Shows a confirmation dialog with optional reason input.
/// Returns the reason string if confirmed, or null if cancelled.
Future<String?> showEnrollmentConfirmationDialog(
  BuildContext context, {
  required String title,
  required String description,
  bool showReasonField = false,
  String confirmLabel = 'Confirm',
}) async {
  final reasonController = TextEditingController();

  final result = await showShadDialog<bool>(
    context: context,
    builder: (context) => ShadDialog(
      title: Text(title),
      description: Text(description),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        ShadButton.destructive(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmLabel),
        ),
      ],
      child: showReasonField
          ? ShadInput(
              controller: reasonController,
              placeholder: const Text('Reason (optional)'),
              keyboardType: TextInputType.text,
            )
          : null,
    ),
  );

  if (result == true) {
    final reason = reasonController.text.trim();
    reasonController.dispose();
    return reason.isEmpty ? '' : reason;
  }

  reasonController.dispose();
  return null;
}
