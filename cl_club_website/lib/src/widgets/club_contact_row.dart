import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// One line of `ClubContactCard`: an icon, a title and the value.
///
/// If [onTap] is provided, the row becomes tappable with a pointer cursor
/// and the content text is rendered in the primary accent color so the
/// row visually reads as a link.
class ClubContactRow extends StatelessWidget {
  const ClubContactRow({
    required this.icon,
    required this.title,
    required this.content,
    super.key,
    this.onTap,
  });
  final IconData icon;
  final String title;
  final String content;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final isActionable = onTap != null;

    final contentStyle = isActionable
        ? theme.textTheme.muted.copyWith(
            color: theme.colorScheme.primary,
            decoration: TextDecoration.underline,
            decorationColor: theme.colorScheme.primary.withValues(alpha: 0.4),
          )
        : theme.textTheme.muted;

    final row = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: theme.colorScheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.small.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 4),
              Text(content, style: contentStyle),
            ],
          ),
        ),
      ],
    );

    if (!isActionable) return row;

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: row,
      ),
    );
  }
}
