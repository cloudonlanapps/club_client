import 'package:club_sdk_2/club_sdk_2.dart' show EvaluationTemplate;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionItem;

import '../constants/evaluation_view_sizes.dart';
import '../constants/evaluation_view_strings.dart';
import 'template_row.dart';

/// The live templates, by name, each with **Start**.
class TemplateStartList extends StatelessWidget {
  /// Lists [templates].
  const TemplateStartList({
    required this.templates,
    required this.onStart,
    super.key,
  });

  /// The library, deleted templates included.
  final Iterable<EvaluationTemplate> templates;

  /// Starts a review from the template with this id.
  final ValueChanged<int> onStart;

  @override
  Widget build(BuildContext context) {
    final live = templates.where((t) => t.deletedAtUtc == null).toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    if (live.isEmpty) {
      return Text(
        EvaluationViewStrings.noTemplates,
        style: ShadTheme.of(context).textTheme.muted,
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      spacing: EvaluationViewSizes.rowGap,
      children: [
        for (final t in live)
          TemplateRow(
            template: t,
            actions: [
              ActionItem(
                label: EvaluationViewStrings.start,
                onPressed: () => onStart(t.id),
              ),
            ],
          ),
      ],
    );
  }
}
