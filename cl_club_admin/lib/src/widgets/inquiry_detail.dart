import 'package:cl_remote_store/cl_remote_store.dart'
    show clInquiriesMasterProvider, defaultCountryCodeProvider;
import 'package:cl_server_config/cl_server_config.dart' show DateTimeFormat;
import 'package:club_sdk_2/club_sdk_2.dart' show Inquiry;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show ConfirmDialog, EmailContact, PhoneContact;

import '../models/inquiry_filter_options.dart';
import '../models/inquiry_reply.dart';
import 'labeled_content.dart';
import 'labeled_value.dart';

/// One inquiry in full — the whole message and whatever else the form sent
/// (`extra`) — with Mark handled / Mark open and Delete. The sender's email
/// and phone carry the buttons that reach them (#32).
///
/// Lives in the sheet the inbox opens; Delete closes that sheet once the
/// inquiry is gone. Every action goes through `clInquiriesMasterProvider`.
class InquiryDetail extends ConsumerStatefulWidget {
  const InquiryDetail({required this.inquiry, super.key});

  final Inquiry inquiry;

  @override
  ConsumerState<InquiryDetail> createState() => InquiryDetailState();
}

class InquiryDetailState extends ConsumerState<InquiryDetail> {
  /// Label of the button that starts an email to the sender.
  static const String replyLabel = 'Reply with Email';

  late Inquiry inquiry = widget.inquiry;
  bool busy = false;

  Future<void> toggleHandled() async {
    final toaster = ShadToaster.of(context);
    final handled = !inquiry.isHandled;
    setState(() => busy = true);
    try {
      final updated = await ref
          .read(clInquiriesMasterProvider.notifier)
          .setHandled(inquiry.id, handled: handled);
      if (!mounted) return;
      setState(() => inquiry = updated);
      toaster.show(
        ShadToast(
          description: Text(
            handled ? 'Inquiry marked handled.' : 'Inquiry reopened.',
          ),
        ),
      );
    } on Object catch (_) {
      toaster.show(
        const ShadToast.destructive(
          description: Text('Could not update the inquiry. Please try again.'),
        ),
      );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> delete() async {
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete inquiry?',
      message:
          'This removes the inquiry and the personal details in it '
          'permanently.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !mounted) return;
    final toaster = ShadToaster.of(context);
    final navigator = Navigator.of(context);
    setState(() => busy = true);
    try {
      await ref
          .read(clInquiriesMasterProvider.notifier)
          .deleteInquiry(inquiry.id);
      toaster.show(const ShadToast(description: Text('Inquiry deleted.')));
      // Close the sheet this inquiry was opened in.
      navigator.pop();
    } on Object catch (_) {
      toaster.show(
        const ShadToast.destructive(
          description: Text('Could not delete the inquiry. Please try again.'),
        ),
      );
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final phone = inquiry.phone;
    final handledAt = inquiry.handledAtUtc;
    final extra = inquiry.extra ?? const <String, dynamic>{};
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: 16,
        children: [
          Text(inquiry.name, style: theme.textTheme.h4),
          LabeledValue(label: 'Kind', value: inquiryKindLabel(inquiry.kind)),
          LabeledContent(
            label: 'Email',
            child: EmailContact(
              address: inquiry.email,
              actionLabel: replyLabel,
              subject: InquiryReply.subject(inquiry),
            ),
          ),
          if (phone != null && phone.isNotEmpty)
            LabeledContent(
              label: 'Phone',
              child: PhoneContact(
                number: phone,
                defaultCountryCode: ref.watch(defaultCountryCodeProvider),
              ),
            ),
          LabeledValue(
            label: 'Received',
            value: inquiry.createdAtUtc.toLocalDateTimeMedium(),
          ),
          LabeledValue(
            label: 'Status',
            value: handledAt == null
                ? 'Open'
                : 'Handled by ${inquiry.handledBy ?? 'an admin'} · '
                      '${handledAt.toLocalDateTimeMedium()}',
          ),
          LabeledValue(label: 'Message', value: inquiry.message),
          for (final entry in extra.entries)
            LabeledValue(label: entry.key, value: '${entry.value}'),
          const Divider(height: 1),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ShadButton.outline(
                onPressed: busy ? null : toggleHandled,
                child: Text(inquiry.isHandled ? 'Mark open' : 'Mark handled'),
              ),
              ShadButton.destructive(
                onPressed: busy ? null : delete,
                child: const Text('Delete'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
