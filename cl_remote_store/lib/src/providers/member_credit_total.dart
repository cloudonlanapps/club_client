import 'package:cl_remote_store/src/providers/capabilities.dart';
import 'package:cl_remote_store/src/providers/credit_accounts_master.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// A member's usable credit: the sum of the balances of their accounts that
/// are `usable` now (club_core#102). Expired and empty balances are not
/// counted; the credit screen shows them.
///
/// Null while unknown: before the capabilities answer, with the credit
/// system off, or before the accounts have loaded. Derived from
/// [clCreditAccountsMasterProvider]; makes no call of its own.
final AutoDisposeProviderFamily<int?, String> clMemberCreditTotalProvider =
    Provider.autoDispose.family<int?, String>((ref, username) {
      if (ref.watch(creditSystemProvider) != true) return null;
      final accounts = ref
          .watch(clCreditAccountsMasterProvider(username))
          .valueOrNull;
      if (accounts == null) return null;
      return accounts
          .where((a) => a.usable)
          .fold<int>(0, (sum, a) => sum + a.balance);
    });
