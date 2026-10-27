import 'package:cl_club_applications/cl_club_applications.dart';
import 'package:cl_club_applications/src/constants/application_view_strings.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/application_samples.dart';
import '../support/applications_harness.dart';
import '../support/pdf_action.dart';
import '../support/profile_complete.dart';

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
  UserPrivate? user,
  bool enabled = true,
  List<MediaLink> documents = const [],
}) {
  final viewer = user ?? _adult();
  return pumpApplications(
    tester,
    MyApplicationsView(
      currentUser: viewer,
      pdfAction: recordingPdfAction(),
      onOpenProfile: () {},
    ),
    master: master,
    enabled: enabled,
    documents: documents,
    currentUser: viewer,
  );
}

/// A member the samples' "Open" category fits: born before 2014.
UserPrivate _adult({bool admin = false}) =>
    applicationsUser(admin: admin).copyWith(
      dateOfBirthUtc: () => DateTime.utc(1990, 5, 4),
    );

/// A published template for members born from 2014: one [_adult] doesn't fit.
ApplicationTemplate _juniorOnly(int id) => ApplicationSamples.template(
  id: id,
  status: ApplicationStatus.published,
  content: ApplicationSamples.content.copyWith(
    title: () => const ApplicationText({'en': 'Juniors 2026'}),
    ageCategories: [
      ApplicationAgeCategory(
        label: const {'en': 'Under-12'},
        bornOnOrAfterUtc: DateTime.utc(2014),
      ),
    ],
  ),
);

/// A published template for every member: no age categories.
ApplicationTemplate _everyone(int id) => ApplicationSamples.template(
  id: id,
  status: ApplicationStatus.published,
  content: ApplicationSamples.content.copyWith(
    title: () => const ApplicationText({'en': 'Volunteers'}),
    ageCategories: const [],
  ),
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

      await tester.tap(find.text(testPdfActionLabel));
      await answerProfileComplete(tester);
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

  group('Issue 380: only the applications the member is eligible for', () {
    testWidgets('Issue 380: one the member fits no category of is not '
        'listed', (tester) async {
      await _pump(
        tester,
        master: FakeApplicationsMaster({..._all(), 4: _juniorOnly(4)}),
        documents: [identityDocument()],
      );
      expect(find.text('Season 2026'), findsOneWidget);
      expect(find.text('Juniors 2026'), findsNothing);
    });

    testWidgets('Issue 380: with none they fit, says none is open', (
      tester,
    ) async {
      await _pump(
        tester,
        master: FakeApplicationsMaster({4: _juniorOnly(4)}),
        documents: [identityDocument()],
      );
      expect(find.text(ApplicationViewStrings.noneOpen), findsOneWidget);
      expect(find.text('Juniors 2026'), findsNothing);
    });

    testWidgets('Issue 380: without a date of birth asks for one, and lists '
        'only those without categories', (tester) async {
      await _pump(
        tester,
        master: FakeApplicationsMaster({..._all(), 4: _everyone(4)}),
        user: applicationsUser(),
        documents: [identityDocument()],
      );
      expect(
        find.text(ApplicationViewStrings.needsDateOfBirth),
        findsOneWidget,
      );
      expect(find.text('Volunteers'), findsOneWidget);
      expect(find.text('Season 2026'), findsNothing);
    });

    testWidgets('Issue 380: an admin sees the member list, without Create', (
      tester,
    ) async {
      await _pump(
        tester,
        master: FakeApplicationsMaster(_all()),
        user: _adult(admin: true),
        documents: [identityDocument()],
      );
      expect(find.text('Season 2026'), findsOneWidget);
      expect(find.text('Draft'), findsNothing);
      expect(find.text(ApplicationViewStrings.create), findsNothing);
    });
  });
}
