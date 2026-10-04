import 'package:club_sdk_2/club_sdk_2.dart'
    show CreditAccount, CreditAccountKind, CreditAccountState;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The admin menu on a package row (club_core#101): 📅 Extend, ↶ Reverse
/// (while something is unspent) and ⇄ Transfer (for an expired or
/// programme-bound package — how a programme is settled). Nothing is
/// offered on a closed package.
class CreditAccountMenu extends StatefulWidget {
  const CreditAccountMenu({
    required this.account,
    required this.onExtend,
    required this.onReverse,
    required this.onTransfer,
    super.key,
  });

  final CreditAccount account;
  final VoidCallback onExtend;
  final VoidCallback onReverse;
  final VoidCallback onTransfer;

  /// Whether [account] has any action at all.
  static bool hasActions(CreditAccount account) =>
      account.state != CreditAccountState.closed;

  @override
  State<CreditAccountMenu> createState() => CreditAccountMenuState();
}

class CreditAccountMenuState extends State<CreditAccountMenu> {
  final controller = ShadPopoverController();

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void run(VoidCallback action) {
    controller.hide();
    action();
  }

  @override
  Widget build(BuildContext context) {
    final account = widget.account;
    final canReverse = account.balance > 0;
    final canTransfer =
        account.state == CreditAccountState.expired ||
        account.kind == CreditAccountKind.event;
    return ShadPopover(
      controller: controller,
      popover: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ShadButton.ghost(
            size: ShadButtonSize.sm,
            leading: const Icon(LucideIcons.calendarPlus, size: 14),
            onPressed: () => run(widget.onExtend),
            child: const Text('Extend'),
          ),
          if (canReverse)
            ShadButton.ghost(
              size: ShadButtonSize.sm,
              leading: const Icon(LucideIcons.undo2, size: 14),
              onPressed: () => run(widget.onReverse),
              child: const Text('Reverse'),
            ),
          if (canTransfer)
            ShadButton.ghost(
              size: ShadButtonSize.sm,
              leading: const Icon(LucideIcons.arrowLeftRight, size: 14),
              onPressed: () => run(widget.onTransfer),
              child: const Text('Transfer'),
            ),
        ],
      ),
      child: ShadIconButton.ghost(
        icon: const Icon(LucideIcons.ellipsisVertical, size: 16),
        onPressed: controller.toggle,
      ),
    );
  }
}
