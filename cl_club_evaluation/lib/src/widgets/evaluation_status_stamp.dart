import 'package:club_sdk_2/club_sdk_2.dart' show EvaluationStatus;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show StampBadge;

import '../constants/evaluation_view_strings.dart';

/// The stamp an evaluation's [status] earns — the website's [StampBadge],
/// in the theme's monochrome colours (no colour coding): **Ready** once
/// finalized, **Published** once published; a draft gets none — its
/// actions say what it is.
class EvaluationStatusStamp extends StatelessWidget {
  /// The stamp of [status].
  const EvaluationStatusStamp({required this.status, super.key});

  /// The evaluation's status.
  final EvaluationStatus status;

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      EvaluationStatus.draft => null,
      EvaluationStatus.saved => EvaluationViewStrings.stampReady,
      EvaluationStatus.published => EvaluationViewStrings.stampPublished,
    };
    if (label == null) return const SizedBox.shrink();
    final colors = ShadTheme.of(context).colorScheme;
    return StampBadge(
      text: label,
      background: colors.muted,
      foreground: colors.foreground,
    );
  }
}
