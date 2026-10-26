import 'dart:typed_data';

import 'package:cl_club_applications/cl_club_applications.dart';
import 'package:cl_club_applications/src/constants/application_view_strings.dart';
import 'package:cl_club_applications/src/models/application_download.dart';
import 'package:cl_club_applications/src/widgets/application_download_button.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/application_samples.dart';
import '../support/applications_harness.dart';

Map<int, ApplicationTemplate> _published() => {
  4: ApplicationSamples.template(id: 4, status: ApplicationStatus.published),
  6: ApplicationSamples.template(id: 6),
};

void main() {
  group('Issue 321: ApplicationDownloadButton', () {
    testWidgets('Issue 321: hands the downloaded bytes on', (tester) async {
      final master = FakeApplicationsMaster(_published());
      Uint8List? opened;
      await pumpApplications(
        tester,
        ApplicationDownloadButton(
          download: const ApplicationOwnForm(4),
          onOpenPdfBytes: (bytes) => opened = bytes,
        ),
        master: master,
      );
      await tester.tap(find.text(ApplicationViewStrings.download));
      await tester.pumpAndSettle();
      expect(master.calls, ['own 4']);
      expect(opened, [37, 80, 68, 70]);
    });

    testWidgets('Issue 321: a member not eligible is told so under the '
        'button, not shown the raw error', (tester) async {
      final master = FakeApplicationsMaster(_published())
        ..failWith = const ServerException(
          statusCode: 422,
          code: SdkErrorCode.applicationNotEligible,
          message: 'raw server words',
        );
      Uint8List? opened;
      await pumpApplications(
        tester,
        ApplicationDownloadButton(
          download: const ApplicationOwnForm(4),
          onOpenPdfBytes: (bytes) => opened = bytes,
        ),
        master: master,
      );
      await tester.tap(find.text(ApplicationViewStrings.download));
      await tester.pumpAndSettle();
      expect(find.text(ApplicationViewStrings.notEligible), findsOneWidget);
      expect(find.textContaining('raw server words'), findsNothing);
      expect(opened, isNull);
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
          onOpenPdfBytes: (_) {},
        ),
        master: master,
      );
      await tester.tap(find.text(ApplicationViewStrings.download));
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
          onOpenPdfBytes: (_) {},
        ),
        master: master,
      );
      expect(find.text('Trial'), findsOneWidget, reason: 'published only');
      await tester.tap(find.text(ApplicationViewStrings.download));
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
          onOpenPdfBytes: (_) {},
        ),
        master: master,
      );
      await tester.tap(find.text(ApplicationViewStrings.downloadForMember));
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
          onOpenPdfBytes: (_) {},
        ),
        master: FakeApplicationsMaster(_published()),
        enabled: false,
      );
      expect(find.byKey(ProfileApplicationsSection.cardKey), findsNothing);
    });
  });
}
