import 'dart:async';

import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:flutter/material.dart' show CircularProgressIndicator, Tooltip;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

import '../utils/member_write_messages.dart';
import 'avatar_preview_dialog.dart';

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

/// State of [AvatarUploadAffordance]: the flow from the tap to the upload.
class AvatarUploadAffordanceState
    extends ConsumerState<AvatarUploadAffordance> {
  /// What the control reads on hover and to assistive technology.
  static const String tooltip = 'Change photo';

  /// Diameter of the round control.
  static const double size = 36;

  /// Size of the pencil, and of the spinner that takes its place.
  static const double iconSize = 16;

  /// Guards the pick→preview→upload flow so a second tap on the pencil while
  /// the picker/preview is open can't launch a second file browser. The
  /// mutation provider's `isLoading` only covers the upload itself, not the
  /// picking phase, so it can't stand in for this.
  bool picking = false;

  /// Runs the pick→preview→upload flow, once at a time.
  Future<void> handleTap() async {
    if (picking) return;
    setState(() => picking = true);
    try {
      await pickPreviewUpload();
    } finally {
      if (mounted) setState(() => picking = false);
    }
  }

  /// Picks an image, shows it for confirmation and uploads it.
  Future<void> pickPreviewUpload() async {
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
    // The upload mutation drives the spinner; `picking` only disables the
    // control (so a second tap can't open another picker) without showing a
    // perpetual spinner through the pick/preview phase.
    final uploading = ref
        .watch(avatarMutationProvider(widget.username))
        .isLoading;
    final disabled = picking || uploading;
    return Tooltip(
      message: tooltip,
      child: MouseRegion(
        cursor: disabled ? MouseCursor.defer : SystemMouseCursors.click,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: disabled ? null : handleTap,
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.background.withValues(alpha: 0.92),
              border: Border.all(color: theme.colorScheme.border),
            ),
            alignment: Alignment.center,
            child: uploading
                ? const SizedBox(
                    width: iconSize,
                    height: iconSize,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(
                    LucideIcons.pencil,
                    size: iconSize,
                    color: theme.colorScheme.foreground,
                  ),
          ),
        ),
      ),
    );
  }
}
