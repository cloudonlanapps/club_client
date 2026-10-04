import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

const Size _kSurface = Size(1024, 1600);

Future<void> _setSurface(WidgetTester tester, [Size size = _kSurface]) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

Widget _wrap(Widget child) => ShadApp(home: Scaffold(body: child));

AdminUserReviewFormData _user({
  String key = 'u1',
  String name = 'Asha Verma',
  String userName = 'asha',
  DateTime? dob,
  String gender = 'Female',
  String? note,
  int docs = 2,
}) {
  return AdminUserReviewFormData(
    userKey: key,
    fullName: name,
    userName: userName,
    dateOfBirth: dob ?? DateTime(1998, 3, 14),
    gender: gender,
    adminReviewNote: note,
    documents: List.generate(
      docs,
      (i) => IdentityDocumentSlot(
        id: '$key-doc-$i',
        uri: 'https://example.test/$key-$i',
        mimeType: 'image/jpeg',
        sizeBytes: 100000 + i,
        fileName: 'doc-$i.jpg',
      ),
    ),
  );
}

class _CallRecord {
  _CallRecord(this.label, this.data, this.reason);
  final String label;
  final AdminUserReviewFormData data;
  final String? reason;
}

class _Recorder {
  final List<_CallRecord> calls = [];
  Completer<void>? _pending;

  void block() => _pending = Completer<void>();

  void release() {
    _pending?.complete();
    _pending = null;
  }

  Future<void> approve(AdminUserReviewFormData d, String? r) async {
    calls.add(_CallRecord('approve', d, r));
    await _pending?.future;
  }

  Future<void> reject(AdminUserReviewFormData d, String? r) async {
    calls.add(_CallRecord('reject', d, r));
    await _pending?.future;
  }

  Future<void> block_(AdminUserReviewFormData d, String? r) async {
    calls.add(_CallRecord('block', d, r));
    await _pending?.future;
  }
}

Widget _form({
  required AdminUserReviewFormData user,
  required _Recorder rec,
}) {
  return _wrap(
    AdminUserReviewForm(
      data: user,
      onApprove: rec.approve,
      onReject: rec.reject,
      onBlock: rec.block_,
    ),
  );
}

