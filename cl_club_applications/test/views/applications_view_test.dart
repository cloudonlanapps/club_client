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
      title: () => const ApplicationText.custom({'en': 'Season 2026'}),
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
  bool admin = false,
  bool enabled = true,
  List<MediaLink> documents = const [],
  ValueChanged<int>? onOpen,
}) => pumpApplications(
  tester,
  ApplicationsView(
    currentUser: applicationsUser(admin: admin),
    onOpen: onOpen ?? (_) {},
    onOpenPdfBytes: (_) {},
  ),
  master: master,
  enabled: enabled,
  documents: documents,
);

void main() {
  group('Issue 321: a member’s Applications page', () {
    testWidgets('Issue 321: lists the published ones with Download and what '
        'to do with the form', (tester) async {
      final master = FakeApplicationsMaster(_all());
      await _pump(tester, master: master, documents: [identityDocument()]);

      expect(find.text('Season 2026'), findsOneWidget);
      expect(find.text('Trial'), findsNothing, reason: 'drafts stay hidden');
      expect(find.text(ApplicationViewStrings.printNote), findsOneWidget);
      expect(find.text(ApplicationViewStrings.create), findsNothing);

      await tester.tap(find.text(ApplicationViewStrings.download));
      await tester.pumpAndSettle();
      expect(master.calls, ['own 2']);
    });

    testWidgets('Issue 321: without an identity document says why there is '
        'none', (tester) async {
      await _pump(tester, master: FakeApplicationsMaster({}));
      expect(
        find.text(ApplicationViewStrings.needsIdentityDocument),
        findsOneWidget,
      );
    });

    testWidgets('Issue 321: with a document and nothing published says none '
        'is open', (tester) async {
      await _pump(
        tester,
        master: FakeApplicationsMaster({}),
        documents: [identityDocument()],
      );
      expect(find.text(ApplicationViewStrings.noneOpen), findsOneWidget);
    });

    testWidgets('Issue 321: renders nothing while applications are off', (
      tester,
    ) async {
      await _pump(
        tester,
        master: FakeApplicationsMaster(_all()),
        enabled: false,
      );
      expect(find.text(ApplicationViewStrings.applications), findsNothing);
    });
  });

  group('Issue 321: an admin’s Applications page', () {
    testWidgets('Issue 321: lists every template with its state and offers '
        'Create', (tester) async {
      await _pump(tester, master: FakeApplicationsMaster(_all()), admin: true);

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

    testWidgets('Issue 321: Duplicate copies the template and opens the copy', (
      tester,
    ) async {
      final master = FakeApplicationsMaster(_all());
      int? opened;
      await _pump(
        tester,
        master: master,
        admin: true,
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
        admin: true,
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
