import 'package:cl_club_app/cl_club_app.dart';
import 'package:club_sdk_2/club_sdk_2.dart' show EventType;
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> _config([Map<String, dynamic> extra = const {}]) => {
  'fullName': 'Example Club',
  'shortName': 'EXC',
  'themeColorName': 'blue',
  'heroSurface': 'primary',
  'apiBaseUrl': 'http://localhost:8000/v1',
  ...extra,
};

void main() {
  group('Issue 144: club.json websiteBaseUrl', () {
    test('Issue 144: a config without websiteBaseUrl loads', () {
      final config = ClubConfig.fromMap(_config());
      expect(config.apiBaseUrl, 'http://localhost:8000/v1');
      expect(config.toMap().containsKey('websiteBaseUrl'), isFalse);
    });

    test('Issue 144: a websiteBaseUrl still present is ignored', () {
      final config = ClubConfig.fromMap(
        _config({'websiteBaseUrl': 'http://localhost:8000'}),
      );
      expect(config, ClubConfig.fromMap(_config()));
      expect(config.toMap().containsKey('websiteBaseUrl'), isFalse);
    });
  });

  group('Issue 179: club.json websiteUrl', () {
    test('Issue 179: absent means the club has no website', () {
      final config = ClubConfig.fromMap(_config());
      expect(config.websiteUrl, isNull);
      expect(config.toMap().containsKey('websiteUrl'), isFalse);
    });

    test('Issue 179: an empty websiteUrl is no website', () {
      expect(
        ClubConfig.fromMap(_config({'websiteUrl': ''})).websiteUrl,
        isNull,
      );
    });

    test('Issue 179: a websiteUrl is read and round-trips', () {
      final config = ClubConfig.fromMap(
        _config({'websiteUrl': 'https://example.test'}),
      );
      expect(config.websiteUrl, 'https://example.test');
      expect(ClubConfig.fromMap(config.toMap()), config);
      expect(config, isNot(ClubConfig.fromMap(_config())));
    });
  });

  group('Issue 115: club.json eventTypes', () {
    test('Issue 115: absent means camps only', () {
      expect(ClubConfig.fromMap(_config()).eventTypes, {EventType.camp});
      expect(kDefaultClubEventTypes, {EventType.camp});
    });

    test('Issue 115: a club may run camps and programmes', () {
      final config = ClubConfig.fromMap(
        _config({
          'eventTypes': ['camp', 'programme'],
        }),
      );
      expect(config.eventTypes, {EventType.camp, EventType.programme});
    });

    test('Issue 122: a club may run one-off events too', () {
      final config = ClubConfig.fromMap(
        _config({
          'eventTypes': ['camp', 'programme', 'oneOff'],
        }),
      );
      expect(config.eventTypes, EventType.values.toSet());
    });

    test('Issue 115: survives a round trip through toMap', () {
      final config = ClubConfig.fromMap(
        _config({
          'eventTypes': ['programme'],
        }),
      );
      expect(ClubConfig.fromMap(config.toMap()), config);
    });

    for (final bad in <Object>[
      <String>[],
      'camp',
      ['camp', 'workshop'],
    ]) {
      test('Issue 115: refuses eventTypes $bad', () {
        expect(
          () => ClubConfig.fromMap(_config({'eventTypes': bad})),
          throwsFormatException,
        );
      });
    }
  });
}
