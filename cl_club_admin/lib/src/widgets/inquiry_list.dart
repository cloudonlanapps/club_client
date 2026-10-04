import 'package:cl_remote_store/cl_remote_store.dart' show InquiryInbox;
import 'package:club_sdk_2/club_sdk_2.dart' show Inquiry;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show PaginationBar;

import 'inquiry_row.dart';

/// One page of the inbox, newest first, with Previous / Next beneath.
class InquiryList extends StatelessWidget {
  const InquiryList({
    required this.inbox,
    required this.onOpen,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  final InquiryInbox inbox;
  final ValueChanged<Inquiry> onOpen;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final page = inbox.page;
    if (page.items.isEmpty) {
      return Center(
        child: Text(
          'No inquiries.',
          style: ShadTheme.of(context).textTheme.muted,
        ),
      );
    }
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            itemCount: page.items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final inquiry = page.items[i];
              return InquiryRow(
                inquiry: inquiry,
                onTap: () => onOpen(inquiry),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
          child: PaginationBar(
            total: page.total,
            limit: page.limit,
            offset: page.offset,
            onPrevious: onPrevious,
            onNext: onNext,
          ),
        ),
      ],
    );
  }
}
