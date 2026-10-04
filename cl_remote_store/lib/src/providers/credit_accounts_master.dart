import 'package:cl_remote_store/src/providers/capabilities.dart';
import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/providers/resource_version.dart';
import 'package:cl_remote_store/src/utils/bump_credits_version.dart';
import 'package:cl_remote_store/src/utils/uncertain_write.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Master provider for one member's credit accounts (club_core#101, #102).
///
/// Keyed by username. Holds every account, closed ones included, from
/// `listMyAccounts` — the call a member uses for their own accounts and
/// staff use for anyone's. Empty, with no server call, unless
/// [creditSystemProvider] is `true`: the credit routes answer 503 where the
/// module is off.
///
/// The admin mutations live here because each acts on this member's
/// accounts. After each, `creditsVersion` is bumped, so the accounts, the
/// statement, the programme rosters and every chip refetch.
final AutoDisposeAsyncNotifierProviderFamily<
  ClCreditAccountsMasterNotifier,
  List<CreditAccount>,
  String
>
clCreditAccountsMasterProvider = AsyncNotifierProvider.autoDispose
    .family<ClCreditAccountsMasterNotifier, List<CreditAccount>, String>(
      ClCreditAccountsMasterNotifier.new,
    );

/// Notifier over one member's credit accounts.
class ClCreditAccountsMasterNotifier
    extends AutoDisposeFamilyAsyncNotifier<List<CreditAccount>, String> {
  String get username => arg;

  @override
  Future<List<CreditAccount>> build(String arg) async {
    ref
      ..watch(clManualRefreshProvider)
      ..watch(clResourceVersionProvider.select((s) => s.creditsVersion));
    if (ref.watch(creditSystemProvider) != true) return const [];
    final client = await ref.read(secureClientProvider.future);
    return client.myCredits.listMyAccounts(username, includeClosed: true);
  }

  /// Opens a new account holding [credits] for this member: bound to the
  /// programme [eventId], or general when null. Admin only.
  Future<CreditAccount> openAccount({
    required int credits,
    required DateTime validFromUtc,
    required DateTime validUntilUtc,
    required String reason,
    int? eventId,
    bool isTrial = false,
  }) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final account = await client.credits.openAccount(
        membername: username,
        credits: credits,
        validFromUtc: validFromUtc,
        validUntilUtc: validUntilUtc,
        reason: reason,
        eventId: eventId,
        isTrial: isTrial,
      );
      bumpCreditsVersion(ref);
      return account;
    }, refetch: refetchAfterUncertainWrite);
  }

  /// Moves an account's validity end to [validUntilUtc]. Admin only.
  Future<CreditAccount> extendValidity(
    String accountId, {
    required DateTime validUntilUtc,
    required String reason,
  }) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final account = await client.credits.extendValidity(
        accountId,
        validUntilUtc: validUntilUtc,
        reason: reason,
      );
      bumpCreditsVersion(ref);
      return account;
    }, refetch: refetchAfterUncertainWrite);
  }

  /// Reverses [credits] of an account's unspent balance. Admin only.
  Future<CreditAccount> reverseGrant(
    String accountId, {
    required int credits,
    required String reason,
  }) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final account = await client.credits.reverseGrant(
        accountId,
        credits: credits,
        reason: reason,
      );
      bumpCreditsVersion(ref);
      return account;
    }, refetch: refetchAfterUncertainWrite);
  }

  /// Closes an account and moves what survives [penalty] into a new general
  /// account valid over the given window. Admin only.
  Future<CreditTransferResult> transfer(
    String accountId, {
    required int penalty,
    required DateTime validFromUtc,
    required DateTime validUntilUtc,
    required String reason,
  }) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final result = await client.credits.transfer(
        accountId,
        penalty: penalty,
        validFromUtc: validFromUtc,
        validUntilUtc: validUntilUtc,
        reason: reason,
      );
      bumpCreditsVersion(ref);
      return result;
    }, refetch: refetchAfterUncertainWrite);
  }

  /// After a credit write that may have landed ([refetchIfWriteUncertain]):
  /// reload every credit view.
  void refetchAfterUncertainWrite() {
    ref.invalidateSelf();
    bumpCreditsVersion(ref);
  }
}
