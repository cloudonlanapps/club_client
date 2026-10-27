import 'dart:convert';
import 'dart:typed_data';

import 'package:cl_club_applications/cl_club_applications.dart';
import 'package:cl_club_applications/src/constants/application_view_strings.dart';
import 'package:cl_club_applications/src/models/application_template_file.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/application_samples.dart';
import '../support/applications_harness.dart';

Map<int, ApplicationTemplate> _all() => {
  1: ApplicationSamples.template(id: 1),
  2: ApplicationSamples.template(
    id: 2,
    status: ApplicationStatus.published,
    content: ApplicationSamples.content.copyWith(
      title: () => const ApplicationText({'en': 'Season 2026'}),
    ),
  ),
  3: ApplicationSamples.template(
    id: 3,
    status: ApplicationStatus.saved,
    layout: const ApplicationLayout(
      name: 'one page',
      spreadWithGuardian: 1,
      spreadWithoutGuardian: 2,
    ),
  ),
};

Future<void> _pump(
  WidgetTester tester, {
  required FakeApplicationsMaster master,
  bool enabled = true,
  ValueChanged<int>? onOpen,
  Future<Uint8List?> Function()? onPickJsonFile,
}) => pumpApplications(
  tester,
  ApplicationsView(
    currentUser: applicationsUser(admin: true),
    onOpen: onOpen ?? (_) {},
    onPickJsonFile: onPickJsonFile ?? () async => null,
  ),
  master: master,
  enabled: enabled,
);

