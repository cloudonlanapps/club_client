import 'package:cl_server_config/cl_server_config.dart' show DateTimeFormat;
import 'package:club_sdk_2/club_sdk_2.dart' show Inquiry;
import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show EntityCard, EntityImage;

import '../models/inquiry_filter_options.dart';

/// One inquiry in the inbox list: kind, sender, how to reach them, the
/// first line of the message, when it arrived and who handled it. Handled
/// rows render muted. Tapping opens the detail.
class InquiryRow extends StatelessWidget {
  const InquiryRow({required this.inquiry, required this.onTap, super.key});

  final Inquiry inquiry;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final kind = inquiryKindLabel(inquiry.kind);
    final phone = inquiry.phone;
    final firstLine = inquiry.message.split('\n').first;
    final handledAt = inquiry.handledAtUtc;
    return EntityCard(
      key: ValueKey('inquiryRow.${inquiry.id}'),
      image: EntityImage.initials(kind.substring(0, 1)),
      title: inquiry.name,
      caption: [
        kind,
        inquiry.email,
        if (phone != null && phone.isNotEmpty) phone,
      ].join(' · '),
      muted: inquiry.isHandled,
      onTap: onTap,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 2,
        children: [
          Text(firstLine, maxLines: 1, overflow: TextOverflow.ellipsis),
          Text(
            'Received ${inquiry.createdAtUtc.toLocalDateTimeMedium()}',
            style: theme.textTheme.muted,
          ),
          if (handledAt != null)
            Text(
              'Handled by ${inquiry.handledBy ?? 'an admin'} · '
              '${handledAt.toLocalDateTimeMedium()}',
              style: theme.textTheme.muted,
            ),
        ],
      ),
    );
  }
}
