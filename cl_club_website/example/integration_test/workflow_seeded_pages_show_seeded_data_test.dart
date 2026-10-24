// workflow_seeded: every page shows what was seeded for it (club_client#83).
//
// One data set is written once through the SDK, as the super-admin, and a
// visitor with no session then opens each page:
//
//   * the landing page's hero carries the featured events and only those,
//     and its sections the soonest events of each type;
//   * Camps, Programmes and One-off each list their own type in order of
//     start, past ones apart, and leave out a private or a deleted event;
//   * a camp's page shows its title, dates, venue and coaches, and never a
//     coach without a public profile; the extended marketing block shows
//     where the stack has the module on, and not where it is off;
//   * Coaches lists the coaches with a public profile, each with the name,
//     bio and photo given, and the placeholder for one without a photo;
//   * Rinks lists each venue, and a venue's page shows its details, with a
//     map only when it has a location;
//   * Contact and About show the club's details: the bundled ones, then the
//     ones written through the SDK, then the bundled ones again once the
//     original is put back.
//
// The site has no screen that deletes anything, so the fixtures are removed
// through the SDK in tearDownAll, and the test checks that they are gone.
//
// Recommended run (from the club_core root):
//   just website-test-one app_test_server1.conf \
//       workflow_seeded_pages_show_seeded_data_test.dart

import 'package:cl_club_events/cl_club_events.dart';
import 'package:cl_club_events/src/widgets/public/detail/public_event_coach_row.dart'
    show PublicEventCoachRow;
import 'package:cl_club_events/src/widgets/public/detail/public_event_eligibility_section.dart'
    show PublicEventEligibilitySection;
import 'package:cl_club_events/src/widgets/public/detail/public_event_fees_section.dart'
    show PublicEventFeesSection;
import 'package:cl_club_events/src/widgets/public/event_info_badge.dart'
    show EventInfoBadge;
import 'package:cl_club_members/cl_club_members.dart' show CoachCard;
import 'package:cl_club_members/src/widgets/placeholder_avatar.dart'
    show PlaceholderAvatar;
import 'package:cl_club_venues/cl_club_venues.dart'
    show PublicVenueCard, VenueContent;
import 'package:cl_club_website/cl_club_website.dart';
import 'package:cl_club_website/src/widgets/club_contact_card.dart'
    show ClubContactCard;
import 'package:cl_club_website/src/widgets/hero_section.dart'
    show HeroSection, HeroSectionState;
import 'package:cl_club_website/src/widgets/history_content.dart'
    show HistoryContent;
import 'package:cl_remote_store/cl_remote_store.dart'
    show MediaUrlBuilder, clPublicClubInfoProvider, contactInfoProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart' hide Visibility;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/content_page/page_hero.dart' show PageHero;
import 'package:ui_lib/ui_lib.dart'
    show ErrorContent, LoadingContent, MapEmbed, ThemedMarkdown;

import '_helpers/capabilities.dart';
import '_helpers/pump.dart';
import '_helpers/seed.dart';

const _kApiBaseUrl = String.fromEnvironment(
  'CLUB_API_BASE_URL',
  defaultValue: 'http://127.0.0.1:8155/v1',
);
const _kSudoUsername = String.fromEnvironment(
  'SUDO_USERNAME',
  defaultValue: 'sudo',
);
const _kSudoPassword = String.fromEnvironment('SUDO_PASSWORD');

/// Every fixture's name starts with this, so a leftover row names this file
/// and the checks can tell their own rows from anyone else's.
const _kId = 'workflow_seeded';

/// The language the site's copy and the contact block are read in.
const _kLanguage = 'en';

// --- Venues -----------------------------------------------------------------
const _kVenueLocated = '$_kId venue with location';
const _kVenueLocatedAddress = '$_kId 1 Rink Road';
const _kVenueLocatedDescription = '$_kId the main sheet';
const _kVenueLocatedMap =
    'https://www.openstreetmap.org/#map=16/51.5050/-0.1250';
const _kVenuePlain = '$_kId venue without location';
const _kVenuePlainDescription = '$_kId the practice sheet';

// --- Coaches ----------------------------------------------------------------
const _kCoachFull = '${_kId}_coach_full';
const _kCoachFullLast = 'coach with photo';
const _kCoachFullBio = '$_kId bio of the coach with a photo';
const _kCoachPlain = '${_kId}_coach_plain';
const _kCoachPlainLast = 'coach without photo';
const _kCoachPrivate = '${_kId}_coach_private';
const _kCoachPrivateLast = 'coach without public profile';
const _kCoachPrivateBio = '$_kId bio nobody outside the club reads';

