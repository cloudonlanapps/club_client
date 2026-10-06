import 'package:flutter/material.dart' show SelectionArea;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// A displayed value the reader can select and copy.
class SelectableValue extends StatelessWidget {
  /// [value] as selectable text.
  const SelectableValue({required this.value, super.key});

  /// The text shown.
  final String value;

  @override
  Widget build(BuildContext context) {
    return SelectionArea(
      child: Text(value, style: ShadTheme.of(context).textTheme.p),
    );
  }
}
