import 'dart:typed_data';

import 'package:cl_club_evaluation/cl_club_evaluation.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show EvaluationMemberMedia;
import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show
        EvaluationPeriodForm,
        EvaluationPeriodFormState,
        EvaluationStartFormFields,
        StampBadge;

import '../support/evaluation_scope.dart';

/// A public rating section, then a closing run: a public and a private
/// Q & A.
final sdk.EvaluationTemplate _template = template(
  1,
  name: 'Season review',
  layout: const [
    sdk.EvaluationLayoutSection('Skating', [11]),
    sdk.EvaluationLayoutItem(12),
    sdk.EvaluationLayoutItem(13),
  ],
  items: const [
    sdk.EvaluationYesNoItem(id: 11, question: 'Stops'),
    sdk.EvaluationQaItem(id: 12, question: 'Summary'),
    sdk.EvaluationQaItem(
      id: 13,
      question: "Coach's private note",
      isPrivate: true,
    ),
  ],
);

final sdk.MediaLink _copy = sdk.MediaLink(
  tag: sdk.EvaluationMediaTags.memberCopy,
  media: const sdk.MediaRef(
    uuid: 'copy-uuid',
    mimeType: 'application/pdf',
    filename: 'review.pdf',
  ),
  createdAtUtc: t0,
  updatedAtUtc: t0,
);

const sdk.ServerException _duplicate = sdk.ServerException(
  statusCode: 422,
  code: 'DUPLICATE_EVALUATION',
  message: 'raw duplicate',
);

class _Host {
  int back = 0;
  final List<Uint8List> pdfs = [];
  late StubEvaluations stub;