final String _coachFullName = coachDisplayName(_kId, _kCoachFullLast);
final String _coachPlainName = coachDisplayName(_kId, _kCoachPlainLast);
final String _coachPrivateName = coachDisplayName(_kId, _kCoachPrivateLast);

// --- Events -----------------------------------------------------------------
const _kCampFeatured = '$_kId camp featured';
const _kCampFeaturedTagline = '$_kId three days on the ice';
const _kCampPlain = '$_kId camp not featured';
const _kCampPast = '$_kId camp past';
const _kCampPrivate = '$_kId camp private';
const _kCampDeleted = '$_kId camp deleted';
const _kProgrammeFirst = '$_kId programme first';
const _kProgrammeSecond = '$_kId programme second';
const _kProgrammePrivate = '$_kId programme private';
const _kOneOffFeatured = '$_kId one-off featured';
const _kOneOffPlain = '$_kId one-off not featured';
const _kOneOffPast = '$_kId one-off past';
const _kOneOffPrivate = '$_kId one-off private';

/// The featured camp starts this many days from today.
const _kCampFeaturedInDays = 10;

// --- The extended marketing block of the featured camp ---------------------
const _kMarketingSchedule = '$_kId schedule text';
const _kMarketingFee = 4500;
const _kMarketingEligibility = '$_kId eligibility text';

// --- The club identity written, then put back -----------------------------
const _kClubName = '$_kId Club';
const _kClubPhone = '+10000000083';
const _kClubEmail = '$_kId@example.com';
const _kClubAddress = '$_kId 83 Identity Street';
const _kClubStory = '$_kId story of the club, as the server holds it.';

bool _isOurs(String name) => name.startsWith(_kId);

/// The titles among [titles] this file seeded, in the order given.
List<String> _ours(Iterable<String> titles) => titles.where(_isOurs).toList();

/// Mounts the site at [route] and waits for the page's reads to answer.
Future<void> _open(WidgetTester tester, String route) async {
  await pumpSite(tester, apiBaseUrl: _kApiBaseUrl, location: route);
  expect(currentLocation(tester), route);
  await _waitUntilLoaded(tester);
}

Future<void> _waitUntilLoaded(WidgetTester tester) async {
  await waitFor(
    tester,
    () =>
        find.byType(LoadingContent).evaluate().isEmpty &&
        find.byType(CircularProgressIndicator).evaluate().isEmpty,
    description: 'the page to finish loading',
  );
  expect(find.byType(ErrorContent), findsNothing);
}

/// The titles of the event cards of type [T] on screen, top to bottom.
List<String> _cardTitles<T extends Widget>(
  WidgetTester tester,
  PublicEventView Function(T card) eventOf,
) => _ours(tester.widgetList<T>(find.byType(T)).map((c) => eventOf(c).title));

/// Opens the page of the event titled [title] from its card in a listing.
Future<void> _openEventFromCard(WidgetTester tester, String title) async {
  final card = tester
      .widgetList<PublicEventCard>(find.byType(PublicEventCard))
      .firstWhere((c) => c.event.title == title);
  card.onTap!();
  await settle(tester);
  await waitFor(
    tester,
    () => find.byType(PublicEventDetailContent).evaluate().isNotEmpty,
    description: 'the page of "$title"',
  );
  expect(currentLocation(tester), startsWith('/public/events/'));
}

/// Opens the page of the venue named [name] from its card on Rinks.
Future<void> _openVenueFromCard(WidgetTester tester, String name) async {
  final card = tester
      .widgetList<PublicVenueCard>(find.byType(PublicVenueCard))
      .firstWhere((c) => c.venue.name == name);
  card.onTap!();
  await settle(tester);
  await waitFor(
    tester,
    () => find.byType(VenueContent).evaluate().isNotEmpty,
    description: 'the page of "$name"',
  );
  expect(currentLocation(tester), startsWith('/public/rink/'));
}

