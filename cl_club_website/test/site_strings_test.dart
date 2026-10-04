import 'package:cl_club_website/cl_club_website.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Issue 52: SiteStrings', () {
    test('Issue 52: fromArb keeps string entries and drops metadata', () {
      final strings = SiteStrings.fromArb({
        '@@locale': 'en',
        'navHome': 'Home',
        '@navHome': {'description': 'Nav label'},
        'navMenu': 42,
      });

      expect(strings.navHome, 'Home');
      // Not a string, so not read: renders as its key.
      expect(strings.navMenu, 'navMenu');
    });

    test('Issue 52: a key the ARB lacks renders as the key itself', () {
      expect(SiteStrings(const {}).navHome, 'navHome');
    });

    test('Issue 52: placeholders are filled', () {
      final strings = SiteStrings(const {
        'campCtaAvailableDescription': 'Register before {deadline} to join',
      });

      expect(
        strings.campCtaAvailableDescription('1 May'),
        'Register before 1 May to join',
      );
    });

    test('Issue 52: keys lists every getter once', () {
      expect(SiteStrings.keys.toSet(), hasLength(SiteStrings.keys.length));
      expect(SiteStrings.keys, contains('navHome'));
    });
  });
}
