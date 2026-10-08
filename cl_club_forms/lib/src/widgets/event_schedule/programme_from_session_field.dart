import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The session a change to a programme takes effect from: a select over the
/// upcoming session starts of its present schedule ([options]), each
/// written in local time. The server accepts no other effective time.
///
/// A field of the hosting form: it registers its `DateTime` under [id].
class ProgrammeFromSessionField extends StatelessWidget {
  const ProgrammeFromSessionField({
    required this.id,
    required this.options,
    this.initialValue,
    this.enabled = true,
    this.validator,
    this.onChanged,
    super.key,
  });

  /// The label of the field's row.
  static const String label = 'From';

  /// Shown while no session is chosen.
  static const String placeholder = 'Pick a session';

  /// How a session is written in the select.
  static final DateFormat format = DateFormat('EEE d MMM y, HH:mm');

  /// [session] as the select writes it, in local time.
  static String textOf(DateTime session) => format.format(session.toLocal());

  /// The id the chosen session is registered under.
  final String id;

  /// The session starts offered, soonest first.
  final List<DateTime> options;

  /// The session chosen when the form opens.
  final DateTime? initialValue;

  /// Whether the select responds.
  final bool enabled;

  /// Checks the chosen session.
  final String? Function(DateTime? value)? validator;

  /// Called when another session is chosen.
  final ValueChanged<DateTime?>? onChanged;

  @override
  Widget build(BuildContext context) {
    return ShadSelectFormField<DateTime>(
      id: id,
      initialValue: initialValue,
      enabled: enabled,
      placeholder: const Text(placeholder),
      validator: validator,
      options: [
        for (final option in options)
          ShadOption(value: option, child: Text(textOf(option))),
      ],
      selectedOptionBuilder: (context, value) => Text(textOf(value)),
      onChanged: onChanged,
    );
  }
}
