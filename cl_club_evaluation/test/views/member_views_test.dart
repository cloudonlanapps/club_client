import 'dart:typed_data';

import 'package:cl_club_evaluation/cl_club_evaluation.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show EvaluationMemberMedia;
import 'package:club_sdk_2/club_sdk_2.dart' as sdk;
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;

import '../support/evaluation_scope.dart';

sdk.EvaluationMemberView _review(
  int id, {
  required DateTime publishedAtUtc,
  String name = 'Skating',
  int? eventId,
}) => sdk.EvaluationMemberView(
  id: id,
  createdFor: 'ana',
  createdBy: 'coach',
  status: sdk.EvaluationStatus.published,
  publishedAtUtc: publishedAtUtc,
  eventId: eventId,
  template: sdk.EvaluationMemberTemplate(
    id: 1,
    name: name,
    layout: const [
      sdk.EvaluationLayoutSection('Skating', [11]),
    ],
    items: const [
      sdk.EvaluationYesNoItem(
        id: 11,
        question: 'Stops on both sides',
        allowEvidence: true,
      ),
    ],
  ),
  answers: const [
    sdk.EvaluationAnswer(itemId: 11, valueNum: 1, coachNote: 'Clean stops'),
  ],
);

final List<sdk.EvaluationMemberView> _reviews = [
  _review(1, publishedAtUtc: DateTime.utc(2026, 3), name: 'Spring check'),
  _review(
    2,
    publishedAtUtc: DateTime.utc(2026, 6),
    name: 'Summer camp review',
    eventId: 9,
  ),
];

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

void main() {
  final ana = viewer('ana');

  group('Issue 173: MyReviewsView', () {
    testWidgets('Issue 173: with no reviews shows the empty state', (
      tester,
    ) async {
      await tester.pumpWidget(
        evaluationScope(
          child: MyReviewsView(currentUser: ana, onOpen: (_) {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('No reviews yet.'), findsOneWidget);
    });

    testWidgets('Issue 173: lists the reviews newest first, by event or '
        'General, with the coach', (tester) async {
      final opened = <int>[];
      await tester.pumpWidget(
        evaluationScope(
          memberViews: _reviews,
          users: {'coach': userInfo('coach', 'Coach Kim', coach: true)},
          events: {9: event(9, 'Summer camp')},
          child: MyReviewsView(currentUser: ana, onOpen: opened.add),
        ),
      );
      await tester.pumpAndSettle();
      final newer = tester.getTopLeft(find.text('Summer camp review'));
      final older = tester.getTopLeft(find.text('Spring check'));
      expect(newer.dy, lessThan(older.dy));
      expect(find.textContaining('Summer camp ·'), findsOneWidget);
      expect(find.textContaining('General ·'), findsOneWidget);
      expect(find.textContaining('Coach Kim'), findsNWidgets(2));
      await tester.tap(find.text('Spring check'));
      expect(opened, [1]);
    });

    testWidgets('Issue 173: renders nothing with evaluations off', (
      tester,
    ) async {
      await tester.pumpWidget(
        evaluationScope(
          on: false,
          memberViews: _reviews,
          child: MyReviewsView(currentUser: ana, onOpen: (_) {}),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Spring check'), findsNothing);
      expect(find.text('No reviews yet.'), findsNothing);
    });
  });

  group('Issue 173: EvaluationReadView', () {
    testWidgets('Issue 173: shows the answers read-only and downloads the '
        'stored member copy from the download icon', (tester) async {
      final opened = <Uint8List>[];
      await tallSurface(tester);
      await tester.pumpWidget(
        evaluationScope(
          memberViews: _reviews,
          memberMedia: EvaluationMemberMedia(
            memberCopy: _copy,
            evidence: const {},
          ),
          child: EvaluationReadView(
            currentUser: ana,
            username: 'ana',
            evaluationId: 1,
            onBack: () {},
            onOpenPdfBytes: opened.add,
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Spring check'), findsOneWidget);
      expect(find.text('Stops on both sides'), findsOneWidget);
      expect(find.text('Clean stops'), findsOneWidget);
      await tester.tap(find.byIcon(LucideIcons.download));
      await tester.pumpAndSettle();
      expect(opened.single, fixedPdfBytes);
    });

    testWidgets('Issue 173: a coach reads a member review; no copy, no '
        'download', (tester) async {
      await tallSurface(tester);
      await tester.pumpWidget(
        evaluationScope(
          memberViews: _reviews,
          child: EvaluationReadView(
            currentUser: viewer('kim', coach: true),
            username: 'ana',
            evaluationId: 2,
            onBack: () {},
            onOpenPdfBytes: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Summer camp review'), findsOneWidget);
      expect(find.byIcon(LucideIcons.download), findsNothing);
    });

    testWidgets('Issue 173: an unknown review says it is not available', (
      tester,
    ) async {
      await tester.pumpWidget(
        evaluationScope(
          child: EvaluationReadView(
            currentUser: ana,
            username: 'ana',
            evaluationId: 5,
            onBack: () {},
            onOpenPdfBytes: (_) {},
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('This review is not available.'), findsOneWidget);
    });
  });
}
