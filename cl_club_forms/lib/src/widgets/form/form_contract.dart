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
/// ([dropFocusOfControlOff]), so a form that is off takes no typing. Once
/// the form is on again the mixin puts the focus where the member has to
/// act ([giveFocusBack]): on the first field the server refused, or on the
/// field that had the cursor before the save.
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

  /// What had the keyboard focus when the form was turned off, to give it
  /// back once the form is on again; null when nothing of the form had it.
  FocusNode? focusTakenAway;

  /// Whether [showErrors] was called and the focus has not been placed yet.
  bool refusalAwaitsFocus = false;

  /// The first field [showErrors] put a message on, in the order the form
  /// shows its fields; null when the refusal named none.
  String? firstRefusedId;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(dropFocusOfControlOff);
  }

  @override
  void didUpdateWidget(covariant T oldWidget) {
    super.didUpdateWidget(oldWidget);
    // The controls are rebuilt in this frame, so they are read after it.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      dropFocusOfControlOff();
      giveFocusBack();
    });
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
    if (inThisForm && off) {
      focusTakenAway = focus;
      focus.unfocus();
    } else if (focus is! FocusScopeNode) {
      // The member put the cursor somewhere themselves.
      focusTakenAway = null;
    }
  }

  /// Whether the form is turned off: it has fields and every one is off.
  bool get isTurnedOff {
    final fields = formKey.currentState?.fields.values ?? const [];
    return fields.isNotEmpty && fields.every((field) => !field.enabled);
  }

  /// Whether [node] is in the tree, may be focused, and sits in a control
  /// of this form that is on.
  bool canTakeFocus(FocusNode node) {
    final at = node.context;
    if (at == null || !at.mounted || !node.canRequestFocus) return false;
    var off = at is Element && isControlOff(at);
    var inThisForm = false;
    at.visitAncestorElements((element) {
      if (element == context) {
        inThisForm = true;
        return false;
      }
      off = off || isControlOff(element);
      return true;
    });
    return inThisForm && !off;
  }

  /// Scrolls just far enough for what [target] builds to be on screen.
  void scrollIntoView(BuildContext target) {
    for (final policy in const [
      ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      ScrollPositionAlignmentPolicy.keepVisibleAtStart,
    ]) {
      Scrollable.ensureVisible(target, alignmentPolicy: policy);
    }
  }

  /// Scrolls the inline form-level message into view, when one shows.
  void scrollFormErrorIntoView() {
    final message = formError;
    if (message == null) return;
    Element? found;
    void visit(Element element) {
      if (found != null) return;
      final widget = element.widget;
      if (widget is Text && widget.data == message) {
        found = element;
        return;
      }
      element.visitChildren(visit);
    }

    context.visitChildElements(visit);
    if (found != null) scrollIntoView(found!);
  }

  /// Puts the focus where the member has to act, once the form is on
  /// again after a save. Runs after the frame of [showErrors] and after
  /// each rebuild by the host, so it works whichever of the two the host
  /// does first; while the form is off it waits.
  ///
  /// After [showErrors] named fields, the first of them in the form's own
  /// order takes the focus; one with nothing to type into is scrolled into
  /// view. Otherwise the field that had the cursor before the save takes
  /// it again, or the first field that can when that one is gone. A
  /// form-level message is scrolled into view as well.
  void giveFocusBack() {
    final form = formKey.currentState;
    final refused = refusalAwaitsFocus;
    final before = focusTakenAway;
    if (!refused && before == null) return;
    if (!mounted || form == null || isTurnedOff) return;
    final field = form.fields[firstRefusedId];
    refusalAwaitsFocus = false;
    firstRefusedId = null;
    focusTakenAway = null;
    // The member has moved on to something outside this form.
    final current = FocusManager.instance.primaryFocus;
    if (current != null && current is! FocusScopeNode) return;

    if (field != null) {
      if (canTakeFocus(field.focusNode)) {
        field.focusNode.requestFocus();
      } else {
        scrollIntoView(field.context);
      }
    } else if (before != null && canTakeFocus(before)) {
      before.requestFocus();
    } else if (before != null) {
      for (final candidate in form.fields.values) {
        if (!canTakeFocus(candidate.focusNode)) continue;
        candidate.focusNode.requestFocus();
        break;
      }
    }
    if (refused) scrollFormErrorIntoView();
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
    firstRefusedId = form.fields.keys
        .where(refusedFieldIds.contains)
        .firstOrNull;
    refusalAwaitsFocus = true;
    // The host turns the form on again before or after this call; either
    // way its fields are still built off now, so the focus is asked for
    // after the frame.
    WidgetsBinding.instance
      ..addPostFrameCallback((_) => giveFocusBack())
      ..ensureVisualUpdate();
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
