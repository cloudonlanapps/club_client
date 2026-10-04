import 'package:flutter/material.dart';

import '../models/inactive_enrollment_filter.dart';
import 'inactive_filter_button.dart';

/// Small outline filters inside the Inactive enrollment group
/// (club_core#98): all, trial ended (flag), removed, withdrawn.
class InactiveEnrollmentFilterBar extends StatelessWidget {
  const InactiveEnrollmentFilterBar({
    required this.selected,
    required this.onSelected,
    super.key,
  });

  final InactiveEnrollmentFilter selected;
  final ValueChanged<InactiveEnrollmentFilter> onSelected;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: [
          for (final filter in InactiveEnrollmentFilter.values)
            InactiveFilterButton(
              filter: filter,
              selected: filter == selected,
              onPressed: () => onSelected(filter),
            ),
        ],
      ),
    );
  }
}
