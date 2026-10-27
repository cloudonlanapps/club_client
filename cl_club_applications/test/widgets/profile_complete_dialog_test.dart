import 'dart:typed_data';

import 'package:cl_club_applications/cl_club_applications.dart';
import 'package:cl_club_applications/src/constants/application_view_strings.dart';
import 'package:cl_club_applications/src/models/application_download.dart';
import 'package:cl_club_applications/src/widgets/application_download_button.dart';
import 'package:cl_club_applications/src/widgets/profile_complete_dialog.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/application_samples.dart';
import '../support/applications_harness.dart';
import '../support/pdf_action.dart';
import '../support/profile_complete.dart';

Map<int, ApplicationTemplate> _published() => {
  4: ApplicationSamples.template(id: 4, status: ApplicationStatus.published),
};

final Finder _question = find.text(ApplicationViewStrings.profileCompleteTitle);

void main() {
  group('Issue 340: "Is your profile complete?" before a download', () {
    testWidgets('Issue 340: Download of one’s own form asks first and '
        'fetches nothing yet', (tester) async {
      final master = FakeApplicationsMaster(_published());
      await pumpApplications(
        tester,
        ApplicationDownloadButton(
          download: const ApplicationOwnForm(4),
          pdfAction: recordingPdfAction(),
          fileName: 'Trial.pdf',
        ),
        master: master,
      );
      await tester.tap(find.text(testPdfActionLabel));
      await tester.pumpAndSettle();

      expect(_question, findsOneWidget);
      expect(find.byKey(ProfileCompleteDialog.yesKey), findsOneWidget);
      expect(find.byKey(ProfileCompleteDialog.noKey), findsOneWidget);
      expect(master.calls, isEmpty);
    });

    testWidgets('Issue 340: the question lists the printed fields blank on '
        'the profile', (tester) async {
      await pumpApplications(
        tester,
        ApplicationDownloadButton(
          download: const ApplicationOwnForm(4),
          pdfAction: recordingPdfAction(),
          fileName: 'Trial.pdf',
        ),
        master: FakeApplicationsMaster(_published()),
        currentUser: completeProfileUser().copyWith(
          phone: () => ' ',
          address: () => const Address(),
          dateOfBirthUtc: () => null,
          nationality: () => null,
        ),
        extendedProfile: true,
      );
      await tester.tap(find.text(testPdfActionLabel));
      await tester.pumpAndSettle();

      expect(_question, findsOneWidget);
      for (final label in [
        ApplicationViewStrings.fieldDateOfBirth,
        ApplicationViewStrings.fieldPhone,
        ApplicationViewStrings.fieldAddress,
        ApplicationViewStrings.fieldNationality,
      ]) {
        expect(find.text('• $label'), findsOneWidget, reason: label);
      }
      expect(find.text('• ${ApplicationViewStrings.fieldEmail}'), findsNothing);
      expect(
        find.text('• ${ApplicationViewStrings.fieldGuardian}'),
        findsNothing,
      );
    });

    testWidgets('Issue 340: a complete profile downloads without asking', (
      tester,
    ) async {
      final master = FakeApplicationsMaster(_published());
      final handed = <Uint8List>[];
      await pumpApplications(
        tester,
        ApplicationDownloadButton(
          download: const ApplicationOwnForm(4),
          pdfAction: recordingPdfAction(bytes: handed),
          fileName: 'Trial.pdf',
        ),
        master: master,
        currentUser: completeProfileUser(),
        extendedProfile: true,
      );
      await tester.tap(find.text(testPdfActionLabel));
      await tester.pumpAndSettle();

      expect(_question, findsNothing);
      expect(master.calls, ['own 4']);
      expect(handed, hasLength(1));
    });

    testWidgets('Issue 340: Yes downloads and hands the bytes to the PDF '
        'action', (tester) async {
      final master = FakeApplicationsMaster(_published());
      final handed = <Uint8List>[];
      final names = <String>[];
      var opened = 0;
      await pumpApplications(
        tester,
        ApplicationDownloadButton(
          download: const ApplicationOwnForm(4),
          pdfAction: recordingPdfAction(bytes: handed, names: names),
          fileName: 'Trial.pdf',
          onOpenProfile: () => opened++,
        ),
        master: master,
      );
      await tester.tap(find.text(testPdfActionLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ProfileCompleteDialog.yesKey));
      await tester.pumpAndSettle();

      expect(_question, findsNothing);
      expect(master.calls, ['own 4']);
      expect(handed.single, [37, 80, 68, 70]);
      expect(names, ['Trial.pdf']);
      expect(opened, 0);
    });

    testWidgets('Issue 340: No opens the member’s profile and downloads '
        'nothing', (tester) async {
      final master = FakeApplicationsMaster(_published());
      final handed = <Uint8List>[];
      var opened = 0;
      await pumpApplications(
        tester,
        PublishedApplicationsList(
          currentUser: eligibleMember(),
          pdfAction: recordingPdfAction(bytes: handed),
          onOpenProfile: () => opened++,
        ),
        master: master,
      );
      await tester.tap(find.text(testPdfActionLabel));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(ProfileCompleteDialog.noKey));
      await tester.pumpAndSettle();

      expect(opened, 1);
      expect(_question, findsNothing);
      expect(master.calls, isEmpty);
      expect(handed, isEmpty);
    });

    testWidgets('Issue 340: on one’s own profile, No only closes the '
        'question', (tester) async {
      final master = FakeApplicationsMaster(_published());
      final handed = <Uint8List>[];
      await pumpApplications(
        tester,
        ProfileApplicationsSection(
          member: eligibleMember(),
          own: true,
          pdfAction: recordingPdfAction(bytes: handed),
        ),
        master: master,
      );
      await tester.tap(find.text(testPdfActionLabel));
      await tester.pumpAndSettle();
      expect(_question, findsOneWidget);
      await tester.tap(find.byKey(ProfileCompleteDialog.noKey));
      await tester.pumpAndSettle();

      expect(_question, findsNothing);
      expect(find.byKey(ProfileApplicationsSection.cardKey), findsOneWidget);
      expect(master.calls, isEmpty);
      expect(handed, isEmpty);
    });

    testWidgets('Issue 340: an admin’s preview downloads without asking', (
      tester,
    ) async {
      final master = FakeApplicationsMaster(_published());
      final handed = <Uint8List>[];
      await pumpApplications(
        tester,
        ApplicationDownloadButton(
          download: const ApplicationPreview(4),
          pdfAction: recordingPdfAction(bytes: handed),
          fileName: 'Trial.pdf',
          label: ApplicationViewStrings.preview,
        ),
        master: master,
      );
      await tester.tap(find.text(ApplicationViewStrings.preview));
      await tester.pumpAndSettle();

      expect(_question, findsNothing);
      expect(master.calls, ['preview 4']);
      expect(handed, hasLength(1));
    });

    testWidgets('Issue 340: an admin downloading a member’s form from their '
        'profile is not asked', (tester) async {
      final master = FakeApplicationsMaster(_published());
      await pumpApplications(
        tester,
        ProfileApplicationsSection(
          member: eligibleMember(),
          own: false,
          pdfAction: recordingPdfAction(),
        ),
        master: master,
      );
      await tester.tap(find.text(testPdfActionLabel));
      await tester.pumpAndSettle();

      expect(_question, findsNothing);
      expect(master.calls, ['member 4 member_a']);
    });
  });
}
