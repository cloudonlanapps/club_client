import 'package:cl_club_applications/cl_club_applications.dart';
import 'package:cl_club_applications/src/constants/application_view_strings.dart';
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
}) => pumpApplications(
  tester,
  ApplicationsView(
    currentUser: applicationsUser(admin: true),
    onOpen: onOpen ?? (_) {},
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
}
