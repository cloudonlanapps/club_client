import 'package:cl_club_website/cl_club_website.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Issue 52: SiteConfig.fromJson', () {
    Map<String, dynamic> config({Map<String, dynamic>? map}) => {
      'fullName': 'Test Club',
      'shortName': 'TC',
      'apiBaseUrl': 'https://api.example.test/v1',
      'map': ?map,
    };

    test('Issue 52: reads the club apps keys', () {
      final c = SiteConfig.fromJson(config());

      expect(c.fullName, 'Test Club');
      expect(c.shortName, 'TC');
      expect(c.apiBaseUrl, 'https://api.example.test/v1');
      expect(c.map.hasEmbed, isFalse);
    });

    test('Issue 52: joins the map embed and link as MapEmbed expects', () {
      final c = SiteConfig.fromJson(
        config(
          map: {
            'title': 'The Rink',
            'embedUrl': 'https://maps.example.test/embed',
            'linkUrl': 'https://maps.example.test/link',
          },
        ),
      );

      expect(
        c.map.mapUri,
        'https://maps.example.test/embed|https://maps.example.test/link',
      );
      expect(c.map.fallbackTitle, 'The Rink');
    });

    test('Issue 52: a missing required key is a FormatException', () {
      expect(
        () => SiteConfig.fromJson(config()..remove('fullName')),
        throwsFormatException,
      );
    });
  });

  group('Issue 179: SiteConfig memberAppUrl', () {
    Map<String, dynamic> config([Map<String, dynamic> extra = const {}]) => {
      'fullName': 'Test Club',
      'shortName': 'TC',
      'apiBaseUrl': 'https://api.example.test/v1',
      ...extra,
    };

    test('Issue 179: absent means no member app link', () {
      expect(SiteConfig.fromJson(config()).memberAppUrl, isNull);
    });

    test('Issue 179: empty means no member app link', () {
      expect(
        SiteConfig.fromJson(config({'memberAppUrl': ''})).memberAppUrl,
        isNull,
      );
    });

    test('Issue 179: a memberAppUrl is read', () {
      expect(
        SiteConfig.fromJson(
          config({'memberAppUrl': 'https://member.example.test'}),
        ).memberAppUrl,
        'https://member.example.test',
      );
    });
  });
}
