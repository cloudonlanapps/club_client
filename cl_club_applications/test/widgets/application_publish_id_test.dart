// Issue 339: the admin's template view shows a published template's
// publish ID, small and copyable; a draft or saved one shows none.
import 'package:cl_club_applications/cl_club_applications.dart';
import 'package:cl_club_applications/src/constants/application_view_strings.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/application_samples.dart';
import '../support/applications_harness.dart';
import '../support/pdf_action.dart';

const String _id = '3f6c1e2a-9b4d-4c7e-8a51-2d0f7b9e6c13';

Future<void> _pump(WidgetTester tester, ApplicationStatus status) async {
  final master = FakeApplicationsMaster({
    5: ApplicationSamples.template(status: status).copyWith(
      publishId: () => _id,
    ),
  });
  await pumpApplications(
    tester,
    ApplicationView(
      currentUser: applicationsUser(admin: true),
      applicationId: 5,
      onBack: () {},
      onDeleted: () {},
      pdfAction: recordingPdfAction(),
    ),
    master: master,
  );
}

void main() {
  group('Issue 339: the publish ID on the admin template view', () {
    testWidgets('Issue 339: a published template shows its publish ID, '
        'which copies', (tester) async {
      String? copied;
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        (call) async {
          if (call.method == 'Clipboard.setData') {
            copied = (call.arguments as Map)['text'] as String?;
          }
          return null;
        },
      );
      addTearDown(
        () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          SystemChannels.platform,
          null,
        ),
      );
      await _pump(tester, ApplicationStatus.published);

      expect(
        find.text(ApplicationViewStrings.publishId(_id)),
        findsOneWidget,
      );
      // Selectable, so it can be copied by hand too.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('application.state.publishId')),
          matching: find.byType(SelectableText),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('application.state.copyPublishId')),
      );
      await tester.pumpAndSettle();
      expect(copied, _id);
      expect(find.text(ApplicationViewStrings.publishIdCopied), findsOneWidget);
    });

    for (final status in [ApplicationStatus.saved, ApplicationStatus.draft]) {
      testWidgets('Issue 339: a ${status.wireName} template shows no publish '
          'ID', (tester) async {
        await _pump(tester, status);
        expect(find.textContaining('Publish ID'), findsNothing);
        expect(find.textContaining(_id), findsNothing);
        expect(
          find.byKey(const ValueKey('application.state.publishId')),
          findsNothing,
        );
      });
    }
  });
}
