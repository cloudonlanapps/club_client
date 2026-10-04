import 'dart:async';

import 'package:club_sdk_2/club_sdk_2.dart' show EvaluationTemplate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_lib/ui_lib.dart' show ActionItem;

import '../constants/evaluation_view_strings.dart';
import '../utils/evaluation_template_actions.dart';
import 'template_row.dart';

/// One live template of the library: it opens on tap and offers
/// **Duplicate** and **Delete** (disabled while an evaluation uses it).
class TemplateLibraryRow extends ConsumerWidget {
  /// A row for [template].
  const TemplateLibraryRow({
    required this.template,
    required this.onOpen,
    required this.onDuplicate,
    super.key,
  });

  /// The template.
  final EvaluationTemplate template;

  /// Opens it.
  final VoidCallback onOpen;

  /// Opens the designer with a copy of it.
  final VoidCallback onDuplicate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = template;
    return TemplateRow(
      template: t,
      onTap: onOpen,
      actions: [
        ActionItem(
          label: EvaluationViewStrings.duplicate,
          onPressed: onDuplicate,
        ),
        ActionItem(
          label: EvaluationViewStrings.delete,
          destructive: true,
          onPressed: t.inUse
              ? null
              : () => unawaited(
                  EvaluationTemplateActions.delete(context, ref, t),
                ),
        ),
      ],
    );
  }
}
