import 'package:flutter/material.dart';
import 'package:ui_lib/ui_lib.dart' show DetailRow;

import '../../models/marketing_read_entry.dart';

/// A marketing card's read view: a [DetailRow] for each entry that has a
/// value.
class MarketingReadRows extends StatelessWidget {
  const MarketingReadRows({required this.entries, super.key});

  /// The lines, in order; one with no value is left out.
  final List<MarketingReadEntry> entries;

  /// Whether no entry has a value.
  static bool isEmptyOf(List<MarketingReadEntry> entries) =>
      entries.every((entry) => (entry.value ?? '').trim().isEmpty);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final entry in entries)
          if ((entry.value ?? '').trim().isNotEmpty)
            DetailRow(
              icon: entry.icon,
              label: entry.label,
              value: entry.value!,
            ),
      ],
    );
  }
}
