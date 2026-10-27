// Issue 396: the Labels card on Club details: each club label with its text
// in every club language, a blank one Required in the error colour, edited
// in place; a refusal for a language the club lacks shows inline.
import 'package:cl_club_applications/cl_club_applications.dart';
import 'package:cl_club_applications/src/constants/application_label_strings.dart';
import 'package:cl_club_applications/src/constants/application_view_strings.dart';
import 'package:cl_club_applications/src/widgets/labels/application_label_card.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show SectionEditButton;

import '../support/application_samples.dart';
import '../support/applications_harness.dart';

const ApplicationLabels _labels = ApplicationLabels(
  languages: ['en', 'mr', 'hi'],
  labels: {
    'field.full_name': {'en': 'Full name', 'mr': 'पूर्ण नाव'},
    'section.photo': {'en': 'Photo', 'mr': 'फोटो', 'hi': 'फोटो'},
  },
);

Future<FakeApplicationLabels> _pump(
  WidgetTester tester, {
  bool enabled = true,
}) async {
  final labels = FakeApplicationLabels(_labels);
  await pumpApplications(
    tester,
    const SingleChildScrollView(child: ApplicationLabelsSection()),
    master: FakeApplicationsMaster({1: ApplicationSamples.template(id: 1)}),
    labels: labels,
    enabled: enabled,
  );
  return labels;
}

Finder _card(String key) => find.byKey(ApplicationLabelCard.cardKey(key));

Finder _in(Finder card, Finder matching) =>
    find.descendant(of: card, matching: matching);

Future<void> _tap(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pumpAndSettle();
  await tester.tap(finder);
  await tester.pumpAndSettle();
}

Future<void> _edit(WidgetTester tester, String key) =>
    _tap(tester, _in(_card(key), find.byType(SectionEditButton)));

Finder _input(String key, int index) =>
    _in(_card(key), find.byType(EditableText)).at(index);

Future<void> _save(WidgetTester tester, String key) => _tap(
  tester,
  _in(_card(key), find.widgetWithText(ShadButton, ApplicationViewStrings.save)),
);

void main() {
  group('Issue 396: the Labels card', () {
    testWidgets('Issue 396: renders nothing while applications are off', (
      tester,
    ) async {
      await _pump(tester, enabled: false);
      expect(find.byKey(ApplicationLabelsSection.cardKey), findsNothing);
    });

    testWidgets('Issue 396: lists each label by its English text with its '
        'text in every club language; a blank one is Required in the error '
        'colour', (tester) async {
      await _pump(tester);

      expect(find.text(ApplicationLabelStrings.title), findsOneWidget);
      expect(find.text(ApplicationLabelStrings.intro), findsOneWidget);
      final name = _card('field.full_name');
      expect(_in(name, find.text('Full name')), findsWidgets);
      expect(_in(name, find.text('पूर्ण नाव')), findsOneWidget);
      expect(_in(name, find.text('Hindi')), findsOneWidget);
      final required = tester.widget<Text>(
        _in(name, find.text(ApplicationViewStrings.required)),
      );
      final error = ShadTheme.of(
        tester.element(name),
      ).colorScheme.destructive;
      expect(required.style!.color, error);
      expect(
        _in(_card('section.photo'), find.text(ApplicationViewStrings.required)),
        findsNothing,
      );
    });

    testWidgets('Issue 396: a translation is written in place and saved, '
        'the others kept', (tester) async {
      final labels = await _pump(tester);
      await _edit(tester, 'field.full_name');
      await tester.enterText(_input('field.full_name', 2), ' पूरा नाम ');
      await tester.pump();
      await _save(tester, 'field.full_name');

      expect(labels.calls, [
        'update field.full_name {en: Full name, mr: पूर्ण नाव, hi: पूरा नाम}',
      ]);
      expect(find.text(ApplicationLabelStrings.saved), findsOneWidget);
      expect(
        _in(
          _card('field.full_name'),
          find.text(ApplicationViewStrings.required),
        ),
        findsNothing,
      );
      expect(_in(_card('field.full_name'), find.text('पूरा नाम')), findsOne);
    });

    testWidgets('Issue 396: a language the club does not offer is refused '
        'inline and the editor stays open', (tester) async {
      final labels = await _pump(tester);
      labels.failWith = const ApplicationLanguageNotOfferedException(
        message: 'not offered',
        languages: ['hi'],
      );
      await _edit(tester, 'field.full_name');
      await tester.enterText(_input('field.full_name', 2), 'पूरा नाम');
      await tester.pump();
      await _save(tester, 'field.full_name');

      expect(labels.calls, hasLength(1));
      expect(
        _in(
          _card('field.full_name'),
          find.text(ApplicationViewStrings.languageNotOffered(['Hindi'])),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Issue 396: an unchanged Save sends nothing', (tester) async {
      final labels = await _pump(tester);
      await _edit(tester, 'section.photo');
      await _save(tester, 'section.photo');
      expect(labels.calls, isEmpty);
    });
  });
}
