import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/inactive_enrollment_filter.dart';
import 'inactive_filter_label.dart';

/// One Inactive filter: filled when selected, outlined otherwise.
class InactiveFilterButton extends StatelessWidget {
  const InactiveFilterButton({
    required this.filter,
    required this.selected,
    required this.onPressed,
    super.key,
  });

  final InactiveEnrollmentFilter filter;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final label = InactiveFilterLabel(filter: filter);
    if (selected) {
      return ShadButton.secondary(
        size: ShadButtonSize.sm,
        onPressed: onPressed,
        child: label,
      );
    }
    return ShadButton.outline(
      size: ShadButtonSize.sm,
      onPressed: onPressed,
      child: label,
    );
  }
}
