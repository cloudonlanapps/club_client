import 'package:flutter/widgets.dart';

/// Keeps a dialog open while its save is in flight (club_client#113).
///
/// A dialog that saves while it is open wraps its `ShadDialog` in this and
/// gives the dialog a `SavingDialogCloseIcon` as its close icon. While
/// [saving] is true a tap outside, Escape and system back close nothing;
/// the close icon is off. The dialog itself still closes with
/// `Navigator.pop` once the save ends.
class SavingDialogScope extends StatelessWidget {
  /// Blocks dismissal of [child], a dialog, while [saving].
  const SavingDialogScope({
    required this.saving,
    required this.child,
    super.key,
  });

  /// Whether the dialog's save is in flight.
  final bool saving;

  /// The dialog.
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return PopScope<Object?>(canPop: !saving, child: child);
  }
}
