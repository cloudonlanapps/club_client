// workflow_emptysite: every page of a site whose server holds nothing yet
// (club_client#82).
//
// A visitor, with no session, opens each address of the site:
//
//   * the landing page shows its hero and no event section;
//   * Programmes, Camps, One-off, Coaches and Rinks each show their empty
//     state, with no error and nothing left loading;
//   * About shows the bundled story;
//   * Contact shows the bundled contact details and the contact form;
//   * the sign-up address shows the interest form.
//
// Every page carries the club's name from the host's `assets/club.json`,
// and the contact details are those of `assets/data/contact_info.json`: the
// server has no club details to put over them.
//
// It needs a server no test has written to. `just website-test` starts a
// fresh stack per conf, and this file sorts first among the suite's files,
// so it runs before the ones that seed. It creates nothing, so it has
// nothing to clean up.
//
// Recommended run (from the club_core root):
//   just website-test-one app_test_server1.conf \
//       workflow_emptysite_every_route_test.dart

import 'package:cl_club_events/cl_club_events.dart'
    show PublicEventsSection, PublicEventsSectionError;
import 'package:cl_club_website/cl_club_website.dart';
import 'package:cl_club_website/src/widgets/club_contact_card.dart'
    show ClubContactCard;
import 'package:cl_club_website/src/widgets/club_content_section.dart'
    show ClubContentSection;
import 'package:cl_club_website/src/widgets/hero_section.dart' show HeroSection;
import 'package:cl_club_website/src/widgets/history_content.dart'
    show HistoryContent;
import 'package:cl_club_website/src/widgets/page_data_scaffold.dart'
    show EmptyStateSection, ErrorContent, LoadingContent;
import 'package:cl_club_website/src/widgets/public_page_shell.dart'
    show PublicFooter;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clPublicClubInfoProvider;
import 'package:cl_server_config/cl_server_config.dart'
    show NetworkFailureScreen;
import 'package:club_sdk_2/club_sdk_2.dart' show InquiryKind;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import '_helpers/pump.dart';

const _kApiBaseUrl = String.fromEnvironment(
  'CLUB_API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8155/v1',
);

/// The language the site's copy and the contact block are read in.
const _kLanguage = 'en';

/// The copy the mounted site is showing.
SiteCopy _copy(WidgetTester tester) =>
    SiteCopy(container(tester).read(siteStringsProvider).requireValue);

/// Mounts the site and opens [route].
Future<void> _open(WidgetTester tester, String route) async {
  await pumpSite(tester, apiBaseUrl: _kApiBaseUrl, location: route);
  expect(currentLocation(tester), route);
}

/// What every page shows: no failure screen, and the footer with the club's
/// name from the host's `assets/club.json`.
Future<void> _expectPageOfTheClub(WidgetTester tester) async {
  expect(find.byType(NetworkFailureScreen), findsNothing);
  expect(find.byType(ErrorContent), findsNothing);
  expect(find.byType(PublicEventsSectionError), findsNothing);
  final config = await SiteConfig.load();
  expect(
    find.descendant(
      of: find.byType(PublicFooter),
      matching: find.textContaining('${config.fullName}. All rights reserved.'),
    ),
    findsOneWidget,
    reason: "the club's name in the footer",
  );
}

