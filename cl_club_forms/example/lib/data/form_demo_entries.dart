import '../models/form_demo_entry.dart';
import '../models/form_demo_group.dart';
import 'account_entries.dart';
import 'club_identity_entries.dart';
import 'credit_entries.dart';
import 'event_entries.dart';
import 'group_entries.dart';
import 'schedule_entries.dart';
import 'user_entries.dart';
import 'venue_entries.dart';

/// Every entry of the sidebar. A form added to the package gets an entry in
/// its family's file; `test/form_demo_entries_test.dart` fails until it has.
abstract final class FormDemoEntries {
  /// The entries, family by family, in the order shown.
  static final List<FormDemoEntry> all = List.unmodifiable([
    ...AccountEntries.all,
    ...UserEntries.all,
    ...EventEntries.all,
    ...ScheduleEntries.all,
    ...CreditEntries.all,
    ...GroupEntries.all,
    ...VenueEntries.all,
    ...ClubIdentityEntries.all,
  ]);

  /// The entries of [group], in the order shown.
  static List<FormDemoEntry> of(FormDemoGroup group) => [
    for (final entry in all)
      if (entry.group == group) entry,
  ];
}
