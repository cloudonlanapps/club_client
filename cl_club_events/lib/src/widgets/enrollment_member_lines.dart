import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show NoLongerEligibleLabel;

/// Who an enrollment row is about: display name, username, and, for an
/// enrolled member the server reports as no longer meeting the event's
/// criteria (`Enrollment.eligible` false, club_server#19), the shared
/// outlined mark beneath. Nobody is removed automatically; the admin decides
/// (club_client#42).
class EnrollmentMemberLines extends StatelessWidget {
  const EnrollmentMemberLines({
    required this.displayName,
    required this.username,
    this.eligible = true,
    super.key,
  });

  final String displayName;
  final String username;

  /// False shows the mark.
  final bool eligible;

  /// Font size of the display name.
  static const double nameFontSize = 13;

  /// Font size of the username.
  static const double detailFontSize = 11;

  /// Space between the username and the eligibility mark.
  static const double markTopGap = 2;

  @override
  Widget build(BuildContext context) {
    final detailStyle = ShadTheme.of(context).textTheme.muted.copyWith(
      fontSize: detailFontSize,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          displayName,
          style: const TextStyle(
            fontSize: nameFontSize,
            fontWeight: FontWeight.w500,
          ),
        ),
        Text(username, style: detailStyle),
        if (!eligible)
          const Padding(
            padding: EdgeInsets.only(top: markTopGap),
            child: NoLongerEligibleLabel(),
          ),
      ],
    );
  }
}