void main() {
  group('Issue 385: AdminUserReviewFormValidators', () {
    test(
      'Issue 385: reason is optional for all actions — null/empty are fine',
      () {
        for (final action in AdminUserReviewAction.values) {
          expect(AdminUserReviewFormValidators.reason(null, action), isNull);
          expect(AdminUserReviewFormValidators.reason('', action), isNull);
          expect(AdminUserReviewFormValidators.reason('   ', action), isNull);
          expect(
            AdminUserReviewFormValidators.reason('looks good', action),
            isNull,
          );
        }
      },
    );

    test('Issue 385: max length is enforced for all actions', () {
      final tooLong = 'x' * (kAdminReviewReasonMaxLength + 1);
      for (final action in AdminUserReviewAction.values) {
        expect(
          AdminUserReviewFormValidators.reason(tooLong, action),
          isNotNull,
        );
        expect(
          AdminUserReviewFormValidators.reason(
            'x' * kAdminReviewReasonMaxLength,
            action,
          ),
          isNull,
        );
      }
    });

    test('Issue 385: canConfirm is true unless reason exceeds the cap', () {
      for (final action in AdminUserReviewAction.values) {
        expect(
          AdminUserReviewFormValidators.canConfirm(action: action, reason: ''),
          isTrue,
        );
        expect(
          AdminUserReviewFormValidators.canConfirm(
            action: action,
            reason: 'x' * kAdminReviewReasonMaxLength,
          ),
          isTrue,
        );
        expect(
          AdminUserReviewFormValidators.canConfirm(
            action: action,
            reason: 'x' * (kAdminReviewReasonMaxLength + 1),
          ),
          isFalse,
        );
      }
    });
  });

  group('Issue 385: AdminUserReviewForm initial state', () {
    testWidgets(
      'Issue 385: shows three action buttons; no reason field or confirm '
      'until one is tapped',
      (tester) async {
        await _setSurface(tester);
        final rec = _Recorder();
        await tester.pumpWidget(_form(user: _user(), rec: rec));
        await tester.pumpAndSettle();

        expect(find.text('Reject'), findsOneWidget);
        expect(find.text('Approve'), findsOneWidget);
        expect(find.text('Block'), findsOneWidget);

        expect(find.text('Asha Verma'), findsOneWidget);
        expect(find.text('Full name'), findsNothing);
        // Issue 503 / 507: DOB and gender render as a single compact h4
        // text line joined by " · ". Old form-style labels are absent.
        expect(find.text('Date of birth'), findsNothing);
        expect(find.text('Gender'), findsNothing);
        expect(find.text('DOB: 14/03/1998 · Female'), findsOneWidget);

        expect(find.text('Reason for Rejection (optional)'), findsNothing);
        expect(find.text('Resolution note (optional)'), findsNothing);
        expect(find.textContaining('Confirm'), findsNothing);
      },
    );

    testWidgets(
      'Issue 385: prior review note renders when present, hidden otherwise',
      (tester) async {
        await _setSurface(tester);
        final rec = _Recorder();
        await tester.pumpWidget(
          _form(
            user: _user(note: 'Please re-upload back side.'),
            rec: rec,
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Prior review note'), findsOneWidget);
        expect(find.text('Please re-upload back side.'), findsOneWidget);
      },
    );

    testWidgets(
      'Issue 385: prior review note is omitted when null',
      (tester) async {
        await _setSurface(tester);
        final rec = _Recorder();
        await tester.pumpWidget(_form(user: _user(), rec: rec));
        await tester.pumpAndSettle();
        expect(find.text('Prior review note'), findsNothing);
      },
    );
  });

  group('Issue 385: selection reveals reason + confirm', () {
    testWidgets(
      'Issue 385: tapping Approve fires onApprove immediately with no '
      'reason field or Confirm step',
      (tester) async {
        await _setSurface(tester);
        final rec = _Recorder();
        await tester.pumpWidget(
          _form(
            user: _user(key: 'asha'),
            rec: rec,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Approve'));
        await tester.pumpAndSettle();

        expect(find.text('Resolution note (optional)'), findsNothing);
        expect(
          find.widgetWithText(ShadButton, 'Confirm Approve'),
          findsNothing,
        );

        expect(rec.calls, hasLength(1));
        expect(rec.calls.single.label, 'approve');
        expect(rec.calls.single.data.userKey, 'asha');
        expect(rec.calls.single.reason, isNull);
      },
    );

    testWidgets(
      'Issue 385 / 507: tapping Reject opens the reason dialog; Confirm '
      'is enabled even with an empty reason',
      (tester) async {
        await _setSurface(tester);
        final rec = _Recorder();
        await tester.pumpWidget(_form(user: _user(), rec: rec));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Reject'));
        await tester.pumpAndSettle();

        // Dialog is up: title and Confirm Reject button are visible.
        expect(find.text('Reject Asha Verma'), findsOneWidget);
        final confirm = find.widgetWithText(ShadButton, 'Confirm Reject');
        expect(confirm, findsOneWidget);
        expect(tester.widget<ShadButton>(confirm).onPressed, isNotNull);
      },
    );

    testWidgets(
      'Issue 385: Confirm Reject with a whitespace-only reason fires onReject '
      'with null',
      (tester) async {
        await _setSurface(tester);
        final rec = _Recorder();
        await tester.pumpWidget(
          _form(
            user: _user(key: 'rohan'),
            rec: rec,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Reject'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(ShadInput), '   \n  ');
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ShadButton, 'Confirm Reject'));
        await tester.pumpAndSettle();

        expect(rec.calls.single.reason, isNull);
      },
    );

    testWidgets(
      'Issue 385: Confirm Reject with an empty reason fires onReject with '
      'null',
      (tester) async {
        await _setSurface(tester);
        final rec = _Recorder();
        await tester.pumpWidget(
          _form(
            user: _user(key: 'rohan'),
            rec: rec,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Reject'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ShadButton, 'Confirm Reject'));
        await tester.pumpAndSettle();

        expect(rec.calls, hasLength(1));
        expect(rec.calls.single.label, 'reject');
        expect(rec.calls.single.data.userKey, 'rohan');
        expect(rec.calls.single.reason, isNull);
      },
    );

    testWidgets(
      'Issue 385 / 507: tapping Block opens the block-reason dialog with '
      'Confirm Block label',
      (tester) async {
        await _setSurface(tester);
        final rec = _Recorder();
        await tester.pumpWidget(_form(user: _user(), rec: rec));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Block'));
        await tester.pumpAndSettle();

        expect(find.text('Block Asha Verma'), findsOneWidget);
        expect(
          find.widgetWithText(ShadButton, 'Confirm Block'),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'Issue 507: tapping Cancel inside the reason dialog dismisses it '
      'without firing any callback',
      (tester) async {
        await _setSurface(tester);
        final rec = _Recorder();
        await tester.pumpWidget(_form(user: _user(), rec: rec));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Reject'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ShadButton, 'Cancel'));
        await tester.pumpAndSettle();

        expect(find.text('Reject Asha Verma'), findsNothing);
        expect(rec.calls, isEmpty);
      },
    );
  });

  group('Issue 385: callback wiring', () {
    testWidgets(
      'Issue 385: tapping Approve fires onApprove with null reason',
      (tester) async {
        await _setSurface(tester);
        final rec = _Recorder();
        await tester.pumpWidget(
          _form(
            user: _user(key: 'asha'),
            rec: rec,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Approve'));
        await tester.pumpAndSettle();

        expect(rec.calls, hasLength(1));
        expect(rec.calls.single.label, 'approve');
        expect(rec.calls.single.data.userKey, 'asha');
        expect(rec.calls.single.reason, isNull);
      },
    );

    testWidgets(
      'Issue 385: Confirm Reject fires onReject with the validated reason',
      (tester) async {
        await _setSurface(tester);
        final rec = _Recorder();
        await tester.pumpWidget(
          _form(
            user: _user(key: 'rohan'),
            rec: rec,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Reject'));
        await tester.pumpAndSettle();
        const reason = 'Please re-upload Aadhaar back side.';
        await tester.enterText(find.byType(ShadInput), reason);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ShadButton, 'Confirm Reject'));
        await tester.pumpAndSettle();

        expect(rec.calls, hasLength(1));
        expect(rec.calls.single.label, 'reject');
        expect(rec.calls.single.data.userKey, 'rohan');
        expect(rec.calls.single.reason, reason);
      },
    );

    testWidgets(
      'Issue 385: Confirm Block fires onBlock with the validated reason',
      (tester) async {
        await _setSurface(tester);
        final rec = _Recorder();
        await tester.pumpWidget(
          _form(
            user: _user(key: 'meera'),
            rec: rec,
          ),
        );
        await tester.pumpAndSettle();

        await tester.tap(find.text('Block'));
        await tester.pumpAndSettle();
        const reason = 'Repeatedly uploaded fraudulent IDs.';
        await tester.enterText(find.byType(ShadInput), reason);
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ShadButton, 'Confirm Block'));
        await tester.pumpAndSettle();

        expect(rec.calls, hasLength(1));
        expect(rec.calls.single.label, 'block');
        expect(rec.calls.single.data.userKey, 'meera');
        expect(rec.calls.single.reason, reason);
      },
    );
  });

  group('Issue 385 / 507: submitting state', () {
    testWidgets(
      'Issue 385 / 507: while the action callback is pending, the action '
      'row buttons are disabled',
      (tester) async {
        await _setSurface(tester);
        final rec = _Recorder()..block();
        await tester.pumpWidget(_form(user: _user(), rec: rec));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Reject'));
        await tester.pumpAndSettle();
        await tester.tap(find.widgetWithText(ShadButton, 'Confirm Reject'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 50));

        // Dialog has popped; action buttons are now disabled while the
        // host onReject future is pending.
        final approve = find.widgetWithText(ShadButton, 'Approve');
        expect(tester.widget<ShadButton>(approve).onPressed, isNull);
        final reject = find.widgetWithText(ShadButton, 'Reject');
        expect(tester.widget<ShadButton>(reject).onPressed, isNull);

        rec.release();
        await tester.pumpAndSettle();

        // Buttons re-enable once the future resolves.
        expect(tester.widget<ShadButton>(approve).onPressed, isNotNull);
      },
    );
  });

  group('Issue 507: dialog-based reason collection', () {
    testWidgets(
      'Issue 507: the page itself never wraps in a SingleChildScrollView — '
      'the reason flow is a modal dialog, so the admin never has to scroll '
      'the underlying surface',
      (tester) async {
        await _setSurface(tester);
        final rec = _Recorder();
        await tester.pumpWidget(_form(user: _user(), rec: rec));
        await tester.pumpAndSettle();

        // Approve idle state: no scroll view in the page.
        expect(find.byType(SingleChildScrollView), findsNothing);

        // After tapping Reject the page still has no scroll view; the
        // reason input is hosted inside a ShadDialog overlay instead.
        await tester.tap(find.text('Reject'));
        await tester.pumpAndSettle();
        expect(find.byType(ShadDialog), findsOneWidget);
      },
    );
  });

  group('Issue 84: documents follow identity verification', () {
    testWidgets('on: the documents grid is shown, empty or not', (
      tester,
    ) async {
      await tester.pumpWidget(_form(user: _user(docs: 0), rec: _Recorder()));
      await tester.pumpAndSettle();

      expect(find.text('No documents on file.'), findsOneWidget);
    });

    testWidgets('off: no documents section, and the review still works', (
      tester,
    ) async {
      final rec = _Recorder();
      await tester.pumpWidget(
        _wrap(
          AdminUserReviewForm(
            data: _user(docs: 0),
            onApprove: rec.approve,
            onReject: rec.reject,
            onBlock: rec.block_,
            showDocuments: false,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No documents on file.'), findsNothing);
      expect(find.textContaining('DOB:'), findsOneWidget);
      expect(find.text('Approve'), findsOneWidget);
    });
  });
}
