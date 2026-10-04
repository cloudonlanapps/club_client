import 'dart:convert';

import 'package:cl_club_branding/cl_club_branding.dart'
    show ClubBranding, ClubHeroSurface;
import 'package:cl_remote_store/cl_remote_store.dart' show ContactInfo;
import 'package:club_sdk_2/club_sdk_2.dart' show EventType;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

/// Everything that differs between one club's app and another's.
///
/// The two apps were previously identical Dart apart from six values spread
/// across `main.dart` and `app.dart`. Those values live here instead, in an
/// asset each club ships, so adding a configurable field never touches a club
/// repo again — and the app code has nothing club-specific left in it.
@immutable
class ClubConfig {
  const ClubConfig({
    required this.fullName,
    required this.shortName,
    required this.themeColorName,
    required this.heroSurface,
    required this.apiBaseUrl,
    this.eventTypes = kDefaultClubEventTypes,
    this.websiteUrl,
  });

  factory ClubConfig.fromMap(Map<String, dynamic> map) {
    final themeColorName = map['themeColorName'] as String?;
    if (themeColorName == null || themeColorName.isEmpty) {
      throw const FormatException('club config: themeColorName is required');
    }
    if (!kShadColorSchemeNames.contains(themeColorName)) {
      throw FormatException(
        'club config: themeColorName "$themeColorName" is not a shadcn colour '
        'scheme. Valid names: ${kShadColorSchemeNames.join(', ')}.',
      );
    }
    final heroSurface = map['heroSurface'] as String?;
    final surface = ClubHeroSurface.values
        .where((v) => v.name == heroSurface)
        .firstOrNull;
    if (surface == null) {
      throw FormatException(
        'club config: heroSurface must be one of '
        '${ClubHeroSurface.values.map((v) => v.name).join(', ')}, '
        'got "$heroSurface".',
      );
    }
    return ClubConfig(
      fullName: _required(map, 'fullName'),
      shortName: _required(map, 'shortName'),
      themeColorName: themeColorName,
      heroSurface: surface,
      apiBaseUrl: _required(map, 'apiBaseUrl'),
      eventTypes: parseEventTypes(map['eventTypes']),
      websiteUrl: switch (map['websiteUrl']) {
        final String url when url.isNotEmpty => url,
        _ => null,
      },
    );
  }

  factory ClubConfig.fromJson(String source) =>
      ClubConfig.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Reads the config the running app ships at [kClubConfigAsset].
  ///
  /// The path is a convention rather than a parameter: every club app puts its
  /// config in the same place, so `clubMain()` needs no arguments and each
  /// club's `main.dart` is identical.
  static Future<ClubConfig> load() async =>
      ClubConfig.fromJson(await rootBundle.loadString(kClubConfigAsset));

  /// Reads `eventTypes`: a non-empty list of names from
  /// [kConfigurableEventTypes]. Absent means [kDefaultClubEventTypes];
  /// anything else malformed is an error, like the other fields.
  static Set<EventType> parseEventTypes(Object? raw) {
    if (raw == null) return kDefaultClubEventTypes;
    if (raw is! List || raw.isEmpty) {
      throw const FormatException(
        'club config: eventTypes must be a non-empty list',
      );
    }
    return {
      for (final name in raw)
        kConfigurableEventTypes.where((t) => t.name == name).firstOrNull ??
            (throw FormatException(
              'club config: eventTypes entry "$name" is not one of '
              '${kConfigurableEventTypes.map((t) => t.name).join(', ')}.',
            )),
    };
  }

  static String _required(Map<String, dynamic> map, String key) {
    final value = map[key] as String?;
    if (value == null || value.isEmpty) {
      throw FormatException('club config: $key is required');
    }
    return value;
  }

  /// Full organisation name — window title, splash screen.
  final String fullName;

  /// Short brand mark — auth shell, footer copyright.
  final String shortName;

  /// Name of the shadcn colour scheme this club uses, e.g. `blue`.
  ///
  /// Validated on load against [kShadColorSchemeNames]: a typo here would
  /// otherwise surface as a silently wrong theme rather than an error.
  final String themeColorName;

  /// Which theme surface the auth hero is painted in.
  final ClubHeroSurface heroSurface;

  /// API base URL, e.g. `https://api.example.in/v1`.
  final String apiBaseUrl;

  /// The event types this club runs; staff see lists and feeds for these
  /// only (club_core#115).
  final Set<EventType> eventTypes;

  /// The club's public website, e.g. `https://example.in`; null when the
  /// club has none. On the web, signing out goes there (club_core#179).
  final String? websiteUrl;

  ClubBranding get branding => ClubBranding(
    fullName: fullName,
    shortName: shortName,
    heroSurface: heroSurface,
  );

  Map<String, dynamic> toMap() => {
    'fullName': fullName,
    'shortName': shortName,
    'themeColorName': themeColorName,
    'heroSurface': heroSurface.name,
    'apiBaseUrl': apiBaseUrl,
    'eventTypes': [for (final t in eventTypes) t.name],
    'websiteUrl': ?websiteUrl,
  };

  String toJson() => json.encode(toMap());

  @override
  String toString() =>
      'ClubConfig(fullName: $fullName, shortName: $shortName, '
      'themeColorName: $themeColorName, heroSurface: ${heroSurface.name}, '
      'apiBaseUrl: $apiBaseUrl, '
      'eventTypes: ${eventTypes.map((t) => t.name).join(',')}, '
      'websiteUrl: $websiteUrl)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ClubConfig &&
          other.fullName == fullName &&
          other.shortName == shortName &&
          other.themeColorName == themeColorName &&
          other.heroSurface == heroSurface &&
          other.apiBaseUrl == apiBaseUrl &&
          setEquals(other.eventTypes, eventTypes) &&
          other.websiteUrl == websiteUrl);

  @override
  int get hashCode => Object.hash(
    fullName,
    shortName,
    themeColorName,
    heroSurface,
    apiBaseUrl,
    Object.hashAllUnordered(eventTypes),
    websiteUrl,
  );
}

/// Where every club app keeps its config. A convention, not a parameter.
const kClubConfigAsset = 'assets/club.json';

/// The event types of a club whose config names none: camps alone.
const kDefaultClubEventTypes = <EventType>{EventType.camp};

/// The event types a club may list in `eventTypes` (#115, #122).
const kConfigurableEventTypes = <EventType>[
  EventType.camp,
  EventType.programme,
  EventType.oneOff,
];

/// Where every club app keeps its logo.
const kClubLogoAsset = 'assets/images/club_logo.png';

/// Where every club app keeps its contact details — the website's path too.
const String kClubContactAsset = ContactInfo.bundledAsset;

/// Colour scheme names `ShadColorScheme.fromName` accepts.
///
/// Duplicated from shadcn_ui because it exposes no list to validate against,
/// and an unknown name there yields a wrong theme rather than an error.
const kShadColorSchemeNames = <String>{
  'blue',
  'gray',
  'green',
  'neutral',
  'orange',
  'red',
  'rose',
  'slate',
  'stone',
  'violet',
  'yellow',
  'zinc',
};
