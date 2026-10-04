import 'package:club_sdk_2/club_sdk_2.dart' show CreditEntryType;
import 'package:flutter/widgets.dart' show IconData;
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

/// The icon a statement line shows for its [type] (club_core#101): icons
/// and numbers, no prose.
IconData creditEntryIcon(CreditEntryType type) => switch (type) {
  CreditEntryType.sessionDeduction => LucideIcons.calendarCheck,
  CreditEntryType.sessionRefund => LucideIcons.treePalm,
  CreditEntryType.grant => LucideIcons.plus,
  CreditEntryType.grantReversal => LucideIcons.undo2,
  CreditEntryType.penalty => LucideIcons.triangleAlert,
  CreditEntryType.transferOut ||
  CreditEntryType.transferIn => LucideIcons.arrowLeftRight,
  CreditEntryType.validityExtended => LucideIcons.calendarPlus,
  CreditEntryType.unknown => LucideIcons.circleQuestionMark,
};

/// Whether a line of [type] carries a reason an admin wrote, shown on tap.
/// Session lines carry the server's own text, which is not shown.
bool creditEntryHasAdminReason(CreditEntryType type) => switch (type) {
  CreditEntryType.sessionDeduction || CreditEntryType.sessionRefund => false,
  _ => true,
};
