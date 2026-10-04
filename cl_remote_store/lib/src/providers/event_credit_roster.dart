import 'package:cl_remote_store/src/providers/capabilities.dart';
import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/events_master.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/providers/resource_version.dart';
import 'package:cl_remote_store/src/utils/credit_funding.dart';
import 'package:cl_remote_store/src/utils/fetch_all_pages.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A programme's credit roster, keyed by membername (club_core#96, #99):
/// one row per enrolled member — `withdrawRequested` included — with the
/// credit they can spend there (`blocked` when none) and the credit still
/// bound to it (`boundCredits`), which must be settled before they leave.
///
/// Empty, with no call, unless the credit system is on and the event is a
/// programme: the roster answers 503 with credit off and 422 for a camp or
/// one-off. Staff only (admin or coach). A snapshot, refetched whenever
/// `creditsVersion` is bumped.
final AutoDisposeAsyncNotifierProviderFamily<
  ClEventCreditRosterNotifier,
  Map<String, MemberCreditStatus>,
  int
>
clEventCreditRosterProvider = AsyncNotifierProvider.autoDispose
    .family<ClEventCreditRosterNotifier, Map<String, MemberCreditStatus>, int>(
      ClEventCreditRosterNotifier.new,
    );

/// Notifier over one programme's credit roster.
class ClEventCreditRosterNotifier
    extends
        AutoDisposeFamilyAsyncNotifier<Map<String, MemberCreditStatus>, int> {
  int get eventId => arg;

  @override
  Future<Map<String, MemberCreditStatus>> build(int arg) async {
    ref
      ..watch(clManualRefreshProvider)
      ..watch(clResourceVersionProvider.select((s) => s.creditsVersion));
    if (ref.watch(creditSystemProvider) != true) return const {};
    final type = ref.watch(
      clEventsMasterProvider.select((s) => s.valueOrNull?[eventId]?.type),
    );
    if (type != EventType.programme) return const {};
    final client = await ref.read(secureClientProvider.future);
    final rows = await fetchAllPages(
      ({required offset, required limit}) => client.credits.listEventCredits(
        eventId,
        offset: offset,
        limit: limit,
      ),
      pageSize: creditPageSize,
    );
    return {for (final row in rows) row.membername: row};
  }
}