/// Waits for the server's club details, then for the contact card to show
/// [phone].
Future<void> _expectContactPhone(WidgetTester tester, String phone) async {
  await waitFor(
    tester,
    () => container(tester).read(clPublicClubInfoProvider).hasValue,
    description: "the server's public club info",
  );
  final card = find.byType(ClubContactCard);
  try {
    await waitFor(
      tester,
      () => find
          .descendant(of: card, matching: find.text(phone))
          .evaluate()
          .isNotEmpty,
      description: '"$phone" in the contact card',
    );
  } on TestFailure catch (e) {
    final shown = [
      for (final t in tester.widgetList<Text>(
        find.descendant(of: card, matching: find.byType(Text)),
      ))
        t.data ?? t.textSpan?.toPlainText(),
    ];
    final info = container(tester).read(clPublicClubInfoProvider);
    final contact = container(tester).read(contactInfoProvider);
    throw TestFailure(
      '$e; card: ${card.evaluate().length} showing $shown; '
      'club info: ${info.valueOrNull}; contact phone: ${contact.phoneNumber}',
    );
  }
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  if (_kSudoPassword.isEmpty) {
    throw StateError('SUDO_PASSWORD must be supplied via --dart-define.');
  }

  late Capabilities caps;
  late SecureClient admin;
  late Media coachPhoto;
  final eventIds = <String, int>{};
  final venueIds = <int>[];
  const coaches = [_kCoachFull, _kCoachPlain, _kCoachPrivate];

  Future<void> seedEvent(
    String title,
    EventType type, {
    required int venueId,
    required DateTime start,
    Duration length = const Duration(hours: 1),
    String? rrule,
    Visibility visibility = Visibility.public,
    bool featured = false,
    List<String>? coachNames,
    String? shortDescription,
  }) async {
    final event = await admin.events.createEvent(
      acceptConflicts: true,
      title: title,
      description: '$title description',
      type: type,
      visibility: visibility,
      venueId: venueId,
      startTimeUtc: start,
      endTimeUtc: start.add(length),
      rrule: rrule,
      isFeatured: featured,
      coachNames: coachNames,
      shortDescription: shortDescription,
    );
    eventIds[title] = event.id;
  }

  setUpAll(() async {
    caps = await stackCapabilities(baseUrl: _kApiBaseUrl);
    admin = await sudoClient(
      baseUrl: _kApiBaseUrl,
      username: _kSudoUsername,
      password: _kSudoPassword,
    );

    // Venues: one with a location, one without.
    final located = await admin.venues.createVenue(
      name: _kVenueLocated,
      address: _kVenueLocatedAddress,
      description: _kVenueLocatedDescription,
      mapUri: _kVenueLocatedMap,
    );
    final plain = await admin.venues.createVenue(
      name: _kVenuePlain,
      description: _kVenuePlainDescription,
    );
    venueIds.addAll([located.id, plain.id]);

    // Coaches: public with a photo and a bio, public with neither, and one
    // without a public profile.
    coachPhoto = (await seedCoach(
      admin,
      baseUrl: _kApiBaseUrl,
      username: _kCoachFull,
      firstName: _kId,
      lastName: _kCoachFullLast,
      publicProfile: true,
      bio: _kCoachFullBio,
      photo: true,
    ))!;
    await seedCoach(
      admin,
      baseUrl: _kApiBaseUrl,
      username: _kCoachPlain,
      firstName: _kId,
      lastName: _kCoachPlainLast,
      publicProfile: true,
    );
    await seedCoach(
      admin,
      baseUrl: _kApiBaseUrl,
      username: _kCoachPrivate,
      firstName: _kId,
      lastName: _kCoachPrivateLast,
      publicProfile: false,
      bio: _kCoachPrivateBio,
    );

    // Events. No two overlap: they share an organizer, and the server
    // refuses an organizer two events at once. Camps run from 10:00 UTC,
    // one-offs from 14:00 and programmes from 06:00.
    const days = 'FREQ=DAILY;COUNT=';
    const camp = Duration(hours: 2);
    await seedEvent(
      _kCampFeatured,
      EventType.camp,
      venueId: located.id,
      start: dayAt(_kCampFeaturedInDays),
      length: camp,
      rrule: '${days}3',
      featured: true,
      coachNames: [_kCoachFull, _kCoachPrivate],
      shortDescription: _kCampFeaturedTagline,
    );
    await seedEvent(
      _kCampPlain,
      EventType.camp,
      venueId: plain.id,
      start: dayAt(20),
      length: camp,
      rrule: '${days}2',
    );
    await seedEvent(
      _kCampPast,
      EventType.camp,
      venueId: located.id,
      start: dayAt(-30),
      length: camp,
      rrule: '${days}2',
    );
    await seedEvent(
      _kCampPrivate,
      EventType.camp,
      venueId: located.id,
      start: dayAt(40),
      length: camp,
      rrule: '${days}2',
      visibility: Visibility.private,
      featured: true,
    );
    await seedEvent(
      _kCampDeleted,
      EventType.camp,
      venueId: located.id,
      start: dayAt(50),
      length: camp,
      rrule: '${days}2',
      featured: true,
    );
    await admin.events.deleteEvent(eventIds[_kCampDeleted]!);

    final firstProgramme = dayAt(3, hour: 6);
    final secondProgramme = dayAt(4, hour: 6);
    final privateProgramme = dayAt(5, hour: 6);
    await seedEvent(
      _kProgrammeFirst,
      EventType.programme,
      venueId: located.id,
      start: firstProgramme,
      rrule: weeklyOn(firstProgramme),
    );
    await seedEvent(
      _kProgrammeSecond,
      EventType.programme,
      venueId: plain.id,
      start: secondProgramme,
      rrule: weeklyOn(secondProgramme),
    );
    await seedEvent(
      _kProgrammePrivate,
      EventType.programme,
      venueId: located.id,
      start: privateProgramme,
      rrule: weeklyOn(privateProgramme),
      visibility: Visibility.private,
    );

    await seedEvent(
      _kOneOffFeatured,
      EventType.oneOff,
      venueId: located.id,
      start: dayAt(15, hour: 14),
      featured: true,
    );
    await seedEvent(
      _kOneOffPlain,
      EventType.oneOff,
      venueId: plain.id,
      start: dayAt(25, hour: 14),
    );
    await seedEvent(
      _kOneOffPast,
      EventType.oneOff,
      venueId: located.id,
      start: dayAt(-20, hour: 14),
    );
    await seedEvent(
      _kOneOffPrivate,
      EventType.oneOff,
      venueId: located.id,
      start: dayAt(35, hour: 14),
      visibility: Visibility.private,
    );

    if (caps.eventMarketing) {
      await admin.eventMarketing.setEventMarketing(
        eventIds[_kCampFeatured]!,
        const EventMarketing(
          scheduleText: _kMarketingSchedule,
          eligibilityText: _kMarketingEligibility,
          fee: _kMarketingFee,
        ),
        // The event has no marketing block yet.
        version: EventMarketing.unwrittenVersion,
      );
    }
  });

  tearDownAll(() async {
    for (final id in eventIds.values) {
      await removeEvent(admin, id);
    }
    for (final id in venueIds) {
      await removeVenue(admin, id);
    }
    for (final username in coaches) {
      await removeUser(admin, username);
    }

    // The cleanup is checked, not assumed: nothing of this file is left for
    // a visitor to read.
    final events = await admin.public.listPublicEvents(limit: 100);
    expect(_ours(events.items.map((e) => e.title)), isEmpty);
    final venues = await admin.public.listPublicVenues();
    expect(_ours(venues.map((v) => v.name)), isEmpty);
    final staff = await admin.public.listPublicStaff();
    expect(_ours(staff.map((p) => p.displayName)), isEmpty);
    await admin.auth.logout();
  });

  testWidgets('Issue 83: the landing page features the featured events and '
      'only those, and lists the soonest of each type', (tester) async {
    await pumpSite(tester, apiBaseUrl: _kApiBaseUrl);
    expect(find.byType(LandingPage), findsOneWidget);

    // The hero's carousel: the featured public events, by start.
    await waitFor(
      tester,
      () => container(tester).read(publicHighlightsProvider).hasValue,
      description: 'the featured events',
    );
    final highlights = container(
      tester,
    ).read(publicHighlightsProvider).requireValue;
    expect(_ours(highlights.map((h) => h.title)), [
      _kCampFeatured,
      _kOneOffFeatured,
    ]);

    // One slide shows at a time: each featured event has its own.
    final hero = tester.state<HeroSectionState>(find.byType(HeroSection));
    for (final title in [_kCampFeatured, _kOneOffFeatured]) {
      hero.goToPage(highlights.indexWhere((h) => h.title == title));
      await tester.pump();
      await waitFor(
        tester,
        () {
          final cards = tester.widgetList<PublicEventHeroCard>(
            find.byType(PublicEventHeroCard),
          );
          return cards.length == 1 && cards.single.event.title == title;
        },
        description: 'the hero slide of "$title"',
      );
      expect(
        find.descendant(
          of: find.byType(PublicEventHeroCard),
          matching: find.text(title),
        ),
        findsOneWidget,
      );
    }

    // The sections below: the soonest live events of each type.
    await waitFor(
      tester,
      () => find.byType(PublicEventsSection).evaluate().length == 3,
      description: 'the three event sections',
    );
    final sections = {
      for (final section in tester.widgetList<PublicEventsSection>(
        find.byType(PublicEventsSection),
      ))
        section.type: _ours(section.events.map((e) => e.title)),
    };
    expect(sections, {
      EventType.camp: [_kCampFeatured, _kCampPlain],
      EventType.programme: [_kProgrammeFirst, _kProgrammeSecond],
      EventType.oneOff: [_kOneOffFeatured, _kOneOffPlain],
    });

    for (final leftOut in [
      _kCampPrivate,
      _kCampDeleted,
      _kCampPast,
      _kProgrammePrivate,
      _kOneOffPrivate,
      _kOneOffPast,
    ]) {
      expect(find.text(leftOut), findsNothing, reason: leftOut);
    }
  });

  testWidgets('Issue 83: Camps lists the live camps in order, the past one '
      'apart, and no private or deleted camp', (tester) async {
    await _open(tester, '/public/events');
    expect(find.byType(LearningCampsPage), findsOneWidget);
    expect(
      _cardTitles<PublicEventCard>(tester, (c) => c.event),
      [_kCampFeatured, _kCampPlain],
    );
    expect(
      _cardTitles<PublicEventCompactCard>(tester, (c) => c.event),
      [_kCampPast],
    );
    for (final shown in [_kCampFeatured, _kCampPlain, _kCampPast]) {
      expect(find.text(shown), findsWidgets, reason: shown);
    }
    expect(find.text(_kCampFeaturedTagline), findsWidgets);
    for (final leftOut in [_kCampPrivate, _kCampDeleted, _kOneOffFeatured]) {
      expect(find.text(leftOut), findsNothing, reason: leftOut);
    }
  });

  testWidgets('Issue 83: Programmes lists the live programmes in order, and '
      'no private one', (tester) async {
    await _open(tester, '/public/programs');
    expect(find.byType(TrainingSessionsPage), findsOneWidget);
    expect(
      _cardTitles<PublicEventCard>(tester, (c) => c.event),
      [_kProgrammeFirst, _kProgrammeSecond],
    );
    for (final shown in [_kProgrammeFirst, _kProgrammeSecond]) {
      expect(find.text(shown), findsWidgets, reason: shown);
    }
    for (final leftOut in [_kProgrammePrivate, _kCampFeatured]) {
      expect(find.text(leftOut), findsNothing, reason: leftOut);
    }
  });

  testWidgets('Issue 83: One-off lists the live events in order, the past '
      'one apart, and no private one', (tester) async {
    await _open(tester, '/public/one-off');
    expect(find.byType(ClubEventsPage), findsOneWidget);
    expect(
      _cardTitles<PublicEventCard>(tester, (c) => c.event),
      [_kOneOffFeatured, _kOneOffPlain],
    );
    expect(
      _cardTitles<PublicEventCompactCard>(tester, (c) => c.event),
      [_kOneOffPast],
    );
    for (final shown in [_kOneOffFeatured, _kOneOffPlain, _kOneOffPast]) {
      expect(find.text(shown), findsWidgets, reason: shown);
    }
    for (final leftOut in [_kOneOffPrivate, _kCampFeatured]) {
      expect(find.text(leftOut), findsNothing, reason: leftOut);
    }
  });

  testWidgets('Issue 83: a camp page shows its title, dates, venue and '
      'coaches, and no coach without a public profile', (tester) async {
    await _open(tester, '/public/events');
    await _openEventFromCard(tester, _kCampFeatured);

    expect(
      tester.widget<PageHero>(find.byType(PageHero)).data.title,
      _kCampFeatured,
    );
    expect(find.text(_kCampFeatured), findsWidgets);

    final badges = tester
        .widgetList<EventInfoBadge>(find.byType(EventInfoBadge))
        .toList();
    expect(badges.map((b) => b.value), contains(_kVenueLocated));
    expect(find.text(_kVenueLocated), findsWidgets);

    // The dates: the marketing block's own wording where the stack has one,
    // otherwise the range worked out from the camp's first day.
    final dates = badges.firstWhere((b) => b.icon == LucideIcons.calendar);
    if (caps.eventMarketing) {
      expect(dates.value, _kMarketingSchedule);
    } else {
      final firstDay = dayAt(_kCampFeaturedInDays).toLocal();
      expect(dates.value, contains('${firstDay.day}'));
      expect(dates.value, contains('${firstDay.year}'));
    }
    expect(find.text(dates.value), findsWidgets);

    final rows = tester.widgetList<PublicEventCoachRow>(
      find.byType(PublicEventCoachRow),
    );
    expect(rows.map((r) => r.profile.displayName), [_coachFullName]);
    expect(find.text(_coachFullName), findsOneWidget);
    expect(find.text(_coachPrivateName), findsNothing);
    expect(find.textContaining(_kCoachPrivateBio), findsNothing);
  });

  testWidgets('Issue 83: a camp page shows its marketing block where the '
      'stack has event marketing', (tester) async {
    if (skipUnless(enabled: caps.eventMarketing, feature: 'event marketing')) {
      return;
    }
    await _open(tester, '/public/events');
    await _openEventFromCard(tester, _kCampFeatured);

    final fees = tester.widget<PublicEventFeesSection>(
      find.byType(PublicEventFeesSection),
    );
    expect(fees.event.fees, _kMarketingFee);
    expect(find.text(fees.event.formattedFees), findsWidgets);
    expect(find.byType(PublicEventEligibilitySection), findsOneWidget);
    expect(find.textContaining(_kMarketingEligibility), findsWidgets);
  });

  testWidgets('Issue 83: a camp page shows no marketing block where the '
      'stack has no event marketing', (tester) async {
    if (skipIf(enabled: caps.eventMarketing, feature: 'event marketing')) {
      return;
    }
    await _open(tester, '/public/events');
    await _openEventFromCard(tester, _kCampFeatured);

    expect(find.byType(PublicEventDetailContent), findsOneWidget);
    expect(find.byType(PublicEventFeesSection), findsNothing);
    expect(find.byType(PublicEventEligibilitySection), findsNothing);
  });

  testWidgets('Issue 83: Coaches lists the coaches with a public profile, '
      'with name, bio and photo, or the placeholder', (tester) async {
    await _open(tester, '/public/coaches');
    expect(find.byType(IceMastersPage), findsOneWidget);

    final cards = tester.widgetList<CoachCard>(find.byType(CoachCard));
    expect(
      _ours(cards.map((c) => c.coach.displayName)),
      unorderedEquals([_coachFullName, _coachPlainName]),
    );
    expect(find.text(_coachPrivateName), findsNothing);
    expect(find.textContaining(_kCoachPrivateBio), findsNothing);

    // With a photo and a bio: the photo is the uploaded file's public URL.
    final full = find.widgetWithText(CoachCard, _coachFullName);
    expect(full, findsOneWidget);
    final photo = tester.widget<Image>(
      find.descendant(of: full, matching: find.byType(Image)),
    );
    final expectedUrl = const MediaUrlBuilder(
      _kApiBaseUrl,
    )(tester.widget<CoachCard>(full).coach.avatar);
    expect(expectedUrl, contains(coachPhoto.uuid));
    expect((photo.image as NetworkImage).url, expectedUrl);
    expect(
      find.descendant(of: full, matching: find.byType(PlaceholderAvatar)),
      findsNothing,
      reason: 'the photo loaded, so its error placeholder is not showing',
    );
    final bio = tester.widget<ThemedMarkdown>(
      find.descendant(of: full, matching: find.byType(ThemedMarkdown)),
    );
    expect(bio.data, _kCoachFullBio);

    // Without either: the placeholder, and no bio.
    final plain = find.widgetWithText(CoachCard, _coachPlainName);
    expect(plain, findsOneWidget);
    expect(
      find.descendant(of: plain, matching: find.byType(PlaceholderAvatar)),
      findsOneWidget,
    );
    expect(
      find.descendant(of: plain, matching: find.byType(Image)),
      findsNothing,
    );
    expect(
      find.descendant(of: plain, matching: find.byType(ThemedMarkdown)),
      findsNothing,
    );
  });

  testWidgets('Issue 83: Rinks lists each venue, and a venue page shows its '
      'details, with a map only when it has a location', (tester) async {
    await _open(tester, '/public/rinks');
    expect(find.byType(TheRinksPage), findsOneWidget);

    final cards = tester.widgetList<PublicVenueCard>(
      find.byType(PublicVenueCard),
    );
    expect(
      _ours(cards.map((c) => c.venue.name)),
      unorderedEquals([_kVenueLocated, _kVenuePlain]),
    );
    final located = find.widgetWithText(PublicVenueCard, _kVenueLocated);
    expect(located, findsOneWidget);
    expect(
      find.descendant(of: located, matching: find.text(_kVenueLocatedAddress)),
      findsWidgets,
    );
    expect(find.widgetWithText(PublicVenueCard, _kVenuePlain), findsOneWidget);

    // The venue with a location.
    await _openVenueFromCard(tester, _kVenueLocated);
    var hero = tester.widget<PageHero>(find.byType(PageHero)).data;
    expect(hero.title, _kVenueLocated);
    expect(hero.description, _kVenueLocatedAddress);
    expect(find.text(_kVenueLocated), findsWidgets);
    var content = tester.widget<VenueContent>(find.byType(VenueContent));
    expect(content.description, _kVenueLocatedDescription);
    expect(content.mapUri, _kVenueLocatedMap);
    expect(find.byType(MapEmbed), findsOneWidget);

    // The venue without one.
    await go(tester, '/public/rinks');
    await _waitUntilLoaded(tester);
    await _openVenueFromCard(tester, _kVenuePlain);
    hero = tester.widget<PageHero>(find.byType(PageHero)).data;
    expect(hero.title, _kVenuePlain);
    expect(hero.description, isNull);
    content = tester.widget<VenueContent>(find.byType(VenueContent));
    expect(content.description, _kVenuePlainDescription);
    expect(content.mapUri, isNull);
    expect(find.byType(MapEmbed), findsNothing);
  });

  // Last, because it changes what every page reads.
  testWidgets('Issue 83: Contact and About show the club details the server '
      'holds, and the bundled ones once the original is back', (tester) async {
    final bundled = await loadBundledContactInfo();
    final original = (await admin.admin.getPreference(
      ClubIdentity.preferenceKey,
    )).value;

    // Before: the server has no details of its own.
    await _open(tester, '/public/contact-us');
    await _expectContactPhone(tester, bundled.phoneNumber);

    try {
      await admin.admin.setPreference(ClubIdentity.preferenceKey, {
        ...const ClubIdentity(
          name: _kClubName,
          contact: ClubContactDetails(
            phoneNumber: _kClubPhone,
            email: _kClubEmail,
            address: LocalizedText(_kClubAddress),
          ),
        ).toMap(),
        'history': {
          'paragraphs': [_kClubStory],
        },
      });

      // The site, rendered again, reads the new details.
      await _open(tester, '/public/contact-us');
      await _expectContactPhone(tester, _kClubPhone);
      final card = find.byType(ClubContactCard);
      expect(
        find.descendant(of: card, matching: find.text(_kClubEmail)),
        findsWidgets,
      );
      final details = container(tester).read(contactInfoProvider);
      expect(details.addressLine1?.resolve(_kLanguage), _kClubAddress);
      expect(
        find.descendant(
          of: card,
          matching: find.text(details.fullAddress(_kLanguage)),
        ),
        findsOneWidget,
      );
      // The site reads the new name too. No page of the site prints the
      // server's name (the footer's is the host's club.json), so this is
      // checked on what the contact card reads.
      expect(details.clubName, _kClubName);

      await go(tester, '/public/about-us');
      await waitFor(
        tester,
        () =>
            tester
                .widget<HistoryContent>(find.byType(HistoryContent))
                .data
                .text ==
            _kClubStory,
        description: "the server's story on About",
      );
    } finally {
      // A never-written club_info reads null, which the server will not
      // store; an empty object reads the same.
      await admin.admin.setPreference(
        ClubIdentity.preferenceKey,
        original ?? const <String, dynamic>{},
      );
    }

    // After: the defaults are back in place.
    await _open(tester, '/public/contact-us');
    await _expectContactPhone(tester, bundled.phoneNumber);
    expect(find.text(_kClubPhone), findsNothing);
    await go(tester, '/public/about-us');
    expect(
      tester.widget<HistoryContent>(find.byType(HistoryContent)).data.text,
      SiteCopy(
        container(tester).read(siteStringsProvider).requireValue,
      ).clubInfo.history.text,
    );
  });
}
