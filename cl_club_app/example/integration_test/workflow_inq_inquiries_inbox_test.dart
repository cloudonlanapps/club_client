// workflow_inq: the admin inquiries inbox (club_core#21).
//
// Two inquiries — one contact, one interest — are submitted through the
// public inquiry endpoint, as the website's forms do (the app has no form of
// its own). Then an admin (the super-admin `sudo`):
//
//   * finds an `inquiry.received` notification for each, and tapping one
//     opens the inbox (club_core#32);
//   * sees the open count beside Inquiries in the sidebar's Admin section,
//     and opens the inbox from there;
//   * filters by kind, opens the contact inquiry, reads its full message and
//     extra, and marks it handled — the count drops by one and the row moves
//     to the Handled filter, stamped with the admin;
//   * deletes both through the detail's Delete (confirmed), which is also
//     the cleanup, and the server no longer lists them.
//
// Recommended run (from the club_core root):
//   just app-test-one app_test_server1.conf \
//       workflow_inq_inquiries_inbox_test.dart

import 'package:cl_club_admin/cl_club_admin.dart' show InquiriesView;
import 'package:cl_club_admin/src/widgets/inquiry_detail.dart'
    show InquiryDetail;
import 'package:cl_club_communication/src/views/notifications_list_view.dart'
    show NotificationsListView;
import 'package:cl_member_zone/src/widgets/sidebar/sidebar_item.dart'
    show SidebarItem;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        clNotificationsMasterProvider,
        clUnhandledInquiryCountProvider,
        secureClientProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show InquiryKind;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ConfirmDialog;

import '_helpers/auth.dart';
import '_helpers/forms.dart';
import '_helpers/pump.dart';

const _kApiBaseUrl = String.fromEnvironment(
  'CLUB_API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8155/v1',
);
const _kSudoUsername = String.fromEnvironment(
  'SUDO_USERNAME',
  defaultValue: 'sudo',
);
const _kSudoPassword = String.fromEnvironment('SUDO_PASSWORD');

const _kContactName = 'workflow_inq contact';
const _kContactEmail = 'workflow_inq_contact@example.com';
const _kContactMessage = 'workflow_inq first line\nworkflow_inq second line';
const _kInterestName = 'workflow_inq interest';
const _kInterestEmail = 'workflow_inq_interest@example.com';
const _kContactNotificationBody = '$_kContactName sent a message.';
const _kInterestNotificationBody = '$_kInterestName registered interest.';

/// The server drops a submission returned in under three seconds.
const _kMinFill = Duration(milliseconds: 3500);

Finder _row(String name) => find.ancestor(
  of: find.text(name),
  matching: find.byWidgetPredicate(
    (w) =>
        w.key is ValueKey<String> &&
        (w.key! as ValueKey<String>).value.startsWith('inquiryRow.'),
  ),
);

Finder _sidebarInquiries() => find.widgetWithText(SidebarItem, 'Inquiries');

int _sidebarCount(WidgetTester tester) =>
    tester.widget<SidebarItem>(_sidebarInquiries().first).badgeCount ?? 0;

Future<void> _openDetail(WidgetTester tester, String name) async {
  await tester.tap(find.text(name));
  await settle(tester);
  await waitFor(
    tester,
    () => find.byType(InquiryDetail).evaluate().isNotEmpty,
    description: 'the detail sheet for $name',
  );
}

Future<void> _closeSheet(WidgetTester tester) async {
  // The sheet's own close button (top corner of the sheet).
  final close = find.descendant(
    of: find.byType(ShadSheet),
    matching: find.byType(ShadIconButton),
  );
  expect(close, findsOneWidget, reason: 'the sheet close button');
  tester.widget<ShadIconButton>(close).onPressed!.call();
  await settle(tester);
  await waitFor(
    tester,
    () => find.byType(InquiryDetail).evaluate().isEmpty,
    description: 'the detail sheet to close',
  );
}

