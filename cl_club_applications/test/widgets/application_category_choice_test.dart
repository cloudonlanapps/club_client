// Issue 337: a member who fits more than one age category of a template
// is asked which one the form ticks, after "Is your profile complete?"
// (#340) when that asks, and the form downloads with it. The samples'
// categories are Under-12 (0) and Open (1).
import 'dart:typed_data';

import 'package:cl_club_applications/cl_club_applications.dart';
import 'package:cl_club_applications/src/constants/application_view_strings.dart';
import 'package:cl_club_applications/src/models/application_download.dart';
import 'package:cl_club_applications/src/widgets/application_category_dialog.dart';
import 'package:cl_club_applications/src/widgets/application_download_button.dart';
import 'package:cl_club_applications/src/widgets/profile_complete_dialog.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show ShadButton;

import '../support/application_samples.dart';
import '../support/applications_harness.dart';
import '../support/pdf_action.dart';
import '../support/profile_complete.dart';

Map<int, ApplicationTemplate> _published() => {
  4: ApplicationSamples.template(id: 4, status: ApplicationStatus.published),
};

final Finder _profileQuestion = find.text(
  ApplicationViewStrings.profileCompleteTitle,
);

final Finder _categoryQuestion = find.text(
  ApplicationViewStrings.chooseCategoryTitle,
);

/// Mounts the Download button of the signed-in member's own form of
/// template 4, with [master] and [currentUser]; [opened] gets the bytes.
Future<void> _pumpOwn(
  WidgetTester tester,
  FakeApplicationsMaster master, {
  UserPrivate? currentUser,
  List<Uint8List>? opened,
}) => pumpApplications(
  tester,
  ApplicationDownloadButton(
    download: const ApplicationOwnForm(4),
    pdfAction: recordingPdfAction(bytes: opened),
    fileName: 'Trial.pdf',
  ),
  master: master,
  currentUser: currentUser,
);

Future<void> _tapDownload(WidgetTester tester) async {
  await tester.tap(find.text(testPdfActionLabel));
  await tester.pumpAndSettle();
}

Future<void> _choose(WidgetTester tester, int index) async {
  await tester.tap(find.byKey(ApplicationCategoryDialog.choiceKey(index)));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(ApplicationCategoryDialog.downloadKey));
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 337: choosing the age category on download', () {
    testWidgets('Issue 337: two fitting categories show the choice; '
        'picking one downloads with it', (tester) async {
      final master = FakeApplicationsMaster(_published())..fitting = [0, 1];
      final opened = <Uint8List>[];
      await _pumpOwn(
        tester,
        master,
        currentUser: completeProfileUser(),
        opened: opened,
      );
      await _tapDownload(tester);

      expect(_profileQuestion, findsNothing);
      expect(_categoryQuestion, findsOneWidget);
      expect(find.text('Under-12'), findsOneWidget);
      expect(find.text('Open'), findsOneWidget);
      expect(
        tester
            .widget<ShadButton>(
              find.byKey(ApplicationCategoryDialog.downloadKey),
            )
            .enabled,
        isFalse,
        reason: 'one category must be chosen',
      );
      expect(opened, isEmpty);

      await _choose(tester, 1);
      expect(_categoryQuestion, findsNothing);
      expect(master.calls, ['own 4', 'own 4 category 1']);
      expect(opened.single, [37, 80, 68, 70]);
    });

    testWidgets('Issue 337: one fitting category downloads without asking', (
      tester,
    ) async {
      final master = FakeApplicationsMaster(_published())..fitting = [1];
      final opened = <Uint8List>[];
      await _pumpOwn(
        tester,
        master,
        currentUser: completeProfileUser(),
        opened: opened,
      );
      await _tapDownload(tester);

      expect(_categoryQuestion, findsNothing);
      expect(master.calls, ['own 4']);
      expect(opened, hasLength(1));
    });

    testWidgets('Issue 337: blank fields and two categories ask both, '
        'profile first', (tester) async {
      final master = FakeApplicationsMaster(_published())..fitting = [0, 1];
      final opened = <Uint8List>[];
      await _pumpOwn(tester, master, opened: opened);
      await _tapDownload(tester);

      expect(_profileQuestion, findsOneWidget);
      expect(_categoryQuestion, findsNothing);
      expect(master.calls, isEmpty);

      await tester.tap(find.byKey(ProfileCompleteDialog.yesKey));
      await tester.pumpAndSettle();
      expect(_profileQuestion, findsNothing);
      expect(_categoryQuestion, findsOneWidget);

      await _choose(tester, 0);
      expect(master.calls, ['own 4', 'own 4 category 0']);
      expect(opened, hasLength(1));
    });

    testWidgets('Issue 337: No to the profile question asks no category '
        'and downloads nothing', (tester) async {
      final master = FakeApplicationsMaster(_published())..fitting = [0, 1];
      final opened = <Uint8List>[];
      await _pumpOwn(tester, master, opened: opened);
      await _tapDownload(tester);
      await tester.tap(find.byKey(ProfileCompleteDialog.noKey));
      await tester.pumpAndSettle();

      expect(_categoryQuestion, findsNothing);
      expect(master.calls, isEmpty);
      expect(opened, isEmpty);
    });

    testWidgets('Issue 337: Cancel on the category choice downloads nothing '
        'and shows no refusal; the next Download asks again', (tester) async {
      final master = FakeApplicationsMaster(_published())..fitting = [0, 1];
      final opened = <Uint8List>[];
      await _pumpOwn(
        tester,
        master,
        currentUser: completeProfileUser(),
        opened: opened,
      );
      await _tapDownload(tester);
      await tester.tap(find.byKey(ApplicationCategoryDialog.cancelKey));
      await tester.pumpAndSettle();

      expect(_categoryQuestion, findsNothing);
      expect(opened, isEmpty);
      expect(master.calls, ['own 4'], reason: 'no download with a category');
      expect(find.textContaining('raw server words'), findsNothing);
      expect(find.text(ApplicationViewStrings.downloadFailed), findsNothing);

      await _tapDownload(tester);
      expect(_categoryQuestion, findsOneWidget, reason: 'not remembered');
    });

    testWidgets('Issue 337: an admin downloading a member’s form is asked '
        'only the category', (tester) async {
      final master = FakeApplicationsMaster(_published())..fitting = [0, 1];
      final opened = <Uint8List>[];
      await pumpApplications(
        tester,
        ProfileApplicationsSection(
          member: applicationsUser(),
          own: false,
          pdfAction: recordingPdfAction(bytes: opened),
        ),
        master: master,
        currentUser: applicationsUser(admin: true),
      );
      await _tapDownload(tester);

      expect(_profileQuestion, findsNothing);
      expect(_categoryQuestion, findsOneWidget);

      await _choose(tester, 0);
      expect(master.calls, [
        'member 4 member_a',
        'member 4 member_a category 0',
      ]);
      expect(opened, hasLength(1));
    });

    testWidgets('Issue 337: the admin’s preview never asks', (tester) async {
      final master = FakeApplicationsMaster(_published())..fitting = [0, 1];
      await pumpApplications(
        tester,
        ApplicationDownloadButton(
          download: const ApplicationPreview(4),
          pdfAction: recordingPdfAction(),
          fileName: 'Trial.pdf',
        ),
        master: master,
        currentUser: applicationsUser(admin: true),
      );
      await _tapDownload(tester);

      expect(_categoryQuestion, findsNothing);
      expect(master.calls, ['preview 4']);
    });
  });
}
