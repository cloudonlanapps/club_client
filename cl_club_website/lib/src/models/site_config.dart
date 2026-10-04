import 'dart:convert';

import 'package:cl_remote_store/cl_remote_store.dart' show ContactInfo;
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'contact_map_config.dart';

/// The host's club identity: the same file, at the same path, as the club
/// apps ship (`cl_club_app`'s `ClubConfig`), plus the website's own `map`.
const kSiteConfigAsset = 'assets/club.json';

/// How to reach the club, in the club apps' `contact_info.json` shape.
const String kContactInfoAsset = ContactInfo.bundledAsset;

/// The club's logo, at the path the club apps use.
const kClubLogoAsset = 'assets/images/club_logo.png';

/// The Instagram mark, if the host ships one. Brand marks are the club's to
/// license, so the package ships none and falls back to an icon.
const kInstagramMarkAsset = 'assets/images/instagram.png';

/// Who the site is for. Read once, before the first frame, by `websiteMain`.
class SiteConfig {
  const SiteConfig({
    required this.fullName,
    required this.shortName,
    required this.apiBaseUrl,
    required this.map,
    this.memberAppUrl,
  });

  factory SiteConfig.fromJson(Map<String, dynamic> json) {
    String required(String key) {
      final value = json[key];
      if (value is String && value.isNotEmpty) return value;
      throw FormatException('$kSiteConfigAsset: "$key" is missing');
    }

    final map = json['map'];
    final memberAppUrl = json['memberAppUrl'];
    return SiteConfig(
      fullName: required('fullName'),
      shortName: required('shortName'),
      apiBaseUrl: required('apiBaseUrl'),
      map: map is Map
          ? ContactMapConfig(
              mapUri: [
                map['embedUrl'],
                map['linkUrl'],
              ].whereType<String>().where((s) => s.isNotEmpty).join('|'),
              fallbackTitle: map['title'] as String?,
            )
          : const ContactMapConfig(mapUri: ''),
      memberAppUrl: memberAppUrl is String && memberAppUrl.isNotEmpty
          ? memberAppUrl
          : null,
    );
  }

  final String fullName;
  final String shortName;

  /// The API the site reads. A `CLUB_API_BASE_URL` dart-define overrides it,
  /// so a dev build can point at a local server without editing the config.
  final String apiBaseUrl;

  final ContactMapConfig map;

  /// The club's member app, e.g. `https://member.example.in`; null hides the
  /// navbar's user icon (club_core#179). A `CLUB_MEMBER_APP_URL` dart-define
  /// overrides it per environment, as `CLUB_API_BASE_URL` does the API.
  final String? memberAppUrl;

  static Future<SiteConfig> load() async => SiteConfig.fromJson(
    json.decode(await rootBundle.loadString(kSiteConfigAsset))
        as Map<String, dynamic>,
  );
}

/// Reads the host's bundled contact block, which `websiteMain` puts under
/// cl_remote_store's `contactInfoProvider` as its fallback.
Future<ContactInfo> loadBundledContactInfo() async => ContactInfo.fromBundled(
  json.decode(await rootBundle.loadString(kContactInfoAsset))
      as Map<String, dynamic>,
);

/// The running site's configuration. Always overridden by `websiteMain`.
final siteConfigProvider = Provider<SiteConfig>(
  (ref) => throw UnimplementedError('siteConfigProvider: run websiteMain()'),
);
