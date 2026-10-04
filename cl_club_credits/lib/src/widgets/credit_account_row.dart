import 'package:club_sdk_2/club_sdk_2.dart'
    show CreditAccount, CreditAccountKind, CreditAccountState;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../utils/credit_dates.dart';
import 'credit_account_menu.dart';

/// One package (credit account) in the credit view (club_core#101): its
/// balance, validity, what it is bound to (📌 programme or 🌐 general), 🧪
/// for a trial, and its state, dimmed when it cannot be spent. Expired
/// balances stay visible (R64). Tapping shows the 8-character code, to read
/// out over the phone (R91). Admins get a row menu.
class CreditAccountRow extends StatefulWidget {
  const CreditAccountRow({
    required this.account,
    this.programmeTitle,
    this.menu,
    super.key,
  });

  final CreditAccount account;

  /// The programme a bound account pays for, when known.
  final String? programmeTitle;

  /// The admin row menu; null for coaches and the member.
  final CreditAccountMenu? menu;

  @override
  State<CreditAccountRow> createState() => CreditAccountRowState();
}

class CreditAccountRowState extends State<CreditAccountRow> {
  bool showCode = false;

  /// The icon marking a package that cannot be spent, or null when usable.
  IconData? get stateIcon => switch (widget.account.state) {
    CreditAccountState.usable => null,
    CreditAccountState.empty => LucideIcons.circleSlash,
    CreditAccountState.expired => LucideIcons.hourglass,
    CreditAccountState.closed => LucideIcons.lock,
  };

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final account = widget.account;
    final muted = theme.textTheme.muted;
    final bound = account.kind == CreditAccountKind.event;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => setState(() => showCode = !showCode),
      child: Opacity(
        opacity: account.usable ? 1 : 0.5,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            spacing: 8,
            children: [
              const Icon(LucideIcons.coins, size: 16),
              SizedBox(
                width: 36,
                child: Text('${account.balance}', style: theme.textTheme.large),
              ),
              Icon(bound ? LucideIcons.pin : LucideIcons.globe, size: 14),
              if (account.isTrial)
                const Icon(LucideIcons.flaskConical, size: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (bound && widget.programmeTitle != null)
                      Text(
                        widget.programmeTitle!,
                        overflow: TextOverflow.ellipsis,
                      ),
                    Text(
                      creditRange(account.validFromUtc, account.validUntilUtc),
                      style: muted,
                    ),
                    if (showCode)
                      SelectableText(
                        account.accountId,
                        style: theme.textTheme.small.copyWith(
                          fontFamily: 'monospace',
                        ),
                      ),
                  ],
                ),
              ),
              if (stateIcon != null)
                Icon(
                  stateIcon,
                  size: 14,
                  color: theme.colorScheme.mutedForeground,
                ),
              ?widget.menu,
            ],
          ),
        ),
      ),
    );
  }
}
