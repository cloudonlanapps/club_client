import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Holds a date field that is one input of a composite field, apart from
/// the form around it.
///
/// A `ShadFormBuilderField` without an id still registers with the nearest
/// `ShadForm`, under an id it generates, so the outer form's value would
/// carry the day a second time under that id, and `isDirty` would compare
/// it. Here the field registers with a form of its own instead, and the
/// composite field keeps the day in its own value.
///
/// The field holds its value in its own state, so a day set from outside
/// (cleared by an x, replaced by the composite field) shows only on a new
/// field: [value] keys it, and a new value builds a new one.
class DetachedDateField extends StatelessWidget {
  const DetachedDateField({
    required this.value,
    required this.child,
    super.key,
  });

  /// The day the field shows, as the composite field holds it.
  final Object? value;

  /// The date field.
  final Widget child;

  @override
  Widget build(BuildContext context) =>
      ShadForm(key: ValueKey(value), child: child);
}
