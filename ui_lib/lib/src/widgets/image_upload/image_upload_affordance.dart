import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// A small circular icon button (no Material ink) — the building block for the
/// cover/gallery image affordances. Shows a spinner while [busy]; pass a `null`
/// [onTap] to render it disabled (icon shown, taps ignored).
class CircleIconButton extends StatelessWidget {
  const CircleIconButton({
    required this.icon,
    required this.onTap,
    this.busy = false,
    this.size = 36,
    super.key,
  });

  final IconData icon;

  /// Tap handler, or `null` to render the button disabled. [busy] shows the
  /// spinner; disabling without [busy] (e.g. while a sibling control is mid
  /// pick→upload) keeps the icon but ignores taps.
  final VoidCallback? onTap;
  final bool busy;
  final double size;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: busy ? null : onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: theme.colorScheme.background.withValues(alpha: 0.92),
          border: Border.all(color: theme.colorScheme.border),
        ),
        alignment: Alignment.center,
        child: busy
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                icon,
                size: size * 0.44,
                color: theme.colorScheme.foreground,
              ),
      ),
    );
  }
}

/// Pure-UI affordance overlaid on a cover image: a circular pencil to replace
/// it and, when [onRemove] is supplied, a trash button to clear it.
///
/// SDK-free and provider-free — the host (a connected widget in the feature
/// package) wires its media mutation provider, supplies the async actions, and
/// passes the [uploading] flag. The same widget backs the event cover, the
/// venue image, and the group image.
///
/// Owns the re-entrancy guard: while [onReplace] (pick → confirm → upload) is
/// in flight, both controls are disabled so a second tap can't open another
/// file picker. The spinner is shown only while [uploading] (the upload
/// mutation itself), never during the pick/preview phase — so a perpetual
/// spinner never stalls `pumpAndSettle` and the affordance reads as idle until
/// work starts.
class ImageUploadAffordance extends StatefulWidget {
  const ImageUploadAffordance({
    required this.onReplace,
    this.onRemove,
    this.uploading = false,
    super.key,
  });

  /// Runs the full pick → confirm → upload flow. The host owns picking,
  /// confirmation, the SDK call, and its own error toast; this widget only
  /// gates re-entry and resets the guard when the future completes.
  final Future<void> Function() onReplace;

  /// Clears the current image, or `null` when there is nothing to remove (the
  /// trash button is then hidden entirely).
  final Future<void> Function()? onRemove;

  /// Whether the upload mutation is in flight — drives the spinner and disables
  /// both controls.
  final bool uploading;

  @override
  State<ImageUploadAffordance> createState() => _ImageUploadAffordanceState();
}

class _ImageUploadAffordanceState extends State<ImageUploadAffordance> {
  bool _picking = false;

  Future<void> _runReplace() async {
    if (_picking) return;
    setState(() => _picking = true);
    try {
      await widget.onReplace();
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final disabled = _picking || widget.uploading;
    final onRemove = widget.onRemove;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (onRemove != null) ...[
          CircleIconButton(
            icon: LucideIcons.trash2,
            busy: widget.uploading,
            onTap: disabled ? null : onRemove,
          ),
          const SizedBox(width: 8),
        ],
        CircleIconButton(
          icon: LucideIcons.pencil,
          busy: widget.uploading,
          onTap: disabled ? null : _runReplace,
        ),
      ],
    );
  }
}
