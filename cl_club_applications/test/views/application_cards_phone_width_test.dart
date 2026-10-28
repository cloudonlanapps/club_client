// Issue 408: the Library and Labels cards on Club details fit a phone: a
// long library text name wraps in its card's title, and a read line's label
// stands above its value when the card is narrow.
import 'package:cl_club_applications/cl_club_applications.dart';
import 'package:cl_club_applications/src/constants/application_library_strings.dart';
import 'package:cl_club_applications/src/widgets/labels/application_label_card.dart';
import 'package:cl_club_applications/src/widgets/sections/application_section_read.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show SectionEditButton;

import '../support/application_samples.dart';
import '../support/applications_harness.dart';

const Size _phone = Size(360, 2400);

/// Names like the server's seeded clauses, and longer.
final Map<int, ApplicationLibraryText> _seededStyle = {
  1: ApplicationSamples.libraryText(
    id: 1,
    key: 'selection.training_camp',
    name: 'Selection: attend training camp',
    text: const ApplicationText({
      'en':
          'I agree to attend the training camp from {camp_start} to '
          '{camp_end} at {camp_venue} if selected.',
      'mr':
          'निवड झाल्यास मी {camp_start} ते {camp_end} '
          'प्रशिक्षण शिबिरास उपस्थित राहीन.',
    }),
  ),
  2: ApplicationSamples.libraryText(
    id: 2,
    key: 'declaration.championship',
    name: 'Declaration: championship',
    kind: ApplicationClauseKind.declaration,
    heading: const ApplicationText({
      'en': 'Declaration by the player and the parent or guardian',
    }),
  ),
  3: ApplicationSamples.libraryText(
    id: 3,
    name:
        'Terms: medical fitness certificate signed by a registered medical '
        'practitioner',
    kind: ApplicationClauseKind.note,
  ),
};

const ApplicationLabels _labels = ApplicationLabels(
  languages: ['en', 'mr', 'hi'],
  labels: {
    'field.guardian': {
      'en': 'Name of the parent or guardian (for a player under 18)',
    },
    'section.photo': {'en': 'Photo', 'mr': 'फोटो', 'hi': 'फोटो'},
  },
);

Future<void> _pumpLibrary(WidgetTester tester) => pumpApplications(
  tester,
  const SingleChildScrollView(child: ApplicationLibrarySection()),
  master: FakeApplicationsMaster({1: ApplicationSamples.template(id: 1)}),
  library: FakeApplicationLibraryMaster(_seededStyle),
  size: _phone,
);

Finder _textCard(int id) => find.byKey(ValueKey('application.library.$id'));

Future<void> _edit(WidgetTester tester, Finder card) async {
  final pencil = find.descendant(
    of: card,
    matching: find.byType(SectionEditButton),
  );
  await tester.ensureVisible(pencil);
  await tester.pumpAndSettle();
  await tester.tap(pencil);
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 408: the Library and Labels cards at 360 px', () {
    testWidgets('Issue 408: the Library card lists long names without '
        'overflow, each name wrapping beside its pencil', (tester) async {
      await _pumpLibrary(tester);
      expect(tester.takeException(), isNull);
      expect(find.text(ApplicationLibraryStrings.add), findsOneWidget);
      for (final id in _seededStyle.keys) {
        final card = _textCard(id);
        expect(card, findsOneWidget);
        final pencil = find.descendant(
          of: card,
          matching: find.byType(SectionEditButton),
        );
        expect(tester.getTopRight(pencil).dx, lessThanOrEqualTo(360));
      }
      final longName = find.text(_seededStyle[3]!.name);
      expect(tester.getSize(longName).height, greaterThan(40));
    });

    testWidgets('Issue 408: a library text card opens its editor without '
        'overflow', (tester) async {
      await _pumpLibrary(tester);
      await _edit(tester, _textCard(1));
      expect(tester.takeException(), isNull);
      await _edit(tester, _textCard(2));
      expect(tester.takeException(), isNull);
    });

    testWidgets('Issue 408: a read line stacks its label above its value on '
        'a phone, and keeps them side by side on a wide card', (tester) async {
      await _pumpLibrary(tester);
      final card = _textCard(1);
      final label = find.descendant(
        of: card,
        matching: find.text(ApplicationLibraryStrings.usedFor),
      );
      final value = find.descendant(of: card, matching: find.text('Selection'));
      expect(
        tester.getTopLeft(value).dy,
        greaterThanOrEqualTo(tester.getBottomLeft(label).dy),
      );
      expect(tester.getTopLeft(value).dx, tester.getTopLeft(label).dx);

      await tester.pumpWidget(const SizedBox.shrink());
      await pumpApplications(
        tester,
        const SingleChildScrollView(child: ApplicationLibrarySection()),
        master: FakeApplicationsMaster({1: ApplicationSamples.template(id: 1)}),
        library: FakeApplicationLibraryMaster(_seededStyle),
      );
      final wideLabel = find.descendant(
        of: _textCard(1),
        matching: find.text(ApplicationLibraryStrings.usedFor),
      );
      final wideValue = find.descendant(
        of: _textCard(1),
        matching: find.text('Selection'),
      );
      expect(
        tester.getCenter(wideValue).dy,
        closeTo(tester.getCenter(wideLabel).dy, 4),
      );
      expect(
        tester.getTopLeft(wideValue).dx,
        greaterThan(tester.getTopRight(wideLabel).dx),
      );
      expect(find.byType(ApplicationSectionRead), findsWidgets);
    });

    testWidgets('Issue 408: the Labels card shows a long label without '
        'overflow, in read and edit mode', (tester) async {
      await pumpApplications(
        tester,
        const SingleChildScrollView(child: ApplicationLabelsSection()),
        master: FakeApplicationsMaster({1: ApplicationSamples.template(id: 1)}),
        labels: FakeApplicationLabels(_labels),
        size: _phone,
      );
      expect(tester.takeException(), isNull);
      final card = find.byKey(ApplicationLabelCard.cardKey('field.guardian'));
      expect(card, findsOneWidget);
      await _edit(tester, card);
      expect(tester.takeException(), isNull);
      expect(find.byType(ShadInput), findsWidgets);
    });
  });
}
