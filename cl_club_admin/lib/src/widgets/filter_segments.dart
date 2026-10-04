import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// One choice of a [FilterSegments] row.
typedef FilterSegment<T> = ({T value, String label, Key key});

/// A row of mutually exclusive filter buttons: the selected one filled in
/// the secondary tone, the rest outlined. Monochrome, no chips.
class FilterSegments<T> extends StatelessWidget {
  const FilterSegments({
    required this.segments,
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final List<FilterSegment<T>> segments;
  final T selected;
  final ValueChanged<T> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final s in segments)
          if (s.value == selected)
            ShadButton.secondary(
              key: s.key,
              size: ShadButtonSize.sm,
              onPressed: () {},
              child: Text(s.label),
            )
          else
            ShadButton.outline(
              key: s.key,
              size: ShadButtonSize.sm,
              onPressed: () => onSelected(s.value),
              child: Text(s.label),
            ),
      ],
    );
  }
}
