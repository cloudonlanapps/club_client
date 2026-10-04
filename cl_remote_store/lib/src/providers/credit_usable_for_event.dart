import 'package:cl_remote_store/src/providers/capabilities.dart';
import 'package:cl_remote_store/src/providers/credit_accounts_master.dart';
import 'package:cl_remote_store/src/utils/credit_funding.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Key: whose credit, for which programme, and for a trial or not.
typedef ClCreditUsableKey = ({String username, int eventId, bool trial});

/// Credit `username` can spend on one programme
/// (club_core#97, #105): what decides whether accepting, requesting,
/// approving or assigning can go through. Callers ask only for programmes.
///
/// Null while unknown — capabilities unanswered, credit off, or accounts
/// not loaded — in which case nothing is greyed out. Derived from
/// [clCreditAccountsMasterProvider].
final AutoDisposeProviderFamily<int?, ClCreditUsableKey>
clCreditUsableForEventProvider = Provider.autoDispose
    .family<int?, ClCreditUsableKey>((ref, key) {
      if (ref.watch(creditSystemProvider) != true) return null;
      final accounts = ref
          .watch(clCreditAccountsMasterProvider(key.username))
          .valueOrNull;
      if (accounts == null) return null;
      return usableCreditsFor(
        accounts,
        eventId: key.eventId,
        trial: key.trial,
      );
    });
