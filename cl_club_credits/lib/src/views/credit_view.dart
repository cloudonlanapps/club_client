import 'dart:async';

import 'package:cl_remote_store/cl_remote_store.dart'
    show
        clCreditAccountsMasterProvider,
        clCreditEntriesMasterProvider,
        clEventsMasterProvider,
        clMyEventsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart'
    show CreditAccount, Event, UserPrivate;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/credit_grant_prefill.dart';
import '../widgets/credit_account_menu.dart';
import '../widgets/credit_account_row.dart';
import '../widgets/credit_action_launchers.dart';
import '../widgets/credit_entry_row.dart';
import '../widgets/credit_header.dart';

/// A member's credit (club_core#101): their usable total, their packages,
/// and their statement, newest first, loading older lines as it scrolls.
///
/// Readable by the member (their own) and by staff (anyone). Only an admin
/// sees actions: Add credit, and per package Extend, Reverse and Transfer.
/// Every action refreshes the whole view, the member's chips and the
/// programme rosters through `creditsVersion`.
class CreditView extends ConsumerStatefulWidget {
  const CreditView({
    required this.currentUser,
    required this.username,
    this.grantPrefill,
    super.key,
  });

  final UserPrivate currentUser;

  /// The member whose credit this is.
  final String username;

  /// Opens Add credit at once, pre-filled, when an admin arrives to fund
  /// the member (club_core#105).
  final CreditGrantPrefill? grantPrefill;

  @override
  ConsumerState<CreditView> createState() => CreditViewState();
}

class CreditViewState extends ConsumerState<CreditView> {
  /// Statement lines left below the fold when the next page is fetched.
  static const loadAheadLines = 5;

  bool get isAdmin => widget.currentUser.isAdmin;

  @override
  void initState() {
    super.initState();
    final prefill = widget.grantPrefill;
    if (prefill != null && isAdmin) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        unawaited(
          showCreditGrantDialog(
            context,
            ref,
            username: widget.username,
            programmeId: prefill.programmeId,
            trial: prefill.trial,
          ),
        );
      });
    }
  }

  CreditAccountMenu? menuFor(CreditAccount account) {
    if (!isAdmin || !CreditAccountMenu.hasActions(account)) return null;
    return CreditAccountMenu(
      account: account,
      onExtend: () =>
          unawaited(showCreditExtendDialog(context, ref, account: account)),
      onReverse: () =>
          unawaited(showCreditReverseDialog(context, ref, account: account)),
      onTransfer: () =>
          unawaited(showCreditTransferDialog(context, ref, account: account)),
    );
  }

  @override
  Widget build(BuildContext context) {
    assert(
      widget.currentUser.username == widget.username ||
          widget.currentUser.isCoachOrAdmin,
      'CreditView for ${widget.username} opened by '
      '${widget.currentUser.username}, who is neither the member nor staff.',
    );
    final accounts =
        ref
            .watch(clCreditAccountsMasterProvider(widget.username))
            .valueOrNull ??
        const <CreditAccount>[];
    final statement = ref
        .watch(clCreditEntriesMasterProvider(widget.username))
        .valueOrNull;
    final entries = statement?.entries ?? const [];
    // The member's own events name what they are enrolled in; staff also
    // see the club's programmes, e.g. one funded before an invite.
    final titles = {
      if (widget.currentUser.isCoachOrAdmin)
        for (final e
            in ref.watch(clEventsMasterProvider).valueOrNull?.values ??
                const <Event>[])
          e.id: e.title,
      for (final e
          in ref.watch(clMyEventsMasterProvider(widget.username)).valueOrNull ??
              const <Event>[])
        e.id: e.title,
    };
    final sorted = [...accounts]
      ..sort((a, b) {
        if (a.usable != b.usable) return a.usable ? -1 : 1;
        return b.validUntilUtc.compareTo(a.validUntilUtc);
      });
    final hasMore = statement?.hasMore ?? false;

    // Header, packages, a divider, the statement, and a loader while more.
    final headerCount = 1 + sorted.length + 1;
    final itemCount = headerCount + entries.length + (hasMore ? 1 : 0);

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        if (index == 0) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: CreditHeader(
              currentUser: widget.currentUser,
              username: widget.username,
              onAddCredit: isAdmin
                  ? () => unawaited(
                      showCreditGrantDialog(
                        context,
                        ref,
                        username: widget.username,
                      ),
                    )
                  : null,
            ),
          );
        }
        if (index <= sorted.length) {
          final account = sorted[index - 1];
          return CreditAccountRow(
            key: ValueKey('credit-account-${account.accountId}'),
            account: account,
            programmeTitle: account.eventId == null
                ? null
                : titles[account.eventId],
            menu: menuFor(account),
          );
        }
        if (index == headerCount - 1) return const Divider(height: 24);
        final line = index - headerCount;
        if (line >= entries.length) {
          return const Padding(
            padding: EdgeInsets.all(12),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (hasMore && line >= entries.length - loadAheadLines) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!mounted) return;
            unawaited(
              ref
                  .read(clCreditEntriesMasterProvider(widget.username).notifier)
                  .loadMore(),
            );
          });
        }
        final entry = entries[line];
        return CreditEntryRow(
          key: ValueKey('credit-entry-${entry.id}'),
          entry: entry,
          eventTitle: entry.eventId == null ? null : titles[entry.eventId],
        );
      },
    );
  }
}
