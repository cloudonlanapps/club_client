import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Dialog for entering cancellation reason.
class CancelReasonDialog extends StatefulWidget {
  const CancelReasonDialog({super.key});

  @override
  State<CancelReasonDialog> createState() => CancelReasonDialogState();
}

class CancelReasonDialogState extends State<CancelReasonDialog> {
  final controller = TextEditingController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ShadDialog(
      title: const Text('Cancel Session'),
      description: const Text(
        'This will cancel the session for all participants. '
        'This action cannot be undone. Please provide a reason.',
      ),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back'),
        ),
        ShadButton.destructive(
          onPressed: () => Navigator.of(context).pop(controller.text.trim()),
          child: const Text('Cancel Session'),
        ),
      ],
      child: ShadInput(
        controller: controller,
        placeholder: const Text('e.g., Coach unavailable'),
        autofocus: true,
        keyboardType: TextInputType.multiline,
        minLines: 2,
        maxLines: 3,
      ),
    );
  }
}
