import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Horizontal scrollable filter bar for user status.
///
/// Uses `null` for "All" and [UserStatus] values for specific filters.
class UserStatusFilterBar extends StatelessWidget {
  const UserStatusFilterBar({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final UserStatus? selected;
  final ValueChanged<UserStatus?> onSelected;

  @override
  Widget build(BuildContext context) {
    final options = <UserStatus?>[null, ...UserStatus.values];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: options.map((status) {
          final isSelected = status == selected;
          final label = status == null
              ? 'All'
              : status.name[0].toUpperCase() + status.name.substring(1);

          return Padding(
            padding: const EdgeInsets.only(right: 6),
            child: isSelected
                ? ShadButton.secondary(
                    size: ShadButtonSize.sm,
                    onPressed: () => onSelected(status),
                    child: Text(label, style: const TextStyle(fontSize: 12)),
                  )
                : ShadButton.ghost(
                    size: ShadButtonSize.sm,
                    onPressed: () => onSelected(status),
                    child: Text(label, style: const TextStyle(fontSize: 12)),
                  ),
          );
        }).toList(),
      ),
    );
  }
}
