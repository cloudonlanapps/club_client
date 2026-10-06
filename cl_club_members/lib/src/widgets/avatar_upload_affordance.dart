import 'dart:async';
import 'dart:typed_data';

import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

import '../utils/member_write_messages.dart';

/// Picker function returning a [PickedImage] or `null` when the user
/// cancels. Production callers should not override this; tests can.
typedef AvatarImagePicker = Future<PickedImage?> Function();

/// Pencil overlay that lets the signed-in user replace their own avatar, or
/// an admin replace a member's ([onBehalf], club_client#35).
///
/// Renders a small circular pencil button (bottom-right by default in the
/// parent stack). On tap:
///
/// 1. opens [picker] (jpeg/png/webp);
/// 2. shows a preview dialog with the selected image and an "Allow others
///    to see my photo" checkbox;
/// 3. on confirm, dispatches `avatarMutationProvider(username).upload(...)`.
///
/// With [onBehalf] the preview has no checkbox and the confirm dispatches
/// `uploadOnBehalf(...)`: the photo is stored private in the member's name,
/// and making it public stays the member's choice.
///
/// The pencil is disabled for the whole pick→preview→upload flow (not just
/// the upload) so the user can't fire a second file browser mid-flight.
class AvatarUploadAffordance extends ConsumerStatefulWidget {
  const AvatarUploadAffordance({
    required this.username,
    this.onBehalf = false,
    this.picker,
    super.key,
  });

  final String username;

  /// True when an admin is changing another member's photo.
  final bool onBehalf;

  /// Overrides the image picker. When null the shared [imagePickerProvider] is
  /// used — tests inject one; production passes nothing.
  final AvatarImagePicker? picker;

  @override
  ConsumerState<AvatarUploadAffordance> createState() =>
      AvatarUploadAffordanceState();
}

class AvatarUploadAffordanceState
    extends ConsumerState<AvatarUploadAffordance> {
  /// Guards the pick→preview→upload flow so a second tap on the pencil while
  /// the picker/preview is open can't launch a second file browser. The
  /// mutation provider's `isLoading` only covers the upload itself, not the
  /// picking phase, so it can't stand in for this.
  bool _picking = false;

  Future<void> _handleTap() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      await _pickPreviewUpload();
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _pickPreviewUpload() async {
    final picked = await pickImageReportingErrors(
      context,
      picker: widget.picker ?? ref.read(imagePickerProvider),
    );
    if (!mounted || picked == null) return;
    // Snapshot the user's previous visibility choice so the checkbox is
    // pre-ticked when they're upgrading an already-public avatar. The
    // .future read awaits the FutureProvider so the dialog opens with
    // the resolved value rather than racing on cache state.
    var initialAllowOthersToSee = false;
    if (!widget.onBehalf) {
      try {
        initialAllowOthersToSee = await ref.read(
          avatarVisibilityProvider(widget.username).future,
        );
      } on Object {
        initialAllowOthersToSee = false;
      }
    }
    if (!mounted) return;
    final decision = await showPreviewDialog(
      context,
      picked,
      initialAllowOthersToSee: initialAllowOthersToSee,
      showVisibilityChoice: !widget.onBehalf,
    );
    if (!mounted || decision == null) return;
    final notifier = ref.read(avatarMutationProvider(widget.username).notifier);
    try {
      if (widget.onBehalf) {
        await notifier.uploadOnBehalf(
          bytes: picked.bytes,
          filename: picked.filename,
          contentType: picked.mimeType,
        );
      } else {
        await notifier.upload(
          bytes: picked.bytes,
          filename: picked.filename,
          contentType: picked.mimeType,
          allowOthersToSee: decision.allowOthersToSee,
        );
      }
    } on Object catch (e) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(
            writeFailureMessage(e, fallback: MemberWriteMessages.photoFailed),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    // The upload mutation drives the spinner; `_picking` only disables the
    // control (so a second tap can't open another picker) without showing a
    // perpetual spinner through the pick/preview phase.
    final uploading = ref
        .watch(avatarMutationProvider(widget.username))
        .isLoading;
    final disabled = _picking || uploading;
    return Material(
      color: Colors.transparent,
      child: Tooltip(
        message: 'Change photo',
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: disabled ? null : _handleTap,
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.background.withValues(alpha: 0.92),
              border: Border.all(color: theme.colorScheme.border),
            ),
            alignment: Alignment.center,
            child: uploading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    Icons.edit,
                    size: 16,
                    color: theme.colorScheme.foreground,
                  ),
          ),
        ),
      ),
    );
  }
}

class PreviewDecision {
  const PreviewDecision({required this.allowOthersToSee});
  final bool allowOthersToSee;
}

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

class AvatarPreviewDialog extends StatefulWidget {
  const AvatarPreviewDialog({
    required this.picked,
    required this.initialAllowOthersToSee,
    this.showVisibilityChoice = true,
    super.key,
  });
  final PickedImage picked;
  final bool initialAllowOthersToSee;

  /// Whether the "Allow others to see my photo" checkbox is offered. False
  /// for an admin changing a member's photo (club_client#35).
  final bool showVisibilityChoice;

  @override
  State<AvatarPreviewDialog> createState() => AvatarPreviewDialogState();
}

class AvatarPreviewDialogState extends State<AvatarPreviewDialog> {
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
                  onPressed: () => Navigator.of(context).pop(
                    PreviewDecision(allowOthersToSee: allowOthersToSee),
                  ),
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
