import 'dart:typed_data';

import 'package:cl_club_evaluation/cl_club_evaluation.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show EvaluationMemberMedia;
import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/evaluation_scope.dart';

sdk.EvaluationMemberView _review({
  int? eventId,
  DateTime? periodStartUtc,
  DateTime? periodEndUtc,
}) => sdk.EvaluationMemberView(
  id: 1,
  createdFor: 'ana',
  createdBy: 'coach',
  status: sdk.EvaluationStatus.published,
  publishedAtUtc: t0,
  eventId: eventId,
  periodStartUtc: periodStartUtc,
  periodEndUtc: periodEndUtc,
  template: const sdk.EvaluationMemberTemplate(
    id: 1,
    name: 'Season review',
    layout: [
      sdk.EvaluationLayoutSection('Skating', [11]),
      sdk.EvaluationLayoutItem(12),
    ],
    items: [
      sdk.EvaluationYesNoItem(id: 11, question: 'Stops'),
      sdk.EvaluationQaItem(id: 12, question: 'Summary'),
    ],
  ),
  answers: const [sdk.EvaluationAnswer(itemId: 12, valueText: 'Strong')],
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

Future<List<Uint8List>> _pump(
  WidgetTester tester,
  sdk.EvaluationMemberView review, {
  EvaluationMemberMedia? media,
}) async {
  final opened = <Uint8List>[];
  await tallSurface(tester);
  await tester.pumpWidget(
    evaluationScope(
      memberViews: [review],
      memberMedia: media,
      users: {'coach': userInfo('coach', 'Coach Kim', coach: true)},
      events: {9: event(9, 'Summer camp')},
      child: EvaluationReadView(
        currentUser: viewer('ana'),
        username: 'ana',
        evaluationId: 1,
        onBack: () {},
        onOpenPdfBytes: opened.add,
      ),
    ),
  );
  await tester.pumpAndSettle();
  return opened;
}

void main() {
  group('Issue 173: the member view, per the UI remarks', () {
    testWidgets('Issue 173: the title is a plain page title, with no '
        'General, published date or coach', (tester) async {
      await _pump(tester, _review());
      final title = find.text('Season review');
      expect(title, findsOneWidget);
      expect(
        find.ancestor(of: title, matching: find.byType(ShadCard)),
        findsNothing,
      );
      expect(find.text('General'), findsNothing);
      expect(find.textContaining('Published'), findsNothing);
      expect(find.textContaining('Coach Kim'), findsNothing);
    });

    testWidgets('Issue 173: no Open PDF; the download icon at the top '
        'right opens the member copy', (tester) async {
      final opened = await _pump(
        tester,
        _review(),
        media: EvaluationMemberMedia(memberCopy: _copy, evidence: const {}),
      );
      expect(find.text('Open PDF'), findsNothing);
      final icon = find.byIcon(LucideIcons.download);
      expect(
        tester.getTopLeft(icon).dy,
        lessThan(tester.getTopLeft(find.text('Skating')).dy),
      );
      expect(
        tester.getTopLeft(icon).dx,
        greaterThan(tester.getTopRight(find.text('Season review')).dx),
      );
      await tester.tap(icon);
      await tester.pumpAndSettle();
      expect(opened.single, fixedPdfBytes);
    });

    testWidgets('Issue 173: the Review Period section states the event and '
        'period, with no pencil', (tester) async {
      await _pump(
        tester,
        _review(
          eventId: 9,
          periodStartUtc: DateTime.utc(2026, 5),
          periodEndUtc: DateTime.utc(2026, 5, 31),
        ),
      );
      expect(find.text('Review Period'), findsWidgets);
      expect(find.text('Summer camp'), findsOneWidget);
      expect(find.text('1 May 2026 to 31 May 2026'), findsOneWidget);
      expect(find.byIcon(LucideIcons.pencil), findsNothing);
    });

    testWidgets('Issue 173: a general review states only the period', (
      tester,
    ) async {
      await _pump(
        tester,
        _review(
          periodStartUtc: DateTime.utc(2026, 5),
          periodEndUtc: DateTime.utc(2026, 5, 31),
        ),
      );
      expect(find.text('Event'), findsNothing);
      expect(find.text('1 May 2026 to 31 May 2026'), findsOneWidget);
    });

    testWidgets('Issue 173: the section is left out with neither an event '
        'nor a period', (tester) async {
      await _pump(tester, _review());
      expect(find.text('Review Period'), findsNothing);
    });

    testWidgets('Issue 173: the closing Q & A shows untitled, in its own '
        'card after the sections', (tester) async {
      await _pump(tester, _review());
      expect(find.text('Closing remarks'), findsNothing);
      final card = find
          .ancestor(of: find.text('Summary'), matching: find.byType(ShadCard))
          .first;
      expect(
        find.descendant(of: card, matching: find.text('Strong')),
        findsOneWidget,
      );
      expect(
        find.descendant(of: card, matching: find.text('Skating')),
        findsNothing,
      );
      expect(tester.widget<ShadCard>(card).title, isNull);
      expect(
        tester.getTopLeft(find.text('Skating')).dy,
        lessThan(tester.getTopLeft(find.text('Summary')).dy),
      );
    });
  });
}
