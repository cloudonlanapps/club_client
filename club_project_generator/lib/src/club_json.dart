import 'target.dart';

/// The brand's `club.json` as one target ships it: the brand's own keys plus
/// the URLs of this environment.
///
/// One `club.json` serves both targets; each reads the keys it knows and
/// ignores the rest. The URLs are never part of the brand: they arrive per
/// environment and replace whatever the file holds.
Map<String, dynamic> clubJsonFor({
  required Map<String, dynamic> brand,
  required Target target,
  required String apiUrl,
  String? appUrl,
  String? websiteUrl,
}) {
  final out = Map<String, dynamic>.of(brand)
    ..remove('apiBaseUrl')
    ..remove('websiteUrl')
    ..remove('memberAppUrl')
    ..['apiBaseUrl'] = apiUrl;
  switch (target) {
    case Target.app:
      if (websiteUrl != null) out['websiteUrl'] = websiteUrl;
    case Target.website:
      if (appUrl != null) out['memberAppUrl'] = appUrl;
  }
  return out;
}
