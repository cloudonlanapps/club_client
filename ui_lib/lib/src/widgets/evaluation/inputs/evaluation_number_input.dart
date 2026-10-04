import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../constants/evaluation_spacing.dart';
import '../../../constants/evaluation_strings.dart';

/// A number answer, with a numeric keyboard and "Enter a number" while
/// empty. Text that is not a number reports `null` and shows "Enter a
/// number.". Stateful only to own its controller.
class EvaluationNumberInput extends StatefulWidget {
  /// Edits [value].
  const EvaluationNumberInput({
    required this.value,
    required this.onChanged,
    this.enabled = true,
    super.key,
  });

  /// The number, or `null`.
  final num? value;

  /// Called with the new number; empty or invalid text is `null`.
  final ValueChanged<num?> onChanged;

  /// Whether the number can change.
  final bool enabled;

  @override
  State<EvaluationNumberInput> createState() => EvaluationNumberInputState();
}

/// State of [EvaluationNumberInput]: the controller and whether the text
/// parses.
class EvaluationNumberInputState extends State<EvaluationNumberInput> {
  /// The input's controller.
  late final TextEditingController controller = TextEditingController(
    text: format(widget.value),
  );

  /// Whether the current text is not a number.
  bool invalid = false;

  /// [value] as text; empty for `null`.
  static String format(num? value) => value == null ? '' : '$value';

  @override
  void didUpdateWidget(EvaluationNumberInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!invalid && num.tryParse(controller.text.trim()) != widget.value) {
      controller.text = format(widget.value);
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  /// Reports [text] to the host.
  void changed(String text) {
    final t = text.trim();
    final parsed = num.tryParse(t);
    setState(() => invalid = t.isNotEmpty && parsed == null);
    widget.onChanged(parsed);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      spacing: EvaluationSpacing.smallGap,
      children: [
        ShadInput(
          controller: controller,
          enabled: widget.enabled,
          placeholder: const Text(EvaluationStrings.numberPlaceholder),
          keyboardType: const TextInputType.numberWithOptions(
            decimal: true,
            signed: true,
          ),
          onChanged: changed,
        ),
        if (invalid)
          Text(
            EvaluationStrings.notANumber,
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.destructive,
            ),
          ),
      ],
    );
  }
}