void main() {
  group('Issue 321: an admin’s Applications page', () {
    testWidgets('Issue 380: renders nothing while applications are off', (
      tester,
    ) async {
      await _pump(
        tester,
        master: FakeApplicationsMaster(_all()),
        enabled: false,
      );
      expect(find.text(ApplicationViewStrings.applications), findsNothing);
    });

    testWidgets('Issue 321: lists every template with its state and offers '
        'Create', (tester) async {
      await _pump(tester, master: FakeApplicationsMaster(_all()));

      expect(find.text('Season 2026'), findsOneWidget);
      expect(find.text('Trial'), findsNWidgets(2));
      expect(find.text('Draft'), findsOneWidget);
      expect(find.text('Published'), findsOneWidget);
      expect(find.text('Saved · one page'), findsOneWidget);
      expect(
        find.widgetWithText(ShadButton, ApplicationViewStrings.create),
        findsOneWidget,
      );
    });

    testWidgets('Issue 399: lists the templates only, with no Library', (
      tester,
    ) async {
      await _pump(tester, master: FakeApplicationsMaster(_all()));
      expect(find.text('Season 2026'), findsOneWidget);
      expect(find.byKey(const ValueKey('application.library')), findsNothing);
      expect(find.text('Add text'), findsNothing);
    });

    testWidgets('Issue 321: Duplicate copies the template and opens the copy', (
      tester,
    ) async {
      final master = FakeApplicationsMaster(_all());
      int? opened;
      await _pump(
        tester,
        master: master,
        onOpen: (id) => opened = id,
      );

      await tester.tap(find.text(ApplicationViewStrings.duplicate).first);
      await tester.pumpAndSettle();
      expect(master.calls.single, startsWith('duplicate '));
      expect(opened, 91);
    });

    testWidgets('Issue 321: Create makes a draft from the title and opens it', (
      tester,
    ) async {
      final master = FakeApplicationsMaster(_all());
      int? opened;
      await _pump(
        tester,
        master: master,
        onOpen: (id) => opened = id,
      );

      await tester.tap(
        find.widgetWithText(ShadButton, ApplicationViewStrings.create),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).first, 'Camp 2027');
      await tester.tap(
        find.widgetWithText(ShadButton, ApplicationViewStrings.save),
      );
      await tester.pumpAndSettle();

      expect(master.calls, ['create {en: Camp 2027}']);
      expect(opened, 90);
    });
  });

  group('Issue 396: a language the club does not offer', () {
    const notOffered = ApplicationLanguageNotOfferedException(
      message: 'raw server words',
      languages: ['hi'],
    );

    testWidgets('Issue 396: Create refused for it says so in the dialog, '
        'which stays open', (tester) async {
      final master = FakeApplicationsMaster(_all())..failWith = notOffered;
      int? opened;
      await _pump(tester, master: master, onOpen: (id) => opened = id);

      await tester.tap(
        find.widgetWithText(ShadButton, ApplicationViewStrings.create),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(EditableText).first, 'Camp 2027');
      await tester.tap(
        find.widgetWithText(ShadButton, ApplicationViewStrings.save),
      );
      await tester.pumpAndSettle();

      expect(master.calls, hasLength(1));
      expect(find.byType(ShadDialog), findsOneWidget);
      expect(
        find.text(ApplicationViewStrings.languageNotOffered(['Hindi'])),
        findsOneWidget,
      );
      expect(opened, isNull);
    });

    testWidgets('Issue 396: Import refused for it names the language', (
      tester,
    ) async {
      final master = FakeApplicationsMaster(_all())..failWith = notOffered;
      int? opened;
      await _pump(
        tester,
        master: master,
        onOpen: (id) => opened = id,
        onPickJsonFile: () async => utf8.encode(
          ApplicationTemplateFile.encode(
            ApplicationSamples.template(
              id: 2,
              status: ApplicationStatus.published,
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(const ValueKey('application.importJson')));
      await tester.pumpAndSettle();
      expect(
        find.text(ApplicationViewStrings.languageNotOffered(['Hindi'])),
        findsOneWidget,
      );
      expect(find.textContaining('raw server words'), findsNothing);
      expect(opened, isNull);
    });
  });

  group('Issue 400: Import JSON', () {
    final import = find.byKey(const ValueKey('application.importJson'));

    /// An exported file of a published template of the samples.
    Uint8List exported() => utf8.encode(
      ApplicationTemplateFile.encode(
        ApplicationSamples.template(id: 2, status: ApplicationStatus.published),
      ),
    );

    testWidgets('Issue 400: sits beside Create application', (tester) async {
      await _pump(tester, master: FakeApplicationsMaster(_all()));
      final create = find.widgetWithText(
        ShadButton,
        ApplicationViewStrings.create,
      );
      expect(import, findsOneWidget);
      expect(
        tester.getCenter(import).dy,
        moreOrLessEquals(tester.getCenter(create).dy, epsilon: 1),
      );
      expect(
        tester.getRect(import).right,
        lessThan(tester.getRect(create).left),
      );
    });

    testWidgets('Issue 400: creates a draft from the picked file through the '
        'master and opens it', (tester) async {
      final master = FakeApplicationsMaster(_all());
      int? opened;
      await _pump(
        tester,
        master: master,
        onOpen: (id) => opened = id,
        onPickJsonFile: () async => exported(),
      );
      await tester.tap(import);
      await tester.pumpAndSettle();
      expect(master.calls, ['create {en: Trial, mr: चाचणी}']);
      final created = master.state.value![90]!;
      expect(created.status, ApplicationStatus.draft);
      expect(created.content, ApplicationSamples.content);
      expect(opened, 90);
    });

    testWidgets('Issue 400: a cancelled pick does nothing', (tester) async {
      final master = FakeApplicationsMaster(_all());
      int? opened;
      await _pump(
        tester,
        master: master,
        onOpen: (id) => opened = id,
        onPickJsonFile: () async => null,
      );
      await tester.tap(import);
      await tester.pumpAndSettle();
      expect(master.calls, isEmpty);
      expect(opened, isNull);
    });

    testWidgets('Issue 400: a file that is not an exported application says '
        'so and creates nothing', (tester) async {
      final master = FakeApplicationsMaster(_all());
      int? opened;
      await _pump(
        tester,
        master: master,
        onOpen: (id) => opened = id,
        onPickJsonFile: () async =>
            utf8.encode(jsonEncode({'name': 'a review template'})),
      );
      await tester.tap(import);
      await tester.pumpAndSettle();
      expect(
        find.text(ApplicationViewStrings.importUnreadable),
        findsOneWidget,
      );
      expect(master.calls, isEmpty);
      expect(opened, isNull);
    });

    testWidgets('Issue 400: a refusal is a fixed message, and nothing opens', (
      tester,
    ) async {
      final master = FakeApplicationsMaster(_all())
        ..failWith = const ServerException(
          statusCode: 422,
          code: SdkErrorCode.validationError,
          message: 'raw server words',
        );
      int? opened;
      await _pump(
        tester,
        master: master,
        onOpen: (id) => opened = id,
        onPickJsonFile: () async => exported(),
      );
      await tester.tap(import);
      await tester.pumpAndSettle();
      expect(find.text(ApplicationViewStrings.importFailed), findsOneWidget);
      expect(find.textContaining('raw server words'), findsNothing);
      expect(master.calls, hasLength(1));
      expect(opened, isNull);
    });
  });
}
