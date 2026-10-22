import 'package:cl_remote_store/cl_remote_store.dart'
    show clEvaluationTemplatesMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show EvaluationTemplate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ConfirmDialog;

import '../constants/evaluation_view_strings.dart';
import '../constants/template_restore_strings.dart';
import 'evaluation_error_message.dart';

/// Deleting a template from the library or its detail, with the prompt and
/// the toasts, and restoring a deleted one. Errors never show the raw
/// exception.
abstract final class EvaluationTemplateActions {
  /// Asks, then soft-deletes [template]; `true` once deleted. A template in
  /// use cannot be deleted (the server refuses with `TEMPLATE_IN_USE`).
  static Future<bool> delete(
    BuildContext context,
    WidgetRef ref,
    EvaluationTemplate template,
  ) async {
    final ok = await ConfirmDialog.show(
      context,
      title: EvaluationViewStrings.deleteTemplateTitle,
      message: EvaluationViewStrings.deleteTemplateMessage,
      confirmLabel: EvaluationViewStrings.delete,
      destructive: true,
    );
    if (!ok || !context.mounted) return false;
    return write(
      context,
      () => ref
          .read(clEvaluationTemplatesMasterProvider.notifier)
          .deleteTemplate(template.id),
      done: EvaluationViewStrings.templateDeleted,
    );
  }

  /// Restores soft-deleted [template] (any staff member, evaluation R46)
  /// and resolves to it, live again; `null` when refused. When a live
  /// template holds its name the server restores it renamed
  /// (`<name> -- Restored #N`), and the toast names the new name.
  static Future<EvaluationTemplate?> restore(
    BuildContext context,
    WidgetRef ref,
    EvaluationTemplate template,
  ) => run(
    context,
    () => ref
        .read(clEvaluationTemplatesMasterProvider.notifier)
        .restoreTemplate(template.id),
    done: (restored) => restored.name == template.name
        ? TemplateRestoreStrings.templateRestored
        : TemplateRestoreStrings.restoredAs(restored.name),
  );

  /// Runs [call], toasting [done] or the refusal; `true` once done.
  static Future<bool> write(
    BuildContext context,
    Future<Object?> Function() call, {
    required String done,
  }) async =>
      await run(context, () async {
        await call();
        return true;
      }, done: (_) => done) ??
      false;

  /// Runs [call], toasting [done] of its result or the refusal; the result,
  /// or `null` when refused.
  static Future<T?> run<T>(
    BuildContext context,
    Future<T> Function() call, {
    required String Function(T result) done,
  }) async {
    final toaster = ShadToaster.of(context);
    try {
      final result = await call();
      toaster.show(ShadToast(description: Text(done(result))));
      return result;
    } on Object catch (e) {
      toaster.show(
        ShadToast.destructive(description: Text(EvaluationErrorMessage.of(e))),
      );
      return null;
    }
  }
}
