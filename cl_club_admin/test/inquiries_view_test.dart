import 'package:cl_club_admin/cl_club_admin.dart';
import 'package:cl_club_admin/src/widgets/inquiry_detail.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/admin_test_scope.dart';

Future<StubInquiries> _pump(WidgetTester tester, InquiryInbox inbox) async {
  await tester.binding.setSurfaceSize(const Size(1000, 1400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final stub = StubInquiries(inbox);
  await tester.pumpWidget(
    adminScope(
      inquiries: stub,
      child: InquiriesView(currentUser: adminViewer()),
    ),
  );
  await tester.pumpAndSettle();
  return stub;
}

void main() {
  group('Issue 21: the inquiries inbox', () {
    testWidgets('Issue 21: a row shows kind, sender, contact and the first '
        'line of the message', (tester) async {
      await _pump(
        tester,
        inboxOf([
          inquiry(
            7,
            kind: InquiryKind.interest,
            phone: '+91 98765 43210',
            message: 'First line here\nSecond line hidden',
          ),
        ]),
      );

      final row = find.byKey(const ValueKey('inquiryRow.7'));
      expect(row, findsOneWidget);
      Finder inRow(String text) =>
          find.descendant(of: row, matching: find.textContaining(text));
      expect(inRow('Sender 7'), findsOneWidget);
      expect(inRow('Interest'), findsOneWidget);
      expect(inRow('sender7@example.com'), findsOneWidget);
      expect(inRow('+91 98765 43210'), findsOneWidget);
      expect(inRow('First line here'), findsOneWidget);
      expect(inRow('Second line hidden'), findsNothing);
    });

    testWidgets('Issue 21: a handled row says who handled it', (tester) async {
      await _pump(
        tester,
        inboxOf([inquiry(3, handled: true)], filter: const InquiryFilter()),
      );
      expect(find.textContaining('Handled by someadmin'), findsOneWidget);
    });

    testWidgets('Issue 21: an empty inbox says so', (tester) async {
      await _pump(tester, inboxOf(const []));
      expect(find.text('No inquiries.'), findsOneWidget);
    });

    testWidgets('Issue 21: the filters ask the master for kind and handled '
        'state', (tester) async {
      final stub = await _pump(tester, inboxOf([inquiry(1)]));

      await tester.tap(
        find.byKey(const ValueKey('inquiryFilter.kind.contact')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('inquiryFilter.state.handled')),
      );
      await tester.pumpAndSettle();

      expect(stub.filters, [
        const InquiryFilter(kind: InquiryKind.contact, handled: false),
        const InquiryFilter(kind: InquiryKind.contact, handled: true),
      ]);
    });

    testWidgets('Issue 21: the detail shows the full message and extra, and '
        'marks it handled', (tester) async {
      final stub = await _pump(
        tester,
        inboxOf([
          inquiry(
            5,
            message: 'Line one\nLine two',
            extra: const {'programme': 'Juniors'},
          ),
        ]),
      );

      await tester.tap(find.byKey(const ValueKey('inquiryRow.5')));
      await tester.pumpAndSettle();

      final detail = find.byType(InquiryDetail);
      expect(detail, findsOneWidget);
      expect(
        find.descendant(of: detail, matching: find.text('Line one\nLine two')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: detail, matching: find.textContaining('Juniors')),
        findsOneWidget,
      );

      await tester.tap(find.text('Mark handled'));
      await tester.pumpAndSettle();
      expect(stub.handledCalls, ['5 true']);
      expect(find.text('Mark open'), findsOneWidget);
    });

    testWidgets('Issue 21: delete asks first, then removes it', (
      tester,
    ) async {
      final stub = await _pump(tester, inboxOf([inquiry(9)]));

      await tester.tap(find.byKey(const ValueKey('inquiryRow.9')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();
      expect(find.text('Delete inquiry?'), findsOneWidget);
      expect(stub.deleted, isEmpty);

      await tester.tap(find.text('Delete').last);
      await tester.pumpAndSettle();
      expect(stub.deleted, [9]);
      expect(find.byType(InquiryDetail), findsNothing);
    });
  });
}
