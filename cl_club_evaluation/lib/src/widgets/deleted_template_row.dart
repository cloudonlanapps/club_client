import 'dart:async';

import 'package:club_sdk_2/club_sdk_2.dart' show EvaluationTemplate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_lib/ui_lib.dart' show ActionItem;

import '../constants/template_restore_strings.dart';
import '../utils/evaluation_template_actions.dart';
import 'template_row.dart';

/// One deleted template of the library (club_client#277): it does not open,
/// and offers **Restore** to any staff member, busy while the restore runs.
class DeletedTemplateRow extends ConsumerStatefulWidget {
  /// A row for deleted [template].
  const DeletedTemplateRow({required this.template, super.key});

  /// The deleted template.
  final EvaluationTemplate template;

  @override
  ConsumerState<DeletedTemplateRow> createState() => DeletedTemplateRowState();
}

/// Holds whether the row's restore is running.
class DeletedTemplateRowState extends ConsumerState<DeletedTemplateRow> {
  /// Whether **Restore** is running.
  bool restoring = false;

  /// Restores the template, the toast naming the name it came back under.
  Future<void> restore() async {
    setState(() => restoring = true);
    await EvaluationTemplateActions.restore(context, ref, widget.template);
    if (mounted) setState(() => restoring = false);
  }

  @override
  Widget build(BuildContext context) => TemplateRow(
    template: widget.template,
    actions: [
      ActionItem(
        label: TemplateRestoreStrings.restore,
        loading: restoring,
        onPressed: () => unawaited(restore()),
      ),
    ],
  );
}
