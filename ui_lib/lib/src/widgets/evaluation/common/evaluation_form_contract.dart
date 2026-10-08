import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../utils/evaluation_form_equality.dart';

/// What the state of every evaluation form offers its host, which drives
/// the form through a `GlobalKey` of that state:
///
/// - [validate] gives the values, or null when the form is invalid;
/// - [isDirty] says whether anything changed;
/// - [showErrors] puts back what the server refused.
///
/// The fourth part of the contract is the widget's own `enabled` parameter,
/// which the host turns off while it saves.
///
/// A form's state mixes this in, builds its `ShadForm` with [formKey] and
/// shows [formError] inline. It overrides [crossFieldError] for a rule
/// across fields and [assemble] to shape what [validate] returns.
/// (`cl_club_forms` has the same contract for its forms, with the same
/// signatures; the two packages share no code.)
mixin EvaluationFormContract<T extends StatefulWidget> on State<T> {
  /// The key of the form's `ShadForm`.
  final GlobalKey<ShadFormState> formKey = GlobalKey<ShadFormState>();

  /// The form-level message to show inline; null when there is none.
  String? formError;

  /// The ids of the fields now showing a message [showErrors] put there.
  final Set<String> refusedFieldIds = <String>{};

  /// Whether [validate] puts the focus on the first invalid field. A form
  /// made of pickers and custom fields, which have nothing to focus, turns
  /// it off.
  bool get focusFirstInvalid => true;

  /// The message for a rule across fields that [values] break, or null.
  String? crossFieldError(Map<String, dynamic> values) => null;

  /// What [validate] returns for valid [values]: the values as they are,
  /// unless the form trims, parses or drops some.
  Map<String, dynamic> assemble(Map<String, dynamic> values) => values;

  /// Validates the form. Returns its values, or null when a field or a rule
  /// across fields is broken; the messages then show on the fields and
  /// inline. A rule across fields is checked whether or not the fields are
  /// valid, so both kinds of message show at once.
  Map<String, dynamic>? validate() {
    final form = formKey.currentState;
    if (form == null) return null;
    clearFieldErrors();
    final fieldsValid = form.saveAndValidate(focusOnInvalid: focusFirstInvalid);
    final values = Map<String, dynamic>.of(form.value);
    final problem = crossFieldError(values);
    setFormError(problem);
    return fieldsValid && problem == null ? assemble(values) : null;
  }

  /// Whether any field differs from its initial value; lists compare
  /// element by element.
  bool get isDirty {
    final form = formKey.currentState;
    if (form == null) return false;
    return !EvaluationFormEquality.mapsEqual(form.initialValue, form.value);
  }

  /// Shows what the server refused: a message on each field of
  /// [fieldErrors], keyed by field id, and [formError] inline.
  ///
  /// The messages replace those of an earlier call, and stay on the fields
  /// until the next [validate], which judges the fields by what they hold
  /// then. A message for a field that is not on screen is shown inline
  /// instead, unless [formError] is given.
  void showErrors({
    Map<String, String> fieldErrors = const {},
    String? formError,
  }) {
    final form = formKey.currentState;
    if (form == null) return;
    clearFieldErrors();
    String? unplaced;
    for (final entry in fieldErrors.entries) {
      if (!form.fields.containsKey(entry.key)) {
        unplaced ??= entry.value;
        continue;
      }
      form.setFieldError(entry.key, entry.value);
      refusedFieldIds.add(entry.key);
    }
    setFormError(formError ?? unplaced);
  }

  /// Takes the messages [showErrors] put on the fields off again. A field
  /// showing one counts as invalid whatever it holds, so [validate] clears
  /// them before it checks the fields.
  void clearFieldErrors() {
    final form = formKey.currentState;
    if (form != null) {
      for (final id in refusedFieldIds) {
        if (form.fields.containsKey(id)) form.setFieldError(id, null);
      }
    }
    refusedFieldIds.clear();
  }

  /// What each field held when the form-level message was last set; null
  /// while none shows.
  Map<String, dynamic>? valuesAtFormError;

  /// Whether [clearFormErrorOnEdit] is due after the next frame.
  bool watchingForEdit = false;

  /// What each field holds now, by field id: the fields' own values, which
  /// stay the same objects until a field changes.
  Map<String, dynamic>? get fieldValues {
    final fields = formKey.currentState?.fields;
    if (fields == null) return null;
    return {for (final entry in fields.entries) entry.key: entry.value.value};
  }

  /// Sets the inline form-level message; null clears it. A message goes on
  /// the next edit of the form ([clearFormErrorOnEdit]), so no form clears
  /// it from its own `onChanged`.
  void setFormError(String? message) {
    valuesAtFormError = message == null ? null : fieldValues;
    if (valuesAtFormError != null && !watchingForEdit) {
      watchingForEdit = true;
      WidgetsBinding.instance.addPostFrameCallback(
        (_) => clearFormErrorOnEdit(),
      );
    }
    if (formError == message || !mounted) return;
    setState(() => formError = message);
  }

  /// Clears the form-level message once a field holds something else than
  /// when the message was set. An edit always draws a frame, so this runs
  /// after each frame while a message shows, and not at all otherwise.
  void clearFormErrorOnEdit() {
    final shown = valuesAtFormError;
    final now = fieldValues;
    watchingForEdit = false;
    if (!mounted || shown == null || now == null) {
      valuesAtFormError = null;
      return;
    }
    if (!EvaluationFormEquality.mapsEqual(shown, now)) {
      setFormError(null);
      return;
    }
    watchingForEdit = true;
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => clearFormErrorOnEdit(),
    );
  }
}