  Future<void> pump(
    WidgetTester tester, {
    sdk.EvaluationStatus status = sdk.EvaluationStatus.draft,
    int? eventId,
    DateTime? periodStartUtc,
    DateTime? periodEndUtc,
    String? owner,
    EvaluationMemberMedia? media,
    Exception? periodError,
    Map<int, sdk.Event>? events,
    Map<int, Map<String, sdk.EnrollmentStatus>> enrollments = const {},
  }) async {
    stub = StubEvaluations({
      5: staffView(
        5,
        status: status,
        eventId: eventId,
        periodStartUtc: periodStartUtc,
        periodEndUtc: periodEndUtc,
        owner: owner,
      ),
    }, periodError: periodError);
    await tallSurface(tester);
    await tester.pumpWidget(
      evaluationScope(
        templates: StubTemplates({1: _template}),
        evaluations: stub,
        ownerMedia: media,
        users: {
          'ana': userInfo('ana', 'Cara Mendes'),
          'coach': userInfo('coach', 'Coach Kim', coach: true),
          'lee': userInfo('lee', 'Coach Lee', coach: true),
        },
        events: events ?? {9: event(9, 'Summer camp')},
        enrollments: enrollments,
        child: EvaluationEditView(
          currentUser: viewer('coach', coach: true),
          evaluationId: 5,
          onBack: () => back++,
          onDeleted: () {},
          onTransferred: () {},
          onOpenPdfBytes: pdfs.add,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }
}

/// The status stamp is the website's [StampBadge] reading [label], in the
/// theme's monochrome colours.
void _expectStamp(WidgetTester tester, String label) {
  final stamp = find.byType(StampBadge);
  expect(stamp, findsOneWidget);
  expect(
    find.descendant(of: stamp, matching: find.text(label)),
    findsOneWidget,
  );
  final colors = ShadTheme.of(tester.element(stamp)).colorScheme;
  final badge = tester.widget<StampBadge>(stamp);
  expect(badge.background, colors.muted);
  expect(badge.foreground, colors.foreground);
}

/// Summer camp (the review's, no longer coached), Autumn camp (coached,
/// the member enrolled), Spring camp (coached, the member withdrawn) and
/// Winter league (coached, the member not on it).
final Map<int, sdk.Event> _events = {
  9: event(9, 'Summer camp'),
  8: event(8, 'Autumn camp', coaches: ['coach']),
  7: event(7, 'Spring camp', coaches: ['coach']),
  6: event(6, 'Winter league', coaches: ['coach']),
};

const Map<int, Map<String, sdk.EnrollmentStatus>> _rolls = {
  8: {'ana': sdk.EnrollmentStatus.accepted},
  7: {'ana': sdk.EnrollmentStatus.withdrawn},
};

/// Opens the select showing [showing] and picks [option].
Future<void> _choose(WidgetTester tester, String showing, String option) async {
  await tester.tap(find.text(showing).last);
  await tester.pumpAndSettle();
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

Finder _inCard(String card, String text) => find.descendant(
  of: find.ancestor(of: find.text(card), matching: find.byType(ShadCard)).first,
  matching: find.text(text),
);

double _opacity(WidgetTester tester, String text) => tester
    .widgetList<Opacity>(
      find.ancestor(of: find.text(text), matching: find.byType(Opacity)),
    )
    .fold(1, (o, w) => o * w.opacity);

void main() {
  group('Issue 173: the owner editor, per the UI remarks', () {
    testWidgets('Issue 173: Back leaves at once, without asking', (
      tester,
    ) async {
      final host = _Host();
      await host.pump(tester);
      await tester.tap(find.text('Back'));
      await tester.pumpAndSettle();
      expect(host.back, 1);
      expect(find.byType(ShadDialog), findsNothing);
    });

    testWidgets('Issue 173: the head shows the member over the review '
        'title, without event or status; a draft has no stamp', (
      tester,
    ) async {
      final host = _Host();
      await host.pump(tester, eventId: 9);
      final head = find.ancestor(
        of: find.text('Cara Mendes'),
        matching: find.byType(ShadCard),
      );
      expect(
        find.descendant(of: head, matching: find.text('Season review')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: head, matching: find.text('Summer camp')),
        findsNothing,
      );
      expect(find.byType(StampBadge), findsNothing);
    });

    testWidgets('Issue 173: a finalized review is stamped Ready', (
      tester,
    ) async {
      final host = _Host();
      await host.pump(tester, status: sdk.EvaluationStatus.saved);
      _expectStamp(tester, 'READY');
    });

    testWidgets('Issue 173: a published review is stamped Published', (
      tester,
    ) async {
      final host = _Host();
      await host.pump(tester, status: sdk.EvaluationStatus.published);
      _expectStamp(tester, 'PUBLISHED');
    });

    testWidgets('Issue 173: the Review Period section states the event and '
        'the period, and a draft edits it', (tester) async {
      final host = _Host();
      await host.pump(
        tester,
        eventId: 9,
        periodStartUtc: DateTime.utc(2026, 5),
        periodEndUtc: DateTime.utc(2026, 5, 31),
      );
      expect(_inCard('Review Period', 'Summer camp'), findsOneWidget);
      expect(
        _inCard('Review Period', '1 May 2026 to 31 May 2026'),
        findsOneWidget,
      );
      expect(find.byIcon(LucideIcons.pencil), findsOneWidget);
    });

    testWidgets('Issue 173: a general review leaves the event out; a '
        'finalized one has no pencil', (tester) async {
      final host = _Host();
      await host.pump(
        tester,
        status: sdk.EvaluationStatus.saved,
        periodStartUtc: DateTime.utc(2026, 5),
        periodEndUtc: DateTime.utc(2026, 5, 31),
      );
      expect(find.text('General'), findsNothing);
      expect(find.text('Event'), findsNothing);
      expect(find.byIcon(LucideIcons.pencil), findsNothing);
    });

    testWidgets('Issue 173: DUPLICATE_EVALUATION shows inline in the period '
        'editor, which stays open', (tester) async {
      final host = _Host();
      await host.pump(
        tester,
        periodStartUtc: DateTime.utc(2026, 5),
        periodEndUtc: DateTime.utc(2026, 5, 31),
        periodError: _duplicate,
      );
      await tester.tap(find.byIcon(LucideIcons.pencil));
      await tester.pumpAndSettle();
      final form = tester.state<EvaluationPeriodFormState>(
        find.byType(EvaluationPeriodForm),
      );
      form.formKey.currentState!.fields[EvaluationStartFormFields.periodEndId]!
          .didChange(DateTime(2026, 5, 30));
      await tester.pump();
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      final start = DateTime.utc(2026, 5);
      final end = DateTime.utc(2026, 5, 30);
      expect(host.stub.calls, ['update 5 event=- start=$start end=$end']);
      expect(
        find.text(
          'A review of this member with this template and period already '
          'exists.',
        ),
        findsOneWidget,
      );
      expect(find.text('raw duplicate'), findsNothing);
      expect(find.byType(EvaluationPeriodForm), findsOneWidget);
    });

    testWidgets('Issue 173: the Review Period pencil edits the event: '
        "General, the coach's events the member is enrolled in, and the "
        'current one', (tester) async {
      final host = _Host();
      await host.pump(tester, eventId: 9, events: _events, enrollments: _rolls);
      await tester.tap(find.byIcon(LucideIcons.pencil));
      await tester.pumpAndSettle();
      await _choose(tester, 'Summer camp', 'General');
      expect(find.text('Spring camp'), findsNothing);
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(host.stub.calls, ['update 5 event=null start=- end=-']);
      expect(find.byType(EvaluationPeriodForm), findsNothing);
    });

    testWidgets('Issue 173: the event choices exclude events the member is '
        'not enrolled in or the coach does not coach', (tester) async {
      final host = _Host();
      await host.pump(tester, events: _events, enrollments: _rolls);
      await tester.tap(find.byIcon(LucideIcons.pencil));
      await tester.pumpAndSettle();
      await tester.tap(find.text('General').last);
      await tester.pumpAndSettle();
      expect(find.text('Autumn camp'), findsOneWidget);
      expect(find.text('Spring camp'), findsNothing);
      expect(find.text('Winter league'), findsNothing);
      expect(find.text('Summer camp'), findsNothing);
    });

    testWidgets('Issue 173: NOT_ELIGIBLE shows inline in the Review Period '
        'editor, which stays open', (tester) async {
      final host = _Host();
      await host.pump(
        tester,
        events: _events,
        enrollments: _rolls,
        periodError: const sdk.ServerException(
          statusCode: 422,
          code: sdk.SdkErrorCode.notEligible,
          message: 'raw not eligible',
        ),
      );
      await tester.tap(find.byIcon(LucideIcons.pencil));
      await tester.pumpAndSettle();
      await _choose(tester, 'General', 'Autumn camp');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();
      expect(host.stub.calls, ['update 5 event=8 start=- end=-']);
      expect(
        find.text('The member is not eligible for this event and period.'),
        findsOneWidget,
      );
      expect(find.text('raw not eligible'), findsNothing);
      expect(find.byType(EvaluationPeriodForm), findsOneWidget);
    });

    testWidgets('Issue 173: Review Management sits before Review Info; a '
        'draft offers Finalize and Delete only', (tester) async {
      final host = _Host();
      await host.pump(tester);
      final management = tester.getTopLeft(find.text('Review Management'));
      final info = tester.getTopLeft(find.text('Review Info'));
      expect(management.dy, lessThan(info.dy));
      expect(_inCard('Review Management', 'Finalize'), findsOneWidget);
      expect(_inCard('Review Management', 'Delete'), findsOneWidget);
      expect(find.text('Transfer'), findsNothing);
      expect(find.text('Preview PDF'), findsNothing);
    });

    testWidgets('Issue 173: finalized offers Publish, Revert to draft and '
        'Transfer', (tester) async {
      final host = _Host();
      await host.pump(tester, status: sdk.EvaluationStatus.saved);
      for (final label in ['Publish', 'Revert to draft', 'Transfer']) {
        expect(_inCard('Review Management', label), findsOneWidget);
      }
      expect(find.text('Delete'), findsNothing);
    });

    testWidgets('Issue 173: Review Info shows who, when, status and '
        'template', (tester) async {
      final host = _Host();
      await host.pump(
        tester,
        status: sdk.EvaluationStatus.published,
        owner: 'lee',
      );
      for (final text in [
        'Created by',
        'Coach Kim',
        'Owner',
        'Coach Lee',
        'Created',
        'Updated',
        'Published',
        'Status',
        'Template',
      ]) {
        expect(_inCard('Review Info', text), findsWidgets, reason: text);
      }
      expect(_inCard('Review Info', 'Season review'), findsOneWidget);
    });

    testWidgets('Issue 173: a published review offers Unpublish only and '
        'downloads the member copy from the top right', (tester) async {
      final host = _Host();
      await host.pump(
        tester,
        status: sdk.EvaluationStatus.published,
        media: EvaluationMemberMedia(memberCopy: _copy, evidence: const {}),
      );
      expect(_inCard('Review Management', 'Unpublish'), findsOneWidget);
      for (final label in ['Publish', 'Revert to draft', 'Transfer']) {
        expect(find.text(label), findsNothing, reason: label);
      }
      await tester.tap(find.byIcon(LucideIcons.download));
      await tester.pumpAndSettle();
      expect(host.pdfs.single, fixedPdfBytes);
    });

    testWidgets('Issue 173: no download before publication', (tester) async {
      final host = _Host();
      await host.pump(
        tester,
        status: sdk.EvaluationStatus.saved,
        media: EvaluationMemberMedia(memberCopy: _copy, evidence: const {}),
      );
      expect(find.byIcon(LucideIcons.download), findsNothing);
    });

    testWidgets('Issue 173: the draft editor has no Coach view / Member '
        'view toggle and shows private items normally', (tester) async {
      final host = _Host();
      await host.pump(tester);
      expect(find.text('Coach view'), findsNothing);
      expect(find.text('Member view'), findsNothing);
      expect(_opacity(tester, "Coach's private note"), 1);
    });

    testWidgets('Issue 173: a finalized review greys its private items', (
      tester,
    ) async {
      final host = _Host();
      await host.pump(tester, status: sdk.EvaluationStatus.saved);
      expect(_opacity(tester, "Coach's private note"), lessThan(1));
      expect(_opacity(tester, 'Summary'), 1);
    });

    testWidgets('Issue 173: the closing Q & As share one untitled card '
        'after the sections', (tester) async {
      final host = _Host();
      await host.pump(tester);
      expect(find.text('Closing remarks'), findsNothing);
      expect(_inCard('Summary', "Coach's private note"), findsOneWidget);
      expect(_inCard('Summary', 'Skating'), findsNothing);
      expect(_inCard('Summary', 'Stops'), findsNothing);
      final card = find
          .ancestor(of: find.text('Summary'), matching: find.byType(ShadCard))
          .first;
      expect(tester.widget<ShadCard>(card).title, isNull);
      expect(
        tester.getTopLeft(find.text('Skating')).dy,
        lessThan(tester.getTopLeft(find.text('Summary')).dy),
      );
    });
  });
}
