import 'package:club_sdk_2/club_sdk_2.dart' show CreditEntry;

/// The loaded part of a member's credit statement, newest entry first
/// (club_core#101). `hasMore` is true while older entries remain.
typedef CreditStatement = ({List<CreditEntry> entries, bool hasMore});
