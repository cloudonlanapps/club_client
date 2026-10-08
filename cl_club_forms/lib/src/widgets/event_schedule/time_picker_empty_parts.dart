import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Tells a [ShadTimePickerController] when the hour or the minute box of its
/// picker is emptied.
///
/// `ShadTimePicker` hands what is typed in a box to its controller only
/// while the box holds text, so a controller keeps the earlier hour after
/// the hour is deleted, and its listeners hear nothing. Wrapped around the
/// picker (one that shows hours and minutes, no seconds), this clears the
/// controller's hour or minute when its box is emptied: the controller then
/// has no value, and says so to its listeners.
class TimePickerEmptyParts extends StatefulWidget {
  const TimePickerEmptyParts({
    required this.controller,
    required this.child,
    super.key,
  });

  /// The controller of the picker in [child].
  final ShadTimePickerController controller;

  /// The time picker, or the form field that builds it.
  final Widget child;

  @override
  State<TimePickerEmptyParts> createState() => TimePickerEmptyPartsState();
}

class TimePickerEmptyPartsState extends State<TimePickerEmptyParts> {
  /// The text of the picker's boxes, in the order shown: hour, minute.
  List<TextEditingController> parts = const [];

  @override
  void initState() {
    super.initState();
    // The boxes exist once the picker below has been built.
    WidgetsBinding.instance.addPostFrameCallback((_) => watchParts());
  }

  @override
  void dispose() {
    for (final part in parts) {
      part.removeListener(onPartChanged);
    }
    super.dispose();
  }

  /// Finds the picker's boxes below this widget and listens to their text.
  void watchParts() {
    if (!mounted) return;
    final found = <TextEditingController>[];
    void visit(Element element) {
      final widget = element.widget;
      if (widget is ShadTimePickerField && widget.controller != null) {
        found.add(widget.controller!);
        return;
      }
      element.visitChildren(visit);
    }

    context.visitChildElements(visit);
    parts = found;
    for (final part in parts) {
      part.addListener(onPartChanged);
    }
  }

  void onPartChanged() {
    if (parts.isNotEmpty && parts.first.text.isEmpty) {
      widget.controller.setHour(null);
    }
    if (parts.length > 1 && parts[1].text.isEmpty) {
      widget.controller.setMinute(null);
    }
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
