import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/form_spacing.dart';
import 'user_form_assembly.dart';

/// A list of the extended profile that a member picks from the club's
/// options (preferred positions, preferred languages; club_client#335): one
/// checkbox per option, any number ticked, and [noneTickedHint] beneath the
/// boxes while none is.
///
/// Its value is the ticked values, in the order the boxes show. A value the
/// field starts with that is not among [options] (an option the club
/// removed later) gets a box of its own after them, labelled by the value
/// and ticked, so it is saved back unchanged unless the member unticks it.
///
/// Sits inside the embedding form's `ShadForm`, which holds the initial
/// value as a list of strings (`UserFormAssembly.seed`).
class UserChoicesField extends ShadFormBuilderField<List<String>> {
  UserChoicesField({
    required String id,
    required this.options,
    required this.noneTickedHint,
    super.enabled,
    super.key,
  }) : super(
         id: id,
         // The form hands its value back deep-copied, a `List<dynamic>`.
         fromValueTransformer: (value) =>
             UserFormAssembly.strings(id, {id: value}),
         builder: (field) {
           final state = field as UserChoicesFieldState;
           return UserChoicesChecks(
             shown: state.shown,
             ticked: state.ticked,
             enabled: state.enabled,
             focusNode: state.focusNode,
             noneTickedHint: noneTickedHint,
             onChanged: state.toggle,
           );
         },
       );

  /// The choices, value to the text shown, in order.
  final Map<String, String> options;

  /// The line shown while no box is ticked.
  final String noneTickedHint;

  @override
  UserChoicesFieldState createState() => UserChoicesFieldState();
}

/// State of [UserChoicesField].
class UserChoicesFieldState
    extends ShadFormBuilderFieldState<UserChoicesField, List<String>> {
  /// Every box, value to the text shown, in order: the field's options,
  /// then each value the field started with that is not among them.
  Map<String, String> get shown => {
    ...widget.options,
    for (final held in initialValue ?? const <String>[])
      if (!widget.options.containsKey(held)) held: held,
  };

  /// The values ticked now, in the order the boxes show.
  List<String> get ticked => ordered(value ?? const []);

  /// [values] once each, in the order the boxes show.
  List<String> ordered(Iterable<String> values) {
    final set = values.toSet();
    return List.unmodifiable(shown.keys.where(set.contains));
  }

  /// Ticks [choice] when [on], unticks it otherwise.
  void toggle(String choice, {required bool on}) {
    final next = {...ticked};
    if (on) {
      next.add(choice);
    } else {
      next.remove(choice);
    }
    didChange(ordered(next));
  }
}

/// The boxes of [UserChoicesField], with [noneTickedHint] beneath them while
/// none is ticked.
class UserChoicesChecks extends StatelessWidget {
  const UserChoicesChecks({
    required this.shown,
    required this.ticked,
    required this.enabled,
    required this.noneTickedHint,
    required this.onChanged,
    this.focusNode,
    super.key,
  });

  /// Every box, value to the text shown, in order.
  final Map<String, String> shown;

  /// The values ticked.
  final List<String> ticked;

  /// Whether the boxes respond.
  final bool enabled;

  /// The line shown while no box is ticked.
  final String noneTickedHint;

  /// Called with a value and whether its box is now ticked.
  final void Function(String choice, {required bool on}) onChanged;

  /// The field's focus node, given to the first box.
  final FocusNode? focusNode;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      spacing: FormSpacing.labelGap,
      children: [
        if (shown.isNotEmpty)
          Wrap(
            spacing: FormSpacing.rowGap,
            runSpacing: FormSpacing.labelGap,
            children: [
              for (final (index, entry) in shown.entries.indexed)
                ShadCheckbox(
                  key: ValueKey(entry.key),
                  value: ticked.contains(entry.key),
                  enabled: enabled,
                  focusNode: index == 0 ? focusNode : null,
                  label: Text(entry.value),
                  onChanged: (on) => onChanged(entry.key, on: on),
                ),
            ],
          ),
        if (ticked.isEmpty) Text(noneTickedHint, style: theme.textTheme.muted),
      ],
    );
  }
}
