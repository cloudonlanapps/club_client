import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../../utils/public_event_format.dart';

/// Which row of the fee table a [PublicEventFeeTableRow] is.
enum PublicEventFeeTableRowKind { header, fee, total }

/// One row of a programme's fee table: name, period and amount.
///
/// The header is bold italic on a muted band, a fee row sits over a divider,
/// and the total is larger and heavier on a muted band so it reads as the
/// table's footer. Emphasis is weight, not colour.
class PublicEventFeeTableRow extends StatelessWidget {
  const PublicEventFeeTableRow({
    required this.kind,
    required this.name,
    required this.period,
    required this.amount,
    required this.showPeriod,
    super.key,
  });

  final PublicEventFeeTableRowKind kind;
  final String name;
  final String period;
  final String amount;

  /// Whether the period column shows (not on a phone).
  final bool showPeriod;

  /// An amount as the table shows it, e.g. "₹1,000".
  static String formatAmount(int amount) =>
      '$kCurrencySymbol${formatThousands(amount)}';

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final small = theme.textTheme.small;
    final p = theme.textTheme.p;
    final band = theme.colorScheme.muted.withValues(alpha: 0.5);

    final (
      TextStyle nameStyle,
      TextStyle periodStyle,
      TextStyle amountStyle,
    ) = switch (kind) {
      PublicEventFeeTableRowKind.header => (
        small.copyWith(
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
        ),
        small.copyWith(
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
        ),
        small.copyWith(
          fontWeight: FontWeight.w700,
          fontStyle: FontStyle.italic,
        ),
      ),
      PublicEventFeeTableRowKind.fee => (
        small.copyWith(fontWeight: FontWeight.w600),
        small,
        p.copyWith(fontWeight: FontWeight.w600),
      ),
      PublicEventFeeTableRowKind.total => (
        p.copyWith(
          fontWeight: FontWeight.w800,
          fontSize: 17,
          letterSpacing: 0.3,
        ),
        small.copyWith(
          fontStyle: FontStyle.italic,
          fontWeight: FontWeight.w600,
        ),
        p.copyWith(
          fontWeight: FontWeight.w900,
          fontSize: 20,
          letterSpacing: 0.2,
        ),
      ),
    };

    final decoration = switch (kind) {
      PublicEventFeeTableRowKind.header => BoxDecoration(
        color: band,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
      ),
      PublicEventFeeTableRowKind.fee => BoxDecoration(
        border: Border(bottom: BorderSide(color: theme.colorScheme.border)),
      ),
      PublicEventFeeTableRowKind.total => BoxDecoration(
        color: band,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
        border: Border(
          top: BorderSide(color: theme.colorScheme.border, width: 2),
        ),
      ),
    };

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 16,
        vertical: kind == PublicEventFeeTableRowKind.total ? 18 : 12,
      ),
      decoration: decoration,
      child: Row(
        children: [
          Expanded(flex: 3, child: Text(name, style: nameStyle)),
          if (showPeriod)
            Expanded(
              flex: 2,
              child: Text(
                period,
                style: periodStyle,
                textAlign: TextAlign.center,
              ),
            ),
          Expanded(
            flex: 2,
            child: Text(amount, style: amountStyle, textAlign: TextAlign.right),
          ),
        ],
      ),
    );
  }
}
