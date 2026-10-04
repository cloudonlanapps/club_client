import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// One select of the start form, searchable, over [options] of value and
/// label. With [requiredMessage], an empty choice is invalid.
class EvaluationStartSelect<T> extends StatelessWidget {
  /// A select keyed [id].
  const EvaluationStartSelect({
    required this.id,
    required this.label,
    required this.options,
    this.placeholder,
    this.requiredMessage,
    this.initialValue,
    this.enabled = true,
    this.onChanged,
    super.key,
  });

  /// The field id.
  final String id;

  /// The label above the field.
  final String label;

  /// The values offered, each with its label.
  final List<(T, String)> options;

  /// Shown before a choice.
  final String? placeholder;

  /// The message when nothing is chosen; `null` allows no choice.
  final String? requiredMessage;

  /// The value chosen at first.
  final T? initialValue;

  /// Whether the choice can change.
  final bool enabled;

  /// Called with each new choice.
  final ValueChanged<T?>? onChanged;

  @override
  Widget build(BuildContext context) {
    final hint = placeholder;
    final message = requiredMessage;
    final labels = {for (final (v, l) in options) v: l};
    return ShadSelectFormField<T>(
      id: id,
      label: Text(label),
      initialValue: initialValue,
      enabled: enabled,
      onChanged: onChanged,
      placeholder: hint == null ? null : Text(hint),
      minWidth: double.infinity,
      options: [
        for (final (v, l) in options) ShadOption<T>(value: v, child: Text(l)),
      ],
      selectedOptionBuilder: (context, value) => Text(labels[value] ?? ''),
      validator: message == null ? null : (v) => v == null ? message : null,
    );
  }
}
