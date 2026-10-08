import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Whether [element] is a control that is turned off: a text input, or a
/// form field of any kind.
bool isEvaluationControlOff(Element element) {
  final widget = element.widget;
  if (widget is ShadInput) return !widget.enabled;
  if (element is! StatefulElement) return false;
  final state = element.state;
  return state is ShadFormBuilderFieldState && !state.enabled;
}

/// Scrolls just far enough for what [target] builds to be on screen.
void scrollEvaluationTargetIntoView(BuildContext target) {
  for (final policy in const [
    ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
    ScrollPositionAlignmentPolicy.keepVisibleAtStart,
  ]) {
    Scrollable.ensureVisible(target, alignmentPolicy: policy);
  }
}
