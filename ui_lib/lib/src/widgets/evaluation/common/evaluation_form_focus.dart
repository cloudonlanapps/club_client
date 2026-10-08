import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Keeps the keyboard focus off the controls of an evaluation form that are
/// turned off.
///
/// A control that is turned off stops answering the pointer but would keep
/// the keyboard focus it had, and a text input would go on taking keys. The
/// state of each evaluation form mixes this in, so a form turned off while
/// its host saves takes no typing. (`cl_club_forms` does the same for its
/// forms; the two packages share no code.)
mixin EvaluationFormFocus<T extends StatefulWidget> on State<T> {
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
    if (inThisForm && off) focus.unfocus();
  }
}
