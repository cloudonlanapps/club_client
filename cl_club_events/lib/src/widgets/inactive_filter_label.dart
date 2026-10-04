import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/inactive_enrollment_filter.dart';

/// The label of one Inactive filter: an icon for a trial that ended, words
/// for the others.
class InactiveFilterLabel extends StatelessWidget {
  const InactiveFilterLabel({required this.filter, super.key});

  final InactiveEnrollmentFilter filter;

  @override
  Widget build(BuildContext context) {
    return switch (filter) {
      InactiveEnrollmentFilter.all => const Text('All'),
      InactiveEnrollmentFilter.trialEnded => Semantics(
        label: 'Trial ended',
        child: const Icon(LucideIcons.flag, size: 14),
      ),
      InactiveEnrollmentFilter.removed => const Text('Removed'),
      InactiveEnrollmentFilter.withdrawn => const Text('Withdrawn'),
    };
  }
}
