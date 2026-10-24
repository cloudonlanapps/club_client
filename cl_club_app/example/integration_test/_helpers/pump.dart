// Pump / wait infrastructure for integration tests.
//
// Owns:
//   * pumpApp     — mounts App under a ProviderScope with the test-server
//                   base URL and in-memory storage stubs (no keychain bleed).
//   * settle      — pump-and-settle that swallows the "still pumping" timeout
//                   so a slow async chain doesn't fail the whole test.
//   * waitFor     — busy-wait predicate with a description for diagnostics.
//   * tapVisible  — scrolls [finder] into view, then taps it.
//   * waitForInList — waitFor an item of a lazy list, scrolling the list to
//                   it (a phone-sized screen builds only what it shows).
//   * InMemory*Storage — token/credential storage doubles.
//
// Extracted from workflow1 so workflow5+ can share without copy-paste.

import 'package:cl_club_app/cl_club_app.dart';
import 'package:cl_club_branding/cl_club_branding.dart' show appLogoUriProvider;
import 'package:cl_member_auth/cl_member_auth.dart'
    show
        AuthSession,
        CredentialStorage,
        TokenStorage,
        apiHttpClientProvider,
        authStateProvider,
        clientProvider,
        credentialStorageProvider,
        sessionClientProvider,
        tokenStorageProvider;
import 'package:cl_member_auth/src/providers/credential_storage.dart'
    show SavedCredential;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        bundledContactInfoProvider,
        clubEventTypesProvider,
        currentUserProvider,
        secureClientProvider,
        tokenFreeClientProvider;
import 'package:cl_remote_store/src/providers/public_source.dart'
    show clPublicSourceProvider;
import 'package:cl_server_config/cl_server_config.dart';
import 'package:club_sdk_2/club_sdk_2.dart' show SecureClient;
import 'package:club_sdk_2/remote_store.dart'
    show RemoteStore, createRemotePublicSource, createRemoteSecureClient;
import 'package:club_sdk_2/remote_store/http/default_http_client.dart'
    show createDefaultHttpClient;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;

/// Mounts [App] under a [ProviderScope] preconfigured for the integration
/// test stack: the supplied [apiBaseUrl] (typically the port-8155 test
/// server), an authenticated client wired through Riverpod, and in-memory
/// token/credential storage so the test never auto-logs-in from a previous
/// session and never has to share state with the host machine.
///
/// Pass [extraOverrides] when a specific test needs to layer additional
/// provider overrides on top — they are appended after the defaults so they
/// can replace any of them.
Future<void> pumpApp(
  WidgetTester tester, {
  required String apiBaseUrl,
  List<Override> extraOverrides = const [],
}) async {
  // The app normally gets its config from clubMain(), which these tests bypass
  // by mounting App directly. Load the real assets/club.json rather than
  // fabricating one, so the tests exercise the config this club actually ships.
  // The same for the bundled contact details.
  final config = await ClubConfig.load();
  final contact = await loadBundledContactInfo();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clubConfigProvider.overrideWithValue(config),
        clubEventTypesProvider.overrideWithValue(config.eventTypes),
        bundledContactInfoProvider.overrideWithValue(contact),
        serverConfigProvider.overrideWithValue(
          ServerConfig(baseUrl: apiBaseUrl),
        ),
        secureClientProvider.overrideWith(
          (ref) => ref.watch(sessionClientProvider.future),
        ),
        tokenFreeClientProvider.overrideWith(
          (ref) => ref.watch(clientProvider.future),
        ),
        currentUserProvider.overrideWith(
          (ref) => ref.watch(authStateProvider).valueOrNull,
        ),
        apiHttpClientProvider.overrideWithValue(_uncachedHttp),
        clPublicSourceProvider.overrideWithValue(
          createRemotePublicSource(
            baseUrl: apiBaseUrl,
            store: RemoteStore(baseUrl: apiBaseUrl, client: _uncachedHttp),
          ),
        ),
        tokenStorageProvider.overrideWithValue(InMemoryTokenStorage()),
        credentialStorageProvider.overrideWithValue(
          InMemoryCredentialStorage(),
        ),
        // Mirror `app/lib/main.dart`'s logo override so widgets that pull
        // from `appLogoUriProvider` don't fail trying to load the
        // non-existent default `placeholder_logo.png` asset (which Flutter
        // surfaces as an unhandled image-codec exception that fails the
        // test even when every assertion passes).
        appLogoUriProvider.overrideWithValue(
          Uri.parse('asset:assets/images/club_logo.png'),
        ),
        ...extraOverrides,
      ],
      child: const App(),
    ),
  );
  await settle(tester);
}

