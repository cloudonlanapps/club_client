import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ClubTextTheme;

import '../../../models/public/detail_labels/event_detail_fee_structure_labels.dart';
import '../../../models/public/public_event_view.dart';
import 'public_event_fee_table_row.dart';

/// A programme's fee table: a header, one row per fee, and a total row.
///
/// The period column is dropped on a phone.
class PublicEventFeeStructureSection extends StatelessWidget {
  const PublicEventFeeStructureSection({
    required this.event,
    required this.labels,
    super.key,
  });

  /// Narrower than this is laid out for a phone.
  static const double mobileBreakpoint = 768;

  final PublicEventView event;
  final EventDetailFeeStructureLabels labels;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < mobileBreakpoint;
    final fees = event.feeStructure!;

    final total = fees.fold<int>(0, (sum, fee) => sum + fee.amount);
    // The total names a period only when every fee shares it.
    final periods = fees.map((f) => f.period).whereType<String>().toSet();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 48),
      child: Column(
        children: [
          Text(
            labels.title,
            style: theme.textTheme.sectionTitle(isMobile: isMobile),
          ),
          const SizedBox(height: 32),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: ShadCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  PublicEventFeeTableRow(
                    kind: PublicEventFeeTableRowKind.header,
                    name: labels.feeTypeHeader,
                    period: labels.periodHeader,
                    amount: labels.amountHeader,
                    showPeriod: !isMobile,
                  ),
                  for (final fee in fees)
                    PublicEventFeeTableRow(
                      kind: PublicEventFeeTableRowKind.fee,
                      name: fee.name,
                      period: fee.period ?? '-',
                      amount: PublicEventFeeTableRow.formatAmount(fee.amount),
                      showPeriod: !isMobile,
                    ),
                  PublicEventFeeTableRow(
                    kind: PublicEventFeeTableRowKind.total,
                    name: labels.totalLabel,
                    period: periods.length == 1 ? periods.first : '',
                    amount: PublicEventFeeTableRow.formatAmount(total),
                    showPeriod: !isMobile,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
