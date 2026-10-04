import 'package:club_sdk_2/club_sdk_2.dart' show CreditEntry;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../utils/credit_dates.dart';
import '../utils/credit_entry_icon.dart';

/// One statement line (club_core#101): the date, what happened (an icon),
/// the signed amount, the programme, and the server's running total after
/// it (`totalAfter`, never recomputed here). A line recorded on another day
/// than the session it concerns — a correction — adds ↩ and the session's
/// date. An admin's reason (grant, penalty, reversal, transfer) shows on
/// tap; a session line's server text is never shown.
class CreditEntryRow extends StatefulWidget {
  const CreditEntryRow({required this.entry, this.eventTitle, super.key});

  final CreditEntry entry;

  /// The programme a session line concerns, when known.
  final String? eventTitle;

  @override
  State<CreditEntryRow> createState() => CreditEntryRowState();
}

class CreditEntryRowState extends State<CreditEntryRow> {
  bool showReason = false;

  bool get hasReason =>
      creditEntryHasAdminReason(widget.entry.entryType) &&
      widget.entry.reason.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final entry = widget.entry;
    final muted = theme.textTheme.muted;
    final occurrence = entry.occurrenceTimeUtc;
    final isCorrection =
        occurrence != null && differentLocalDay(occurrence, entry.createdAtUtc);
    final amount = entry.amount > 0 ? '+${entry.amount}' : '${entry.amount}';

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: hasReason ? () => setState(() => showReason = !showReason) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              spacing: 8,
              children: [
                SizedBox(
                  width: 88,
                  child: Text(creditDay(entry.createdAtUtc), style: muted),
                ),
                Icon(creditEntryIcon(entry.entryType), size: 14),
                SizedBox(width: 36, child: Text(amount)),
                Expanded(
                  child: Text(
                    widget.eventTitle ?? '',
                    style: muted,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isCorrection) ...[
                  const Icon(LucideIcons.history, size: 12),
                  Text(creditDay(occurrence), style: muted),
                ],
                if (entry.totalAfter != null) ...[
                  const Icon(LucideIcons.coins, size: 14),
                  SizedBox(
                    width: 28,
                    child: Text(
                      '${entry.totalAfter}',
                      textAlign: TextAlign.end,
                    ),
                  ),
                ],
              ],
            ),
            if (showReason)
              Padding(
                padding: const EdgeInsets.only(left: 96, top: 2),
                child: Text(
                  [
                    entry.reason,
                    if (entry.actorUsername != null) entry.actorUsername!,
                  ].join(' · '),
                  style: muted,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
