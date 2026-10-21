import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('Issue 496: returns empty headers when no session is stored', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final headers = await container.read(imageAuthHeadersProvider.future);
    expect(headers, isEmpty);
  });

  test(
    'Issue 496: returns Bearer Authorization when session is present',
    () async {
      final session = AuthSession(
        accessToken: 'tok-123',
        expiresAtUtc: DateTime.now().toUtc().add(const Duration(hours: 1)),
      );
      SharedPreferences.setMockInitialValues({
        'cl_member_auth.session': session.toJson(),
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final headers = await container.read(imageAuthHeadersProvider.future);
      expect(headers, {'Authorization': 'Bearer tok-123'});
    },
  );

  test(
    'Issue 496: returns empty when access token is the empty string',
    () async {
      final session = AuthSession(
        accessToken: '',
        expiresAtUtc: DateTime.now().toUtc().add(const Duration(hours: 1)),
      );
      SharedPreferences.setMockInitialValues({
        'cl_member_auth.session': session.toJson(),
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      final headers = await container.read(imageAuthHeadersProvider.future);
      expect(headers, isEmpty);
    },
  );

  test('Issue 205: a new session token reaches the headers once the token '
      'expiry moves (a refresh, a new sign-in)', () async {
    SharedPreferences.setMockInitialValues({
      'cl_member_auth.session': AuthSession(
        accessToken: 'a',
        expiresAtUtc: DateTime.utc(2026, 10, 21, 10),
      ).toJson(),
    });
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // Kept alive, as the image widgets watching it keep it.
    final sub = container.listen(imageAuthHeadersProvider, (_, _) {});
    addTearDown(sub.close);
    expect(await container.read(imageAuthHeadersProvider.future), {
      'Authorization': 'Bearer a',
    });

    final refreshed = AuthSession(
      accessToken: 'b',
      expiresAtUtc: DateTime.utc(2026, 10, 21, 10, 30),
    );
    await container.read(tokenStorageProvider).write(refreshed);
    container.read(tokenExpiryProvider.notifier).state = refreshed.expiresAtUtc;

    expect(await container.read(imageAuthHeadersProvider.future), {
      'Authorization': 'Bearer b',
    });
  });

  test('Issue 205: another signed-in user rebuilds the headers, even with '
      'the same token expiry', () async {
    final expiry = DateTime.utc(2026, 10, 21, 10);
    SharedPreferences.setMockInitialValues({
      'cl_member_auth.session': AuthSession(
        accessToken: 'asha-token',
        expiresAtUtc: expiry,
      ).toJson(),
    });
    final container = ProviderContainer(
      overrides: [authStateProvider.overrideWith(_SignedIn.new)],
    );
    addTearDown(container.dispose);
    final sub = container.listen(imageAuthHeadersProvider, (_, _) {});
    addTearDown(sub.close);
    await container.read(authStateProvider.future);
    expect(await container.read(imageAuthHeadersProvider.future), {
      'Authorization': 'Bearer asha-token',
    });

    await container
        .read(tokenStorageProvider)
        .write(AuthSession(accessToken: 'ravi-token', expiresAtUtc: expiry));
    container.read(authStateProvider.notifier).setUser(_user('ravi'));

    expect(await container.read(imageAuthHeadersProvider.future), {
      'Authorization': 'Bearer ravi-token',
    });
  });
}

UserPrivate _user(String username) => UserPrivate(
  username: username,
  displayName: username,
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(),
  createdAtUtc: DateTime.utc(2024),
);

class _SignedIn extends AuthNotifier {
  @override
  Future<UserPrivate?> build() async => _user('asha');
}
