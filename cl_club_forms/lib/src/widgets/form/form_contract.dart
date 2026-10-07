import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// What every form's state offers its host, which drives the form through a
/// `GlobalKey` of that state:
///
/// - [validate] gives the values, or null when the form is invalid;
/// - [isDirty] says whether anything changed;
/// - [showErrors] puts back what the server refused.
///
/// The fourth part of the contract is the widget's own `enabled` parameter,
/// which the host turns off while it saves.
///
/// A form's state mixes this in, builds its `ShadForm` with [formKey], and
/// shows [formError] inline (`FormBody` does). It overrides
/// [crossFieldError] for a rule across fields and [assemble] to shape what
/// [validate] returns.
mixin FormContract<T extends StatefulWidget> on State<T> {
  /// The key of the form's `ShadForm`.
  final GlobalKey<ShadFormState> formKey = GlobalKey<ShadFormState>();

  /// The form-level message to show inline; null when there is none.
  String? formError;

  /// The message for a rule across fields that [values] break, or null.
  String? crossFieldError(Map<String, dynamic> values) => null;

  /// What [validate] returns for valid [values]: the values as they are,
  /// unless the form trims, parses or drops some.
  Map<String, dynamic> assemble(Map<String, dynamic> values) => values;

  /// Validates the form. Returns its values, or null when a field or a rule
  /// across fields is broken; the messages then show on the fields and
  /// inline.
  Map<String, dynamic>? validate() {
    final form = formKey.currentState;
    if (form == null) return null;
    if (!form.saveAndValidate(focusOnInvalid: false)) {
      setFormError(null);
      return null;
    }
    final values = Map<String, dynamic>.of(form.value);
    final problem = crossFieldError(values);
    setFormError(problem);
    return problem == null ? assemble(values) : null;
  }

  /// Whether any field differs from its initial value.
  bool get isDirty {
    final form = formKey.currentState;
    if (form == null) return false;
    return !mapEquals(form.initialValue, form.value);
  }

  /// Shows what the server refused: a message on each field of
  /// [fieldErrors], keyed by field id, and [formError] inline.
  void showErrors({
    Map<String, String> fieldErrors = const {},
    String? formError,
  }) {
    final form = formKey.currentState;
    if (form == null) return;
    for (final entry in fieldErrors.entries) {
      form.setFieldError(entry.key, entry.value);
    }
    setFormError(formError);
  }

  /// Sets the inline form-level message; null clears it.
  void setFormError(String? message) {
    if (formError == message || !mounted) return;
    setState(() => formError = message);
  }
}
