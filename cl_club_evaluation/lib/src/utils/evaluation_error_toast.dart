import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/evaluation_view_strings.dart';
import 'evaluation_error_message.dart';

/// Shows a failed write as a destructive toast over [context] — its fixed
/// message ([EvaluationErrorMessage]), never the raw exception — under
/// [title] when given. Nothing is shown without a context (the view has
/// closed) or a toaster.
void showEvaluationErrorToast(
  BuildContext? context,
  Object error, {
  String fallback = EvaluationViewStrings.saveFailed,
  String? title,
}) {
  if (context == null) return;
  ShadToaster.maybeOf(context)?.show(
    ShadToast.destructive(
      title: title == null ? null : Text(title),
      description: Text(EvaluationErrorMessage.of(error, fallback: fallback)),
    ),
  );
}
