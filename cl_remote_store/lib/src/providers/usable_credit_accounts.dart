import 'package:cl_remote_store/src/providers/capabilities.dart';
import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/providers/resource_version.dart';
import 'package:cl_remote_store/src/utils/credit_funding.dart';
import 'package:cl_remote_store/src/utils/fetch_all_pages.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every member's usable credit accounts, keyed by membername
/// (club_core#105): one staff listing (`credits.listAccounts(state:
/// usable)`, all pages) so a picker can tell who can be funded without a
/// call per member. Empty, with no call, unless the credit system is on.
/// Staff only; refetched whenever `creditsVersion` is bumped.
final AutoDisposeAsyncNotifierProvider<
  ClUsableCreditAccountsNotifier,
  Map<String, List<CreditAccount>>
>
clUsableCreditAccountsProvider =
    AsyncNotifierProvider.autoDispose<
      ClUsableCreditAccountsNotifier,
      Map<String, List<CreditAccount>>
    >(ClUsableCreditAccountsNotifier.new);

/// Notifier over the club's usable credit accounts.
class ClUsableCreditAccountsNotifier
    extends AutoDisposeAsyncNotifier<Map<String, List<CreditAccount>>> {
  @override
  Future<Map<String, List<CreditAccount>>> build() async {
    ref
      ..watch(clManualRefreshProvider)
      ..watch(clResourceVersionProvider.select((s) => s.creditsVersion));
    if (ref.watch(creditSystemProvider) != true) return const {};
    final client = await ref.read(secureClientProvider.future);
    final accounts = await fetchAllPages(
      ({required offset, required limit}) => client.credits.listAccounts(
        state: CreditAccountState.usable,
        offset: offset,
        limit: limit,
      ),
      pageSize: creditPageSize,
    );
    final byMember = <String, List<CreditAccount>>{};
    for (final a in accounts) {
      byMember.putIfAbsent(a.membername, () => []).add(a);
    }
    return byMember;
  }
}
