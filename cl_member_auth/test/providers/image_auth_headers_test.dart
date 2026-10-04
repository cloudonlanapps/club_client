import 'package:cl_member_auth/cl_member_auth.dart';
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
}
