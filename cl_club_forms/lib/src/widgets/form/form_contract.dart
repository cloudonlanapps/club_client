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
/// which the host turns off while it saves. A control that is turned off
/// stops answering the pointer but would keep the keyboard focus it had, and
/// a text input would go on taking keys; the mixin takes that focus away
/// ([dropFocusOfControlOff]), so a form that is off takes no typing.
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

  /// The ids of the fields now showing a message [showErrors] put there.
  final Set<String> refusedFieldIds = <String>{};

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(dropFocusOfControlOff);
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The controls are rebuilt in this frame, so they are read after it.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => dropFocusOfControlOff(),
    );
  }

  @override
  void dispose() {
    FocusManager.instance.removeListener(dropFocusOfControlOff);
    super.dispose();
  }

  /// Whether [element] is a control that is turned off: a text input, or a
  /// form field of any kind.
  bool isControlOff(Element element) {
    final widget = element.widget;
    if (widget is ShadInput) return !widget.enabled;
    if (element is! StatefulElement) return false;
    final state = element.state;
    return state is ShadFormBuilderFieldState && !state.enabled;
  }

  /// Drops the keyboard focus when it is on, or inside, a control of this
  /// form that is turned off. Runs whenever the focus moves, which covers a
  /// field that asks for the focus as a form opens turned off, and after
  /// the host rebuilds the form, which covers a form turned off while a
  /// field has the focus.
  void dropFocusOfControlOff() {
    if (!mounted) return;
    final focus = FocusManager.instance.primaryFocus;
    final focused = focus?.context;
    if (focus == null || focused == null || !focused.mounted) return;
    var off = false;
    var inThisForm = false;
    focused.visitAncestorElements((element) {
      if (element == context) {
        inThisForm = true;
        return false;
      }
      off = off || isControlOff(element);
      return true;
    });
    if (inThisForm && off) focus.unfocus();
  }

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
  /// inline, and the first invalid field takes the focus
  /// ([focusFirstInvalid]).
  Map<String, dynamic>? validate() {
    final form = formKey.currentState;
    if (form == null) return null;
    clearFieldErrors();
    if (!form.saveAndValidate(focusOnInvalid: focusFirstInvalid)) {
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

  /// Sets the inline form-level message; null clears it.
  void setFormError(String? message) {
    if (formError == message || !mounted) return;
    setState(() => formError = message);
  }
}
