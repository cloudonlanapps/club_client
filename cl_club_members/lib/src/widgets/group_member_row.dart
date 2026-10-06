import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionButton, AgeEligibilityText;

/// One member of a group's member list: display name, username, and, for a
/// semi-auto member the server reports as no longer meeting the group's
/// criteria (`GroupMember.eligible` false), a plain-text mark beneath.
/// Nobody is removed automatically; the admin decides.
class GroupMemberRow extends StatelessWidget {
  const GroupMemberRow({
    required this.member,
    this.onTap,
    this.onRemove,
    super.key,
  });

  final GroupMember member;
  final VoidCallback? onTap;

  /// Shows the Remove action when set (admin of a manual or semi-auto group).
  final VoidCallback? onRemove;

  static const String removeLabel = 'Remove';

  /// Font size of the username and the eligibility mark.
  static const double detailFontSize = 12;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final detailStyle = theme.textTheme.muted.copyWith(
      fontSize: detailFontSize,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  spacing: 2,
                  children: [
                    Text(member.displayName, style: theme.textTheme.p),
                    Text('@${member.membername}', style: detailStyle),
                    if (!member.eligible)
                      Text(
                        AgeEligibilityText.noLongerEligible,
                        style: detailStyle,
                      ),
                  ],
                ),
              ),
            ),
          ),
          if (onRemove != null)
            ActionButton(label: removeLabel, onPressed: onRemove),
        ],
      ),
    );
  }
}
