import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'user_selection_dialog.dart' show PickerUser;

class UserSelectionTile extends StatelessWidget {
  const UserSelectionTile({
    required this.user,
    required this.selected,
    required this.onTap,
    this.blocked = false,
    super.key,
  });

  final PickerUser user;
  final bool selected;

  /// Shown dimmed; [onTap] is null.
  final bool blocked;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: MouseRegion(
        cursor: onTap == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        child: Opacity(
          opacity: blocked ? 0.5 : 1,
          child: Container(
            width: 180,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(
                color: selected
                    ? theme.colorScheme.primary
                    : theme.colorScheme.border,
                width: selected ? 2 : 1,
              ),
              borderRadius: BorderRadius.circular(8),
              color: selected
                  ? theme.colorScheme.primary.withValues(alpha: 0.08)
                  : null,
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: theme.colorScheme.muted,
                  child: Text(
                    user.initials,
                    style: TextStyle(
                      color: theme.colorScheme.mutedForeground,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        user.displayName,
                        style: theme.textTheme.small,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              '@${user.username}',
                              style: theme.textTheme.muted.copyWith(
                                fontSize: 11,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (user.roleLabel != null) ...[
                            Text(
                              ' · ${user.roleLabel}',
                              style: theme.textTheme.muted.copyWith(
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                if (selected)
                  Icon(
                    LucideIcons.check,
                    size: 14,
                    color: theme.colorScheme.primary,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
