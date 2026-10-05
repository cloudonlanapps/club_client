import 'dart:convert';
import 'dart:typed_data';

import 'package:club_project_generator/club_project_generator.dart';
import 'package:image/image.dart' as img;
import 'package:test/test.dart';

Uint8List png(int w, int h) => img.encodePng(img.Image(width: w, height: h));

void main() {
  group('Issue 186: checkUrl', () {
    test('takes any host, as given', () {
      for (final url in [
        'http://203.0.113.10:8201/v1',
        'https://example.org/v1',
        'https://api.example.org/v1',
        'https://deep.sub.example.org',
      ]) {
        expect(checkUrl('--api-url', url), url);
      }
    });

    test('refuses anything that is not a whole http(s) URL', () {
      for (final url in [
        'example.org',
        '/v1',
        'ftp://example.org',
        'http://',
      ]) {
        expect(
          () => checkUrl('--api-url', url),
          throwsA(isA<GeneratorException>()),
          reason: url,
        );
      }
    });
  });

  group('Issue 186: clubJsonFor', () {
    final brand = {
      'fullName': 'Example Club',
      'apiBaseUrl': 'https://stale.example.org/v1',
      'websiteUrl': 'https://stale.example.org',
      'memberAppUrl': 'https://stale.example.org',
      'eventTypes': ['camp'],
    };

    test('app: the API and the website link, from the environment', () {
      final out = clubJsonFor(
        brand: brand,
        target: Target.app,
        apiUrl: 'http://10.0.0.1:8000/v1',
        appUrl: 'https://app.example.org',
        websiteUrl: 'https://example.org',
      );
      expect(out['apiBaseUrl'], 'http://10.0.0.1:8000/v1');
      expect(out['websiteUrl'], 'https://example.org');
      expect(out.containsKey('memberAppUrl'), isFalse);
      expect(out['eventTypes'], ['camp']);
      expect(out['fullName'], 'Example Club');
    });

    test('website: the API and the member app link, from the environment', () {
      final out = clubJsonFor(
        brand: brand,
        target: Target.website,
        apiUrl: 'https://api.example.org/v1',
        appUrl: 'https://app.example.org',
      );
      expect(out['apiBaseUrl'], 'https://api.example.org/v1');
      expect(out['memberAppUrl'], 'https://app.example.org');
      expect(out.containsKey('websiteUrl'), isFalse);
    });

    test('a link the environment does not give is left out, not kept', () {
      final out = clubJsonFor(
        brand: brand,
        target: Target.app,
        apiUrl: 'https://api.example.org/v1',
      );
      expect(out.containsKey('websiteUrl'), isFalse);
    });
  });

  group('Issue 186: WebColors', () {
    test('defaults to neutral when club.json has no web block', () {
      final c = WebColors.fromClubJson({});
      expect(c.backgroundLight, WebColors.neutral.backgroundLight);
      expect(c.accentDark, WebColors.neutral.accentDark);
    });

    test('takes the brand colours, and refuses a malformed one', () {
      final c = WebColors.fromClubJson({
        'web': {'backgroundLight': '#F7F6F2'},
      });
      expect(c.backgroundLight, '#F7F6F2');
      expect(
        () => WebColors.fromClubJson({
          'web': {'accentLight': 'blue'},
        }),
        throwsA(isA<GeneratorException>()),
      );
    });
  });

  group('Issue 186: web files', () {
    const names = WebNames(fullName: 'A & B <Club>', shortName: 'AB');

    test('index.html fills every token and escapes the names', () {
      final html = renderIndexHtml(
        template: '<title>@@FULL_NAME@@</title>@@DESCRIPTION@@ @@ACCENT_DARK@@',
        target: Target.website,
        names: names,
        colors: WebColors.neutral,
      );
      expect(html, isNot(contains('@@')));
      expect(html, contains('<title>A &amp; B &lt;Club&gt;</title>'));
      expect(html, contains('Official Website'));
    });

    test('index.html refuses a token it does not know', () {
      expect(
        () => renderIndexHtml(
          template: '@@NOPE@@',
          target: Target.app,
          names: names,
          colors: WebColors.neutral,
        ),
        throwsA(isA<GeneratorException>()),
      );
    });

    test('the manifest names the club', () {
      final m =
          json.decode(
                renderManifest(
                  target: Target.app,
                  names: names,
                  colors: WebColors.neutral,
                ),
              )
              as Map<String, dynamic>;
      expect(m['name'], 'A & B <Club>');
      expect(m['short_name'], 'AB');
      expect(m['description'], 'A & B <Club> - Official App');
    });

    test('icons come in every size the page names', () {
      final icons = renderIcons(png(1024, 1024));
      final sizes = {
        for (final e in icons.entries) e.key: img.decodePng(e.value)!.width,
      };
      expect(sizes, {
        'favicon.png': 16,
        'icons/Icon-192.png': 192,
        'icons/Icon-512.png': 512,
        'icons/Icon-maskable-192.png': 192,
        'icons/Icon-maskable-512.png': 512,
      });
    });

    test('icon source must be square and at least 512 px', () {
      for (final bad in [png(1024, 512), png(256, 256)]) {
        expect(() => renderIcons(bad), throwsA(isA<GeneratorException>()));
      }
    });
  });

  group('Issue 29: search files', () {
    test('sitemap routes cover the event types the club runs', () {
      expect(sitemapRoutes({}), [
        '/',
        '/public/about-us',
        '/public/events',
        '/public/coaches',
        '/public/rinks',
        '/public/contact-us',
      ]);
      expect(
        sitemapRoutes({
          'eventTypes': ['programme', 'oneOff'],
        }),
        [
          '/',
          '/public/about-us',
          '/public/programs',
          '/public/one-off',
          '/public/coaches',
          '/public/rinks',
          '/public/contact-us',
        ],
      );
    });

    test('sitemap routes refuse a malformed eventTypes', () {
      for (final bad in <Object>[
        'camp',
        <String>[],
        ['tournament'],
      ]) {
        expect(
          () => sitemapRoutes({'eventTypes': bad}),
          throwsA(isA<GeneratorException>()),
          reason: '$bad',
        );
      }
    });

    test('sitemap.xml lists each route as an absolute URL', () {
      final xml = renderSitemapXml(
        websiteUrl: 'https://example.org/',
        routes: ['/', '/public/coaches'],
      );
      expect(xml, startsWith('<?xml version="1.0" encoding="UTF-8"?>\n'));
      expect(
        xml,
        contains(
          '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">',
        ),
      );
      expect(xml, contains('<url><loc>https://example.org/</loc></url>'));
      expect(
        xml,
        contains('<url><loc>https://example.org/public/coaches</loc></url>'),
      );
      expect('<url>'.allMatches(xml), hasLength(2));
    });

    test('sitemap.xml keeps a path prefix and escapes the URL', () {
      final xml = renderSitemapXml(
        websiteUrl: 'http://203.0.113.10:8081/site?a=1&b=2',
        routes: ['/public/rinks'],
      );
      expect(xml, contains('&amp;'));
      expect(xml, isNot(contains('&b')));
      expect(
        renderSitemapXml(
          websiteUrl: 'https://example.org/club',
          routes: ['/public/rinks'],
        ),
        contains('<loc>https://example.org/club/public/rinks</loc>'),
      );
    });

    test('robots.txt allows everything and names the sitemap', () {
      expect(
        renderRobotsTxt(websiteUrl: 'https://example.org/'),
        'User-agent: *\n'
        'Allow: /\n'
        '\n'
        'Sitemap: https://example.org/sitemap.xml\n',
      );
    });
  });

  test('Issue 186: relative path dependencies become absolute', () {
    const pubspec = '''
dependencies:
  cl_club_app:
    path: ..
  ui_lib:
    path: ../../ui_lib
  already:
    path: /abs/pkg
  club_sdk_2:
    git:
      url: https://github.com/cloudonlanapps/club_sdk.git
      path: sub
''';
    final out = absolutizePathDependencies(
      pubspec,
      '/core/cl_club_app/example',
    );
    expect(out, contains('path: /core/cl_club_app\n'));
    expect(out, contains('path: /core/ui_lib\n'));
    expect(out, contains('path: /abs/pkg\n'));
    expect(
      out,
      contains('url: https://github.com/cloudonlanapps/club_sdk.git'),
    );
    expect(out, contains('      path: sub\n'));
  });
}
