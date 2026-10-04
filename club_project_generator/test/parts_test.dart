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
