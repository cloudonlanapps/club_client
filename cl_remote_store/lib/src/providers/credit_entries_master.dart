import 'package:cl_remote_store/src/models/credit_statement.dart';
import 'package:cl_remote_store/src/providers/capabilities.dart';
import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/providers/resource_version.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How many statement lines one page loads.
const creditStatementPageSize = 30;

/// Master provider for one member's credit statement, newest first
/// (club_core#101).
///
/// Keyed by username. The first build loads one page; `loadMore` appends
/// the next. Each entry carries the server's running `balanceAfter` and
/// `totalAfter`, which the statement shows as they are: they are never
/// recomputed here. Empty, with no server call, unless
/// [creditSystemProvider] is `true`. Refetches from the first page whenever
/// `creditsVersion` is bumped.
final AutoDisposeAsyncNotifierProviderFamily<
  ClCreditEntriesMasterNotifier,
  CreditStatement,
  String
>
clCreditEntriesMasterProvider = AsyncNotifierProvider.autoDispose
    .family<ClCreditEntriesMasterNotifier, CreditStatement, String>(
      ClCreditEntriesMasterNotifier.new,
    );

/// Notifier over one member's paged credit statement.
class ClCreditEntriesMasterNotifier
    extends AutoDisposeFamilyAsyncNotifier<CreditStatement, String> {
  String get username => arg;

  /// Set while a [loadMore] is in flight, so a scroll does not ask twice.
  bool loadingMore = false;

  @override
  Future<CreditStatement> build(String arg) async {
    ref
      ..watch(clManualRefreshProvider)
      ..watch(clResourceVersionProvider.select((s) => s.creditsVersion));
    if (ref.watch(creditSystemProvider) != true) {
      return (entries: const <CreditEntry>[], hasMore: false);
    }
    final page = await fetchPage(0);
    return (entries: page.items, hasMore: page.hasMore);
  }

  Future<PaginatedList<CreditEntry>> fetchPage(int offset) async {
    final client = await ref.read(secureClientProvider.future);
    return client.myCredits.listMyEntries(
      username,
      order: EntryOrder.newestFirst,
      offset: offset,
      limit: creditStatementPageSize,
    );
  }

  /// Appends the next page of older entries, if there is one.
  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || !current.hasMore || loadingMore) return;
    loadingMore = true;
    try {
      final page = await fetchPage(current.entries.length);
      state = AsyncData((
        entries: [...current.entries, ...page.items],
        hasMore: page.hasMore,
      ));
    } finally {
      loadingMore = false;
    }
  }
}
