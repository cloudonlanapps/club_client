import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'evaluation_form_contract.dart';

/// Keeps the keyboard focus off the controls of an evaluation form that are
/// turned off.
///
/// A control that is turned off stops answering the pointer but would keep
/// the keyboard focus it had, and a text input would go on taking keys. The
/// state of each evaluation form mixes this in, so a form turned off while
/// its host saves takes no typing. Once the form is on again the mixin puts
/// the focus where the member has to act ([giveFocusBack]): on the first
/// field the server refused, or on the field that had the cursor before the
/// save. (`cl_club_forms` does the same for its forms; the two packages
/// share no code.)
mixin EvaluationFormFocus<T extends StatefulWidget>
    on EvaluationFormContract<T> {
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
  void showErrors({
    Map<String, String> fieldErrors = const {},
    String? formError,
  }) {
    super.showErrors(fieldErrors: fieldErrors, formError: formError);
    final form = formKey.currentState;
    if (form == null) return;
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
  /// form that is turned off. Runs whenever the focus moves, and after the
  /// host rebuilds the form, which covers a form turned off while a field
  /// has the focus.
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
}
