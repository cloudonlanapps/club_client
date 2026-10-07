import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import '../status_badge.dart';

/// The one mark for a member the server reports as no longer meeting an
/// event's or a group's criteria: [NoLongerEligibleLabel.text] in a
/// thin outline, with no colour of its own.
///
/// Every list that marks such a member mounts this, so the mark looks the
/// same in a group's member list, an event's enrolment list and the
/// member's own profile (club_client#43).
class NoLongerEligibleLabel extends StatelessWidget {
  const NoLongerEligibleLabel({super.key});

  /// What the mark says.
  static const String text = 'No longer eligible';

  @override
  Widget build(BuildContext context) {
    return const StatusBadge(
      label: text,
      icon: LucideIcons.userX,
    );
  }
}
