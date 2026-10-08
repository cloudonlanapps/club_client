import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The close icon of a dialog that saves while it is open
/// (club_client#113): the look of `ShadDialog`'s own, off while [saving].
///
/// `ShadDialog`'s own icon closes the dialog whatever its
/// `SavingDialogScope` says, so such a dialog passes this as `closeIcon`.
class SavingDialogCloseIcon extends StatelessWidget {
  /// A close icon that does nothing while [saving].
  const SavingDialogCloseIcon({required this.saving, super.key});

  /// The side of the button.
  static const double buttonSize = 20;

  /// The size of the icon in it.
  static const double iconSize = 16;

  /// How faint the icon is until the pointer is on it.
  static const double restingOpacity = .5;

  /// Whether the dialog's save is in flight.
  final bool saving;

  @override
  Widget build(BuildContext context) {
    final foreground = ShadTheme.of(context).colorScheme.foreground;
    return ShadIconButton.ghost(
      icon: const Icon(LucideIcons.x, size: iconSize),
      width: buttonSize,
      height: buttonSize,
      padding: EdgeInsets.zero,
      foregroundColor: foreground.withValues(alpha: restingOpacity),
      hoverBackgroundColor: const Color(0x00000000),
      hoverForegroundColor: foreground,
      pressedForegroundColor: foreground,
      enabled: !saving,
      onPressed: () => Navigator.of(context).maybePop(),
    );
  }
}