class InMemoryTokenStorage implements TokenStorage {
  AuthSession? _session;
  @override
  Future<AuthSession?> read() async => _session;
  @override
  Future<void> write(AuthSession session) async => _session = session;
  @override
  Future<void> clear() async => _session = null;
}

class InMemoryCredentialStorage implements CredentialStorage {
  SavedCredential? _credential;
  @override
  Future<SavedCredential?> read() async => _credential;
  @override
  Future<void> write({
    required String username,
    required String password,
  }) async {
    _credential = SavedCredential(
      username: username,
      password: password,
      savedAtUtc: DateTime.now().toUtc(),
    );
  }

  @override
  Future<void> clear() async => _credential = null;
}

/// pumpAndSettle wrapped to swallow the framework's "still pumping" timeout
/// — long async chains (login + redirect + master-provider warm-up) can
/// legitimately exceed the default settle window without indicating a
/// hang. On timeout we pump one more frame and return.
Future<void> settle(WidgetTester tester) async {
  try {
    await tester.pumpAndSettle(
      const Duration(milliseconds: 250),
      EnginePhase.sendSemanticsUpdate,
      const Duration(seconds: 15),
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

/// Waits until [item] is built inside [within], scrolling the vertical lists
/// in [within] a screen at a time until it is. A lazy list builds only the
/// rows it shows, so on a phone-sized screen a row below the fold never
/// appears to a plain [waitFor] (club_client#291). When a list reaches its
/// end without the item it starts again from the top, since the rows may
/// still be loading. Once found, the item is scrolled into view.
Future<void> waitForInList(
  WidgetTester tester,
  Finder item, {
  required Finder within,
  required String description,
  Duration timeout = const Duration(seconds: 30),
}) async {
  await waitFor(
    tester,
    () {
      if (item.evaluate().isNotEmpty) return true;
      final lists = find.descendant(
        of: within,
        matching: find.byWidgetPredicate(
          (w) => w is Scrollable && w.axisDirection == AxisDirection.down,
        ),
      );
      for (final element in lists.evaluate()) {
        if (element is! StatefulElement) continue;
        final state = element.state;
        if (state is! ScrollableState) continue;
        final position = state.position;
        if (!position.hasContentDimensions) continue;
        if (position.maxScrollExtent <= 0) continue;
        final next = position.pixels >= position.maxScrollExtent
            ? 0.0
            : (position.pixels + position.viewportDimension * 0.8).clamp(
                0.0,
                position.maxScrollExtent,
              );
        position.jumpTo(next);
      }
      return false;
    },
    description: description,
    timeout: timeout,
  );
  final context = item.evaluate().first;
  await Scrollable.ensureVisible(context);
  await tester.pump();
}

/// The server lets a browser keep a public read for five minutes
/// (club_server#297), so in Chrome a test that changes what the server holds
/// would read the old answer back. Each GET gets a query parameter of its
/// own, which the server ignores and no cache has seen (club_client#291).
///
/// It wraps the SDK's own client, which drops an idle connection before the
/// server does: a plain `http.Client()` keeps one 15 s, past uvicorn's 5 s,
/// and on the Android phone (through `adb reverse`) a request written onto
/// it never reaches the server (club_client#305).
///
/// Every request also asks for its connection to be closed after it. adb
/// relays a connection separately on the phone and on the laptop, so a
/// reused one can be closed under a request even within the idle timeout,
/// and Dart does not retry it (club_client#310). The browser ignores this.
final http.Client _uncachedHttp = _UncachedClient(createDefaultHttpClient());

class _UncachedClient extends http.BaseClient {
  _UncachedClient(this._inner);

  final http.Client _inner;
  int _count = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (request.method != 'GET') {
      return _inner.send(request..persistentConnection = false);
    }
    final url = request.url.replace(
      queryParameters: {
        ...request.url.queryParametersAll,
        '_test_nocache': '${DateTime.now().microsecondsSinceEpoch}-${_count++}',
      },
    );
    final copy = http.Request('GET', url)
      ..headers.addAll(request.headers)
      ..followRedirects = request.followRedirects
      ..maxRedirects = request.maxRedirects
      ..persistentConnection = false;
    return _inner.send(copy);
  }
}

/// Scrolls [finder] into view, then taps it. A tap lands where the widget is
/// drawn, so on a phone-sized screen a widget below the fold takes no tap
/// (club_client#291); on a wide one the scroll does nothing.
Future<void> tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
}

/// A test's own SDK client, for setup and for reading back what the server
/// holds. It shares the pages' cache-busting HTTP client, so in Chrome it
/// never reads an answer the browser kept (club_client#291).
Future<SecureClient> createTestClient({required String baseUrl}) =>
    createRemoteSecureClient(
      baseUrl: baseUrl,
      store: RemoteStore(baseUrl: baseUrl, client: _uncachedHttp),
    );
