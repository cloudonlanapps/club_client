import 'dart:async';

import 'package:cl_remote_store/cl_remote_store.dart'
    show InquiryFilter, clInquiriesMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show LoadingView, TitleRow;

import '../widgets/inquiry_filter_bar.dart';
import '../widgets/inquiry_list.dart';
import '../widgets/inquiry_sheet.dart';

/// The admin inquiry inbox (club_core#21): what the public website's
/// contact and interest forms submitted.
///
/// Filters by kind and handled state (opening on open inquiries of every
/// kind), pages newest first, and opens a row in a side sheet with the full
/// message, Mark handled / Mark open and Delete. Gating is the screen's job;
/// this view asserts the admin precondition it was promised.
class InquiriesView extends ConsumerWidget {
  const InquiriesView({required this.currentUser, this.onBack, super.key});

  final UserPrivate currentUser;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(
      currentUser.isAdmin,
      'InquiriesView reached by a non-admin. Screen gate failed.',
    );
    final inbox = ref.watch(clInquiriesMasterProvider);
    final notifier = ref.read(clInquiriesMasterProvider.notifier);
    final filter = inbox.valueOrNull?.filter ?? InquiryFilter.open;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TitleRow(
          title: 'Inquiries',
          subtitle: 'Contact and interest forms from the website',
          onBack: onBack,
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: InquiryFilterBar(
                  filter: filter,
                  onChanged: (f) => unawaited(notifier.setFilter(f)),
                ),
              ),
              ShadButton.outline(
                size: ShadButtonSize.sm,
                leading: const Icon(LucideIcons.refreshCw, size: 16),
                onPressed: notifier.refresh,
                child: const Text('Refresh'),
              ),
            ],
          ),
        ),
        Expanded(
          child: inbox.when(
            loading: () => const LoadingView(message: 'Loading inquiries…'),
            error: (_, _) => Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                spacing: 8,
                children: [
                  const Text("Couldn't load inquiries."),
                  ShadButton.outline(
                    size: ShadButtonSize.sm,
                    onPressed: notifier.refresh,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            ),
            data: (inbox) => InquiryList(
              inbox: inbox,
              onOpen: (inquiry) =>
                  unawaited(showInquirySheet(context, inquiry)),
              onPrevious: () => unawaited(notifier.previousPage()),
              onNext: () => unawaited(notifier.nextPage()),
            ),
          ),
        ),
      ],
    );
  }
}
