import 'package:club_sdk_2/club_sdk_2.dart' show ConflictReport;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/schedule_clash_gate.dart';
import 'schedule_clash_group.dart';

/// The one dialog every schedule or staff save shows when the server
/// refuses it as a clash (club_server#72): the clashing events grouped by
/// venue, organizer and coach, each with the dates and times that overlap.
///
/// **Save anyway** pops `true`, and the caller sends the same request again
/// with `acceptConflicts: true`; **Cancel**, or dismissing the dialog, pops
/// `false` and the caller goes back to its form as it was.
class ScheduleClashDialog extends StatelessWidget {
  /// Shows the clashes [report] lists.
  const ScheduleClashDialog({required this.report, super.key});

  /// The clashes the server found.
  final ConflictReport report;

  /// The dialog's title.
  static const String title = 'Schedule clash';

  /// What the dialog asks.
  static const String description =
      'This clashes with other events. Save it anyway, or cancel and '
      'change it.';

  /// The label of the action that saves with the clash accepted.
  static const String saveAnywayLabel = 'Save anyway';

  /// The label of the action that goes back to the form.
  static const String cancelLabel = 'Cancel';

  /// The widest the list of clashes grows.
  static const double maxWidth = 520;

  /// The tallest the list of clashes grows before it scrolls.
  static const double maxHeight = 420;

  /// The space between two gates' groups.
  static const double groupSpacing = 16;

  /// Shows the dialog for [report] over [context]; `true` when the
  /// organizer chose Save anyway.
  static Future<bool> show(
    BuildContext context, {
    required ConflictReport report,
  }) async {
    final accepted = await showShadDialog<bool>(
      context: context,
      builder: (_) => ScheduleClashDialog(report: report),
    );
    return accepted ?? false;
  }

  @override
  Widget build(BuildContext context) {
    final gates = [
      for (final gate in ScheduleClashGate.values)
        if (gate.itemsOf(report).isNotEmpty) gate,
    ];
    return ShadDialog(
      title: const Text(title),
      description: const Text(description),
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text(cancelLabel),
        ),
        ShadButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text(saveAnywayLabel),
        ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: maxWidth,
          maxHeight: maxHeight,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final (index, gate) in gates.indexed) ...[
                if (index > 0) const SizedBox(height: groupSpacing),
                ScheduleClashGroup(gate: gate, items: gate.itemsOf(report)),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
