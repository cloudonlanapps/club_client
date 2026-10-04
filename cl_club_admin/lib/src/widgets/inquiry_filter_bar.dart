import 'package:cl_remote_store/cl_remote_store.dart' show InquiryFilter;
import 'package:flutter/widgets.dart';

import '../models/inquiry_filter_options.dart';
import 'filter_segments.dart';

/// The inbox filter: kind (all, contact, interest) and handled state (open,
/// handled, all). Each change hands back the whole new [InquiryFilter].
class InquiryFilterBar extends StatelessWidget {
  const InquiryFilterBar({
    required this.filter,
    required this.onChanged,
    super.key,
  });

  final InquiryFilter filter;
  final ValueChanged<InquiryFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 8,
      children: [
        FilterSegments<InquiryKindOption>(
          segments: [
            for (final o in InquiryKindOption.values)
              (
                value: o,
                label: o.label,
                key: ValueKey('inquiryFilter.kind.${o.name}'),
              ),
          ],
          selected: InquiryKindOption.of(filter.kind),
          onSelected: (o) => onChanged(filter.copyWith(kind: () => o.kind)),
        ),
        FilterSegments<InquiryStateOption>(
          segments: [
            for (final o in InquiryStateOption.values)
              (
                value: o,
                label: o.label,
                key: ValueKey('inquiryFilter.state.${o.name}'),
              ),
          ],
          selected: InquiryStateOption.of(handled: filter.handled),
          onSelected: (o) =>
              onChanged(filter.copyWith(handled: () => o.handledFilter)),
        ),
      ],
    );
  }
}
