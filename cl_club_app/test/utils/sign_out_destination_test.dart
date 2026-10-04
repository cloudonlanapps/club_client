import 'package:cl_club_app/src/utils/configured_uri.dart';
import 'package:cl_club_app/src/utils/sign_out_destination.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Issue 179: configuredUri', () {
    test('Issue 179: the build override wins over the config', () {
      expect(
        configuredUri(
          override: 'https://beta.example.test',
          configured: 'https://example.test',
        ),
        Uri.parse('https://beta.example.test'),
      );
    });

    test('Issue 179: without an override the config is used', () {
      expect(
        configuredUri(override: '', configured: 'https://example.test'),
        Uri.parse('https://example.test'),
      );
    });

    test('Issue 179: neither means none', () {
      expect(configuredUri(override: '', configured: null), isNull);
    });
  });

  group('Issue 179: signOutDestination', () {
    final site = Uri.parse('https://example.test');

    test('Issue 179: on web, signing out goes to the website', () {
      expect(signOutDestination(site, isWeb: true), site);
    });

    test('Issue 179: off the web, signing out stays in the app', () {
      expect(signOutDestination(site, isWeb: false), isNull);
    });

    test('Issue 179: without a website, signing out stays in the app', () {
      expect(signOutDestination(null, isWeb: true), isNull);
    });
  });
}
