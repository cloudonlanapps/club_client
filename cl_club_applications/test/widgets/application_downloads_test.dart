import 'dart:typed_data';

import 'package:cl_club_applications/cl_club_applications.dart';
import 'package:cl_club_applications/src/constants/application_view_strings.dart';
import 'package:cl_club_applications/src/models/application_download.dart';
import 'package:cl_club_applications/src/widgets/application_download_button.dart';
import 'package:cl_club_applications/src/widgets/application_download_row.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;
import 'package:ui_lib/ui_lib.dart' show PdfAction;

import '../support/application_samples.dart';
import '../support/applications_harness.dart';
import '../support/pdf_action.dart';

Map<int, ApplicationTemplate> _published() => {
  4: ApplicationSamples.template(id: 4, status: ApplicationStatus.published),
  6: ApplicationSamples.template(id: 6),
};

void main() {
  group('Issue 321: ApplicationDownloadButton', () {
    testWidgets('Issue 321: hands the downloaded bytes on', (tester) async {
      final master = FakeApplicationsMaster(_published());
      final opened = <Uint8List>[];
      await pumpApplications(
        tester,
        ApplicationDownloadButton(
          download: const ApplicationOwnForm(4),
          pdfAction: recordingPdfAction(bytes: opened),
          fileName: 'Trial.pdf',
        ),
        master: master,
      );
      await tester.tap(find.text(testPdfActionLabel));
      await tester.pumpAndSettle();
      expect(master.calls, ['own 4']);
      expect(opened.single, [37, 80, 68, 70]);
    });

    testWidgets('Issue 324: shows the action’s label and icon and hands it '
        'the bytes and the file name', (tester) async {
      final master = FakeApplicationsMaster(_published());
      final handed = <(Uint8List, String)>[];
      await pumpApplications(
        tester,
        ApplicationDownloadButton(
          download: const ApplicationOwnForm(4),
          pdfAction: PdfAction(
            label: 'Share',
            icon: LucideIcons.share2,
            run: (bytes, fileName) async => handed.add((bytes, fileName)),
          ),
          fileName: 'Membership form.pdf',
        ),
        master: master,
      );
      expect(find.byIcon(LucideIcons.share2), findsOneWidget);
      expect(find.byIcon(LucideIcons.download), findsNothing);
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      expect(handed.single.$1, [37, 80, 68, 70]);
      expect(handed.single.$2, 'Membership form.pdf');
    });

    testWidgets('Issue 324: an action that fails is a fixed toast', (
      tester,
    ) async {
      await pumpApplications(
        tester,
        ApplicationDownloadButton(
          download: const ApplicationOwnForm(4),
          pdfAction: PdfAction(
            label: 'Share',
            icon: LucideIcons.share2,
            run: (_, _) async => throw StateError('raw platform words'),
          ),
          fileName: 'Trial.pdf',
        ),
        master: FakeApplicationsMaster(_published()),
      );
      await tester.tap(find.text('Share'));
      await tester.pumpAndSettle();
      expect(find.text(ApplicationViewStrings.downloadFailed), findsOneWidget);
      expect(find.textContaining('raw platform words'), findsNothing);
    });

    testWidgets('Issue 324: a row names the file after the application', (
      tester,
    ) async {
      final names = <String>[];
      await pumpApplications(
        tester,
        ApplicationDownloadRow(
          title: 'Membership form',
          download: const ApplicationOwnForm(4),
          pdfAction: recordingPdfAction(names: names),
        ),
        master: FakeApplicationsMaster(_published()),
      );
      await tester.tap(find.text(testPdfActionLabel));
      await tester.pumpAndSettle();
      expect(names, ['Membership form.pdf']);
    });

    testWidgets('Issue 321: a member not eligible is told so under the '
        'button, not shown the raw error', (tester) async {
      final master = FakeApplicationsMaster(_published())
        ..failWith = const ServerException(
          statusCode: 422,
          code: SdkErrorCode.applicationNotEligible,
          message: 'raw server words',
        );
      final opened = <Uint8List>[];
      await pumpApplications(
        tester,
        ApplicationDownloadButton(
          download: const ApplicationOwnForm(4),
          pdfAction: recordingPdfAction(bytes: opened),
          fileName: 'Trial.pdf',
        ),
        master: master,
      );
      await tester.tap(find.text(testPdfActionLabel));
      await tester.pumpAndSettle();
      expect(find.text(ApplicationViewStrings.notEligible), findsOneWidget);
      expect(find.textContaining('raw server words'), findsNothing);
      expect(opened, isEmpty);
    });

    testWidgets('Issue 321: any other failure is a fixed toast', (
      tester,
    ) async {
      final master = FakeApplicationsMaster(_published())
        ..failWith = const ServerException(
          statusCode: 503,
          code: 'UNAVAILABLE',
          message: 'raw server words',
        );
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
      expect(find.text(ApplicationViewStrings.downloadFailed), findsOneWidget);
      expect(find.textContaining('raw server words'), findsNothing);
    });
  });

  group('Issue 321: the profile’s Applications section', () {
    testWidgets('Issue 321: on one’s own profile downloads one’s own form', (
      tester,
    ) async {
      final master = FakeApplicationsMaster(_published());
      await pumpApplications(
        tester,
        ProfileApplicationsSection(
          member: applicationsUser(),
          own: true,
          pdfAction: recordingPdfAction(),
        ),
        master: master,
      );
      expect(find.text('Trial'), findsOneWidget, reason: 'published only');
      await tester.tap(find.text(testPdfActionLabel));
      await tester.pumpAndSettle();
      expect(master.calls, ['own 4']);
    });

    testWidgets('Issue 321: an admin on a member’s profile downloads that '
        'member’s form', (tester) async {
      final master = FakeApplicationsMaster(_published());
      await pumpApplications(
        tester,
        ProfileApplicationsSection(
          member: applicationsUser(),
          own: false,
          pdfAction: recordingPdfAction(),
        ),
        master: master,
      );
      await tester.tap(find.text(testPdfActionLabel));
      await tester.pumpAndSettle();
      expect(master.calls, ['member 4 member_a']);
    });

    testWidgets('Issue 321: renders nothing while applications are off', (
      tester,
    ) async {
      await pumpApplications(
        tester,
        ProfileApplicationsSection(
          member: applicationsUser(),
          own: true,
          pdfAction: recordingPdfAction(),
        ),
        master: FakeApplicationsMaster(_published()),
        enabled: false,
      );
      expect(find.byKey(ProfileApplicationsSection.cardKey), findsNothing);
    });
  });
}