Future<void> _deleteOpen(WidgetTester tester) async {
  invokeShadButton(
    tester,
    find.descendant(
      of: find.byType(InquiryDetail),
      matching: find.widgetWithText(ShadButton, 'Delete'),
    ),
    reason: 'Delete in the detail',
  );
  await settle(tester);
  invokeShadButton(
    tester,
    find.descendant(
      of: find.byType(ConfirmDialog),
      matching: find.widgetWithText(ShadButton, 'Delete'),
    ),
    reason: 'Delete in the confirmation',
  );
  await settle(tester);
  await waitFor(
    tester,
    () => find.byType(InquiryDetail).evaluate().isEmpty,
    description: 'the sheet to close after delete',
  );
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (_kSudoPassword.isEmpty) {
    throw StateError(
      'SUDO_PASSWORD must be supplied via --dart-define '
      '(or --dart-define-from-file=integration_test/.test_env).',
    );
  }

  testWidgets(
    'an admin reads, handles and deletes website inquiries from the inbox',
    (tester) async {
      await pumpApp(tester, apiBaseUrl: _kApiBaseUrl);
      await ensureLoggedOut(tester);
      await loginViaUi(tester, _kSudoUsername, _kSudoPassword);
      await go(tester, '/memberzone/profile');

      // --- Setup: two submissions through the public endpoint. ------------
      final client = await container(tester).read(secureClientProvider.future);
      final contactToken = await client.public.getInquiryFormToken();
      final interestToken = await client.public.getInquiryFormToken();
      await tester.runAsync(() => Future<void>.delayed(_kMinFill));
      await client.public.submitInquiry(
        kind: InquiryKind.contact,
        name: _kContactName,
        email: _kContactEmail,
        phone: '+91 90000 00021',
        message: _kContactMessage,
        extra: const {'workflow_inq_topic': 'workflow_inq_extra_value'},
        token: contactToken,
      );
      await client.public.submitInquiry(
        kind: InquiryKind.interest,
        name: _kInterestName,
        email: _kInterestEmail,
        message: 'workflow_inq interest message',
        token: interestToken,
      );

      // --- The inquiry.received notification opens the inbox (#32). --------
      await container(
        tester,
      ).read(clNotificationsMasterProvider.notifier).refresh();
      await go(tester, '/memberzone/notifications');
      final notificationRow = find.descendant(
        of: find.byType(NotificationsListView),
        matching: find.text(_kContactNotificationBody),
      );
      await waitFor(
        tester,
        () => notificationRow.evaluate().isNotEmpty,
        description: 'the inquiry.received notification for the contact',
      );
      expect(
        find.descendant(
          of: find.byType(NotificationsListView),
          matching: find.text(_kInterestNotificationBody),
        ),
        findsOneWidget,
        reason: 'the interest inquiry notified too',
      );
      await tester.tap(notificationRow);
      await settle(tester);
      await waitFor(
        tester,
        () => find.byType(InquiriesView).evaluate().isNotEmpty,
        description: 'the inbox opened from the notification',
      );

      // --- The sidebar entry and its count. -------------------------------
      expect(_sidebarInquiries(), findsWidgets);
      tester.widget<SidebarItem>(_sidebarInquiries().first).onTap();
      await settle(tester);
      // The inbox loaded with the shell; Refresh picks up the new rows.
      await tester.tap(find.widgetWithText(ShadButton, 'Refresh'));
      await settle(tester);
      await waitFor(
        tester,
        () =>
            _row(_kContactName).evaluate().isNotEmpty &&
            _row(_kInterestName).evaluate().isNotEmpty,
        description: 'both workflow_inq inquiries in the open inbox',
      );
      final openBefore = container(tester).read(
        clUnhandledInquiryCountProvider,
      );
      expect(openBefore, greaterThanOrEqualTo(2));
      expect(_sidebarCount(tester), openBefore);

      // --- Filter by kind. ------------------------------------------------
      await tester.tap(
        find.byKey(const ValueKey('inquiryFilter.kind.interest')),
      );
      await settle(tester);
      await waitFor(
        tester,
        () => _row(_kContactName).evaluate().isEmpty,
        description: 'the interest filter to hide the contact inquiry',
      );
      expect(_row(_kInterestName), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('inquiryFilter.kind.all')));
      await settle(tester);
      await waitFor(
        tester,
        () => _row(_kContactName).evaluate().isNotEmpty,
        description: 'all kinds again',
      );

      // --- Detail, then mark handled. -------------------------------------
      await _openDetail(tester, _kContactName);
      final detail = find.byType(InquiryDetail);
      expect(
        find.descendant(of: detail, matching: find.text(_kContactMessage)),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: detail,
          matching: find.text('workflow_inq_extra_value'),
        ),
        findsOneWidget,
      );
      invokeShadButton(
        tester,
        find.widgetWithText(ShadButton, 'Mark handled'),
        reason: 'Mark handled',
      );
      await settle(tester);
      await waitFor(
        tester,
        () =>
            find.widgetWithText(ShadButton, 'Mark open').evaluate().isNotEmpty,
        description: 'the detail to show Mark open',
      );
      await _closeSheet(tester);

      expect(_row(_kContactName), findsNothing);
      expect(
        container(tester).read(clUnhandledInquiryCountProvider),
        openBefore - 1,
      );
      expect(_sidebarCount(tester), openBefore - 1);

      // --- It sits under Handled, stamped with the admin. -----------------
      await tester.tap(
        find.byKey(const ValueKey('inquiryFilter.state.handled')),
      );
      await settle(tester);
      await waitFor(
        tester,
        () => _row(_kContactName).evaluate().isNotEmpty,
        description: 'the handled inquiry under Handled',
      );
      expect(
        find.descendant(
          of: _row(_kContactName),
          matching: find.textContaining('Handled by $_kSudoUsername'),
        ),
        findsOneWidget,
      );

      // --- Cleanup: delete both through the UI. ---------------------------
      await _openDetail(tester, _kContactName);
      await _deleteOpen(tester);
      expect(_row(_kContactName), findsNothing);

      await tester.tap(find.byKey(const ValueKey('inquiryFilter.state.all')));
      await settle(tester);
      await waitFor(
        tester,
        () => _row(_kInterestName).evaluate().isNotEmpty,
        description: 'the interest inquiry under All',
      );
      await _openDetail(tester, _kInterestName);
      await _deleteOpen(tester);
      expect(_row(_kInterestName), findsNothing);
      expect(
        container(tester).read(clUnhandledInquiryCountProvider),
        openBefore - 2,
      );

      final left = await client.inquiries.listInquiries(limit: 100);
      expect(
        left.items.where((i) => i.name.startsWith('workflow_inq')),
        isEmpty,
        reason: 'both workflow_inq inquiries are gone from the server',
      );
    },
  );
}
