import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Single scrollable column inside `DurationPickerDropdown`'s popover.
///
/// Renders a header label followed by a 200-pixel-tall list of options.
/// The currently-selected option is highlighted with the primary tint.
/// Tapping an option calls [onSelected].
class DurationPickerColumn extends StatelessWidget {
  const DurationPickerColumn({
    required this.label,
    required this.options,
    required this.selected,
    required this.formatter,
    required this.onSelected,
    super.key,
  });

  final String label;
  final List<int> options;
  final int selected;
  final String Function(int) formatter;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: theme.textTheme.muted.copyWith(fontSize: 11),
          ),
        ),
        SizedBox(
          height: 200,
          child: ListView.builder(
            itemCount: options.length,
            itemBuilder: (context, index) {
              final value = options[index];
              final isSelected = value == selected;
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => onSelected(value),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: Container(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 4,
                      vertical: 2,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      color: isSelected
                          ? theme.colorScheme.primary.withValues(alpha: 0.1)
                          : null,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      formatter(value),
                      style: theme.textTheme.small.copyWith(
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                        color: isSelected
                            ? theme.colorScheme.primary
                            : theme.colorScheme.foreground,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
