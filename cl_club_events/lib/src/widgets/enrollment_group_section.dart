import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/enrollment_category.dart';
import '../models/inactive_enrollment_filter.dart';
import 'enrollment_tile.dart';
import 'inactive_enrollment_filter_bar.dart';

/// One enrollment category on an event's enrollment list. The Inactive
/// group starts collapsed, showing its count, and filters by kind once
/// opened (club_core#98): ended trials pile up there over a season.
class EnrollmentGroupSection extends StatefulWidget {
  const EnrollmentGroupSection({
    required this.category,
    required this.enrollments,
    required this.eventId,
    required this.displayNameResolver,
    required this.canManage,
    this.withdrawalReasons = const {},
    this.ineligibleUsernames = const {},
    this.currentUser,
    this.onOpenReview,
    super.key,
  });

  final EnrollmentCategory category;
  final Map<String, EnrollmentStatus> enrollments;
  final int eventId;
  final String Function(String username) displayNameResolver;

  /// Whether the viewer may act on the rows (`canManageEnrollments`,
  /// club_core#136); false lists them read-only.
  final bool canManage;

  /// Withdrawal reasons by username, from the full enrollment records.
  final Map<String, String?> withdrawalReasons;

  /// Members the full enrollment records report as no longer eligible
  /// (club_client#42); their rows are marked.
  final Set<String> ineligibleUsernames;

  /// The viewer, for the rows' **Add Review** (club_core#174).
  final UserPrivate? currentUser;

  /// Opens an evaluation started from a row.
  final ValueChanged<int>? onOpenReview;

  @override
  State<EnrollmentGroupSection> createState() => EnrollmentGroupSectionState();
}

class EnrollmentGroupSectionState extends State<EnrollmentGroupSection> {
  late bool expanded = widget.category != EnrollmentCategory.inactive;
  InactiveEnrollmentFilter filter = InactiveEnrollmentFilter.all;

  bool get collapsible => widget.category == EnrollmentCategory.inactive;

  Color headerColor() {
    return switch (widget.category) {
      EnrollmentCategory.active => Colors.green,
      EnrollmentCategory.pending => Colors.orange,
      EnrollmentCategory.inactive => Colors.grey,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final color = headerColor();

    if (widget.enrollments.isEmpty) return const SizedBox.shrink();

    final shown = widget.enrollments.entries.where(
      (e) => filter.matches(e.value, widget.withdrawalReasons[e.key]),
    );

    return ShadCard(
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: collapsible
                ? () => setState(() => expanded = !expanded)
                : null,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.06),
                border: Border(
                  bottom: BorderSide(color: theme.colorScheme.border),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.category.label,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 1,
                    ),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${widget.enrollments.length}',
                      style: TextStyle(
                        fontSize: 11,
                        color: color,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  if (collapsible) ...[
                    const Spacer(),
                    Icon(
                      expanded
                          ? LucideIcons.chevronUp
                          : LucideIcons.chevronDown,
                      size: 16,
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (expanded) ...[
            if (collapsible)
              InactiveEnrollmentFilterBar(
                selected: filter,
                onSelected: (f) => setState(() => filter = f),
              ),
            ...shown.map(
              (entry) => EnrollmentTile(
                username: entry.key,
                status: entry.value,
                eventId: widget.eventId,
                displayName: widget.displayNameResolver(entry.key),
                canManage: widget.canManage,
                withdrawalReason: widget.withdrawalReasons[entry.key],
                eligible: !widget.ineligibleUsernames.contains(entry.key),
                currentUser: widget.currentUser,
                onOpenReview: widget.onOpenReview,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
