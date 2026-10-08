import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

import '../models/preview_decision.dart';
import '../utils/member_write_messages.dart';

/// Opens [AvatarPreviewDialog] for [picked] and returns what the user
/// decided, or null when they cancelled.
Future<PreviewDecision?> showPreviewDialog(
  BuildContext context,
  PickedImage picked, {
  required bool initialAllowOthersToSee,
  bool showVisibilityChoice = true,
}) {
  return showShadDialog<PreviewDecision>(
    context: context,
    builder: (_) => AvatarPreviewDialog(
      picked: picked,
      initialAllowOthersToSee: initialAllowOthersToSee,
      showVisibilityChoice: showVisibilityChoice,
    ),
  );
}

/// Shows the image the user picked for their profile photo, and asks them to
/// confirm it. Pops a [PreviewDecision] on OK and nothing on Cancel.
class AvatarPreviewDialog extends StatefulWidget {
  const AvatarPreviewDialog({
    required this.picked,
    required this.initialAllowOthersToSee,
    this.showVisibilityChoice = true,
    super.key,
  });

  /// The image to confirm.
  final PickedImage picked;

  /// Whether the checkbox starts ticked.
  final bool initialAllowOthersToSee;

  /// Whether the "Allow others to see my photo" checkbox is offered. False
  /// for an admin changing a member's photo (club_client#35).
  final bool showVisibilityChoice;

  @override
  State<AvatarPreviewDialog> createState() => AvatarPreviewDialogState();
}

/// State of [AvatarPreviewDialog]: the visibility choice as it stands.
class AvatarPreviewDialogState extends State<AvatarPreviewDialog> {
  /// Whether the checkbox is ticked.
  late bool allowOthersToSee = widget.initialAllowOthersToSee;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadDialog(
      title: const Text('Update profile photo'),
      child: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: AspectRatio(
                aspectRatio: 1,
                // Contain so the user sees the whole image they picked.
                // Matches the BoxFit choice on the rendered avatar (#567).
                child: Image.memory(
                  Uint8List.fromList(widget.picked.bytes),
                  fit: BoxFit.contain,
                ),
              ),
            ),
            if (widget.showVisibilityChoice) ...[
              const SizedBox(height: 16),
              ShadCheckbox(
                value: allowOthersToSee,
                onChanged: (v) => setState(() => allowOthersToSee = v),
                label: Text(
                  MemberWriteMessages.allowOthersToSeePhoto,
                  style: theme.textTheme.small,
                ),
              ),
            ],
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                ShadButton.ghost(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                const SizedBox(width: 8),
                ShadButton(
                  onPressed: () => Navigator.of(
                    context,
                  ).pop(PreviewDecision(allowOthersToSee: allowOthersToSee)),
                  child: const Text('OK'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
