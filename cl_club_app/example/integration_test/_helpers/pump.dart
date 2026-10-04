// Pump / wait infrastructure for integration tests.
//
// Owns:
//   * pumpApp     — mounts App under a ProviderScope with the test-server
//                   base URL and in-memory storage stubs (no keychain bleed).
//   * settle      — pump-and-settle that swallows the "still pumping" timeout
//                   so a slow async chain doesn't fail the whole test.
//   * waitFor     — busy-wait predicate with a description for diagnostics.
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
        authStateProvider,
        clientProvider,
        credentialStorageProvider,
        tokenStorageProvider;
import 'package:cl_member_auth/src/providers/credential_storage.dart'
    show SavedCredential;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        bundledContactInfoProvider,
        clubEventTypesProvider,
        currentUserProvider,
        secureClientProvider;
import 'package:cl_server_config/cl_server_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

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
          (ref) => ref.watch(clientProvider.future),
        ),
        currentUserProvider.overrideWith(
          (ref) => ref.watch(authStateProvider).valueOrNull,
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