/// Opens the listing at [route] and expects [page] with the empty state of
/// [type], once the server has answered.
Future<void> _expectEmptyListing(
  WidgetTester tester, {
  required String route,
  required Type page,
  required PageType type,
}) async {
  await _open(tester, route);
  expect(find.byType(page), findsOneWidget);
  await waitFor(
    tester,
    () =>
        find.byType(LoadingContent).evaluate().isEmpty &&
        find.byType(EmptyStateSection).evaluate().isNotEmpty,
    description: 'the empty state of $route',
  );
  final expected = _copy(tester).pageData(type).emptyState;
  final shown = tester.widget<EmptyStateSection>(
    find.byType(EmptyStateSection),
  );
  expect(shown.data.title, expected.title);
  expect(shown.data.buttonText, expected.buttonText);
  expect(
    find.descendant(
      of: find.byType(EmptyStateSection),
      matching: find.text(expected.title),
    ),
    findsOneWidget,
  );
  await _expectPageOfTheClub(tester);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Issue 82: the landing page of an empty site shows the hero and '
      'no event section', (tester) async {
    await _open(tester, '/');
    expect(find.byType(LandingPage), findsOneWidget);
    expect(find.byType(HeroSection), findsOneWidget);
    // Give the three event reads time to answer: a section would show then.
    await tester.pump(const Duration(seconds: 2));
    await settle(tester);
    expect(find.byType(PublicEventsSection), findsNothing);
    await _expectPageOfTheClub(tester);
  });

  testWidgets('Issue 82: Programmes of an empty site shows its empty state', (
    tester,
  ) async {
    await _expectEmptyListing(
      tester,
      route: '/public/programs',
      page: TrainingSessionsPage,
      type: PageType.trainingSessions,
    );
  });

  testWidgets('Issue 82: Camps of an empty site shows its empty state', (
    tester,
  ) async {
    await _expectEmptyListing(
      tester,
      route: '/public/events',
      page: LearningCampsPage,
      type: PageType.learningCamps,
    );
  });

  testWidgets('Issue 82: One-off events of an empty site shows its empty '
      'state', (tester) async {
    await _expectEmptyListing(
      tester,
      route: '/public/one-off',
      page: ClubEventsPage,
      type: PageType.clubEvents,
    );
  });

  testWidgets('Issue 82: Coaches of an empty site shows its empty state', (
    tester,
  ) async {
    await _expectEmptyListing(
      tester,
      route: '/public/coaches',
      page: IceMastersPage,
      type: PageType.iceMasters,
    );
  });

  testWidgets('Issue 82: Rinks of an empty site shows its empty state', (
    tester,
  ) async {
    await _expectEmptyListing(
      tester,
      route: '/public/rinks',
      page: TheRinksPage,
      type: PageType.theRinks,
    );
  });

  testWidgets('Issue 82: About of an empty site shows the bundled story', (
    tester,
  ) async {
    await _open(tester, '/public/about-us');
    expect(find.byType(TheClubPage), findsOneWidget);
    expect(find.byType(ClubContentSection), findsOneWidget);
    final bundled = _copy(tester).clubInfo;
    expect(bundled.history.text, isNotEmpty);
    expect(
      tester.widget<HistoryContent>(find.byType(HistoryContent)).data.text,
      bundled.history.text,
    );
    await _expectPageOfTheClub(tester);
  });

  testWidgets('Issue 82: Contact of an empty site shows the bundled contact '
      'details and the contact form', (tester) async {
    await _open(tester, '/public/contact-us');
    expect(find.byType(ContactUsPage), findsOneWidget);
    // The server has answered, with no club details to put over the bundled
    // ones: what shows is not just what shows before it answers.
    await waitFor(
      tester,
      () => container(tester).read(clPublicClubInfoProvider).hasValue,
      description: "the server's public club info",
    );
    await settle(tester);

    final bundled = await loadBundledContactInfo();
    final card = find.byType(ClubContactCard);
    expect(card, findsOneWidget);
    for (final detail in [
      bundled.fullAddress(_kLanguage),
      bundled.phoneNumber,
      bundled.email,
    ]) {
      expect(detail, isNotEmpty);
      expect(
        find.descendant(of: card, matching: find.text(detail)),
        findsWidgets,
        reason: '"$detail" in the contact card',
      );
    }

    final form = tester.widget<InquiryView>(find.byType(InquiryView));
    expect(form.kind, InquiryKind.contact);
    await _expectPageOfTheClub(tester);
  });

  testWidgets('Issue 82: the sign-up address of an empty site shows the '
      'interest form', (tester) async {
    await _open(tester, '/auth/signup');
    expect(find.byType(SignupPage), findsOneWidget);
    final form = tester.widget<InquiryView>(find.byType(InquiryView));
    expect(form.kind, InquiryKind.interest);
    await _expectPageOfTheClub(tester);
  });
}
