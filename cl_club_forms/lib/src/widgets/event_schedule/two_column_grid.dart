import 'package:flutter/material.dart';

import '../../constants/form_breakpoints.dart';

/// A layout widget that arranges children in a two-column grid on wide
/// surfaces and stacks them in a single column on narrow ones.
///
/// Falls back to a single column when the available width is below
/// [singleColumnBreakpoint] (defaults to
/// [FormBreakpoints.singleColumnMaxWidth]). Each child takes the full
/// width in single-column mode; in two-column mode, children are paired
/// row-by-row with a flexible spacing in between.
class TwoColumnGrid extends StatelessWidget {
  const TwoColumnGrid({
    required this.children,
    super.key,
    this.spacing = 12,
    this.runSpacing = 12,
    this.crossAxisAlignment = CrossAxisAlignment.start,
    this.singleColumnBreakpoint = FormBreakpoints.singleColumnMaxWidth,
  });
  final List<Widget> children;
  final double spacing;
  final double runSpacing;
  final CrossAxisAlignment crossAxisAlignment;

  /// Width below which the grid collapses to a single column. The runtime
  /// width is taken from the parent's `BoxConstraints` via `LayoutBuilder`.
  final double singleColumnBreakpoint;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    if (children.length == 1) return children.first;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < singleColumnBreakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var i = 0; i < children.length; i++) ...[
                if (i > 0) SizedBox(height: runSpacing),
                children[i],
              ],
            ],
          );
        }

        final rows = <Widget>[];
        for (var i = 0; i < children.length; i += 2) {
          final leftChild = children[i];
          final rightChild = i + 1 < children.length ? children[i + 1] : null;

          if (rows.isNotEmpty) rows.add(SizedBox(height: runSpacing));
          rows.add(
            Row(
              crossAxisAlignment: crossAxisAlignment,
              children: [
                Expanded(child: leftChild),
                SizedBox(width: spacing),
                Expanded(child: rightChild ?? const SizedBox.shrink()),
              ],
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: rows,
        );
      },
    );
  }
}
