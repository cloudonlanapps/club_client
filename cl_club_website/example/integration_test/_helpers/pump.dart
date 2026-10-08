// Pump / navigate / wait infrastructure for the website's integration tests.
//
// Owns:
//   * pumpSite  - mounts the site's App under a ProviderScope, as
//                 websiteMain() does, with the test server's base URL.
//   * container - the provider container of the mounted site.
//   * go        - opens a URL of the site, as a visitor following a link
//                 or typing an address does.
//   * settle    - pump-and-settle that swallows the "still pumping" timeout.
//   * waitFor   - busy-wait predicate with a description for diagnostics.
//
// The same shape as cl_club_app/example/integration_test/_helpers/pump.dart.

import 'package:cl_club_website/cl_club_website.dart';
// App and its router are not part of the package's API: only websiteMain()
// mounts them, and these tests stand in for it.
import 'package:cl_club_website/src/site/app.dart' show App;
import 'package:cl_club_website/src/site/router.dart' show routerProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show bundledContactInfoProvider;
import 'package:cl_server_config/cl_server_config.dart';
import 'package:flutter/widgets.dart' show SizedBox;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:media_kit/media_kit.dart';

/// Mounts the site against [apiBaseUrl], the way `websiteMain()` runs it: the
/// host's real `assets/club.json` and `assets/data/contact_info.json`, and
/// `serverConfigProvider` only. No `secureClientProvider` and no session: a
/// visitor has none, so every read goes through the sessionless client.
///
/// The site starts on the landing page, as it does for a visitor; pass
/// [location] to open another address once it is up. Calling it again in one
/// test renders the site afresh, with nothing kept from the first time.
///
/// Pass [extraOverrides] to layer provider overrides on top; they come after
/// the defaults, so they can replace any of them.
Future<void> pumpSite(
  WidgetTester tester, {
  required String apiBaseUrl,
  String location = landingLocation,
  List<Override> extraOverrides = const [],
}) async {
  MediaKit.ensureInitialized();
  final config = await SiteConfig.load();
  final contact = await loadBundledContactInfo();
  // The container outlives the widget tree, as it does on the web, where the
  // site is never unmounted. The landing page resets the navbar from a
  // microtask when it leaves the tree (LandingPageState.deactivate); with a
  // ProviderScope that owns its container, a test that ends on the landing
  // page has that microtask write to a disposed provider and fails after
  // every assertion has passed.
  final scope = ProviderContainer(
    overrides: [
      siteConfigProvider.overrideWithValue(config),
      serverConfigProvider.overrideWithValue(ServerConfig(baseUrl: apiBaseUrl)),
      bundledContactInfoProvider.overrideWithValue(contact),
      ...extraOverrides,
    ],
  );
  // A test that fails leaves its site mounted. Take it down before the
  // container goes, so that microtask still finds its providers, and the
  // failure stays with the test that failed.
  addTearDown(() async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    scope.dispose();
  });
  // Take down a site an earlier call mounted first: the router's navigator
  // has a global key, which must not move from the old tree into the new.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pumpWidget(
    UncontrolledProviderScope(container: scope, child: const App()),
  );
  // The landing page's carousel animates for as long as it shows, so it
  // never settles: wait for the site's copy, then leave it or settle briefly.
  await waitFor(
    tester,
    () => scope.read(siteStringsProvider).hasValue,
    description: "the site's copy",
  );
  if (location == landingLocation) {
    await settle(tester, timeout: const Duration(seconds: 3));
  } else {
    await go(tester, location);
  }
}

/// The address of the landing page.
const landingLocation = '/';

/// The provider container of the mounted site.
ProviderContainer container(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(App)));

/// Opens [location]. Every page of a website has an address a visitor can
/// open directly, so this is a user-facing path for a listing or a content
/// page. A detail page is addressed by an id only the server knows: reach it
/// by tapping its card.
///
/// Reads the router from the provider container, because the router lives
/// below `App` in the widget tree.
Future<void> go(WidgetTester tester, String location) async {
  container(tester).read(routerProvider).go(location);
  await settle(tester);
}

/// The address the router is showing.
String currentLocation(WidgetTester tester) => container(
  tester,
).read(routerProvider).routerDelegate.currentConfiguration.uri.toString();

/// pumpAndSettle wrapped to swallow the framework's "still pumping" timeout:
/// a page that keeps animating (the landing hero's carousel) never settles
/// without that indicating a hang. On timeout we pump one more frame and
/// return.
Future<void> settle(
  WidgetTester tester, {
  Duration timeout = const Duration(seconds: 15),
}) async {
  try {
    await tester.pumpAndSettle(
      const Duration(milliseconds: 250),
      EnginePhase.sendSemanticsUpdate,
      timeout,
    );
  } on Object catch (_) {
    await tester.pump(const Duration(seconds: 1));
  }
}

/// Polls [predicate] until it returns true or [timeout] elapses. The
/// [description] surfaces in the failure message so a flake is debuggable
/// from the run log alone.
Future<void> waitFor(
  WidgetTester tester,
  bool Function() predicate, {
  required String description,
  Duration timeout = const Duration(seconds: 20),
  Duration interval = const Duration(milliseconds: 200),
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (predicate()) return;
    await tester.pump(interval);
  }
  throw TestFailure('Timed out waiting for: $description');
}
