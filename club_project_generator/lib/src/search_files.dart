import 'target.dart';

/// The website's event listings, by the `club.json` event type each shows.
const eventTypeRoutes = {
  'programme': '/public/programs',
  'camp': '/public/events',
  'oneOff': '/public/one-off',
};

/// The event types of a `club.json` that names none.
const defaultEventTypes = ['camp'];

/// The website's public pages for the sitemap, in the site's own order: the
/// fixed pages, and the listing of each event type `club.json` says the club
/// runs. Event and venue pages are server data and are not listed.
List<String> sitemapRoutes(Map<String, dynamic> clubJson) {
  final raw = clubJson['eventTypes'] ?? defaultEventTypes;
  if (raw is! List ||
      raw.isEmpty ||
      raw.any((type) => !eventTypeRoutes.containsKey(type))) {
    throw GeneratorException(
      'club.json: "eventTypes" must be a non-empty list of '
      '${eventTypeRoutes.keys.join(', ')}, got "$raw"',
    );
  }
  return [
    '/',
    '/public/about-us',
    for (final MapEntry(key: type, value: route) in eventTypeRoutes.entries)
      if (raw.contains(type)) route,
    '/public/coaches',
    '/public/rinks',
    '/public/contact-us',
  ];
}

/// `sitemap.xml`: each of [routes] as an absolute URL under [websiteUrl].
String renderSitemapXml({
  required String websiteUrl,
  required List<String> routes,
}) {
  final urls = routes
      .map(
        (route) =>
            '  <url><loc>${xmlEscape(pageUrl(websiteUrl, route))}'
            '</loc></url>\n',
      )
      .join();
  return '<?xml version="1.0" encoding="UTF-8"?>\n'
      '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n'
      '$urls'
      '</urlset>\n';
}

/// `robots.txt`: every page may be crawled, and the sitemap lists them.
String renderRobotsTxt({required String websiteUrl}) =>
    'User-agent: *\n'
    'Allow: /\n'
    '\n'
    'Sitemap: ${pageUrl(websiteUrl, '/sitemap.xml')}\n';

/// The URL of [route] (which starts with `/`) on the site at [websiteUrl],
/// keeping any path the site is served under.
String pageUrl(String websiteUrl, String route) =>
    '${websiteUrl.replaceFirst(RegExp(r'/+$'), '')}$route';

/// Escapes [text] for XML character data.
String xmlEscape(String text) => text
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');
