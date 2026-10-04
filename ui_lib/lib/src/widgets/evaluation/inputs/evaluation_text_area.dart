import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// A multi-line text area bound to text the host holds.
///
/// Owns only its controller: every edit is reported (blank text as `null`),
/// and the host's [value] replaces the text only when the two disagree, so
/// typing is never interrupted by its own round trip.
class EvaluationTextArea extends StatefulWidget {
  /// Edits [value].
  const EvaluationTextArea({
    required this.value,
    required this.onChanged,
    this.placeholder,
    this.enabled = true,
    super.key,
  });

  /// The text, or `null`.
  final String? value;

  /// Called with the new text; blank text is `null`.
  final ValueChanged<String?> onChanged;

  /// Shown while empty.
  final String? placeholder;

  /// Whether the text can change.
  final bool enabled;

  @override
  State<EvaluationTextArea> createState() => EvaluationTextAreaState();
}

/// State of [EvaluationTextArea]: the controller.
class EvaluationTextAreaState extends State<EvaluationTextArea> {
  /// The area's controller.
  late final TextEditingController controller = TextEditingController(
    text: widget.value ?? '',
  );

  /// The value [text] stands for: `null` when blank.
  static String? parse(String text) => text.trim().isEmpty ? null : text;

  @override
  void didUpdateWidget(EvaluationTextArea oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (parse(controller.text) != widget.value) {
      controller.text = widget.value ?? '';
    }
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ShadTextarea(
    controller: controller,
    enabled: widget.enabled,
    placeholder: widget.placeholder == null ? null : Text(widget.placeholder!),
    onChanged: (text) => widget.onChanged(parse(text)),
  );
}
