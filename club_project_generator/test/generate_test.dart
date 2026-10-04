import 'dart:convert';
import 'dart:io';

import 'package:club_project_generator/club_project_generator.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

/// `dart test` runs from the package folder, inside the club_core checkout.
final String clubCore = p.dirname(Directory.current.path);
final String exampleBrand = p.join(Directory.current.path, 'example_brand');

Map<String, dynamic> readJson(String path) =>
    json.decode(File(path).readAsStringSync()) as Map<String, dynamic>;

void main() {
  late Directory tmp;
  setUp(() async => tmp = await Directory.systemTemp.createTemp('gen186_'));
  tearDown(() => tmp.deleteSync(recursive: true));

  Future<String> run(
    Target target, {
    String? brand,
    String? appUrl,
    String? websiteUrl,
  }) async {
    final out = p.join(tmp.path, target.name);
    await generate(
      GenerateOptions(
        clubCore: clubCore,
        target: target,
        brand: brand ?? exampleBrand,
        out: out,
        apiUrl: 'http://203.0.113.10:8201/v1',
        appUrl: appUrl,
        websiteUrl: websiteUrl,
        check: false,
      ),
    );
    return out;
  }

  test('Issue 186: the app project carries the brand and the URLs', () async {
    final out = await run(Target.app, websiteUrl: 'https://example.org');
    final club = readJson(p.join(out, 'assets/club.json'));
    expect(club['apiBaseUrl'], 'http://203.0.113.10:8201/v1');
    expect(club['websiteUrl'], 'https://example.org');
    expect(club['fullName'], 'Example Club');
    for (final f in [
      'lib/main.dart',
      'test/brand_files_test.dart',
      'assets/data/contact_info.json',
      'assets/images/club_logo.png',
      'web/index.html',
      'web/manifest.json',
      'web/favicon.png',
      'web/icons/Icon-512.png',
    ]) {
      expect(File(p.join(out, f)).existsSync(), isTrue, reason: f);
    }
    for (final skipped in ['integration_test', 'test_driver', 'linux']) {
      expect(Directory(p.join(out, skipped)).existsSync(), isFalse);
    }
    expect(
      File(p.join(out, 'web/index.html')).readAsStringSync(),
      allOf(contains('<title>Example Club</title>'), isNot(contains('@@'))),
    );
  });

  test('Issue 186: every path dependency points into the checkout', () async {
    final out = await run(Target.app);
    final paths = RegExp(r'^\s+path:\s*(\S+)', multiLine: true)
        .allMatches(File(p.join(out, 'pubspec.yaml')).readAsStringSync())
        .map((m) => m[1]!)
        .toList();
    expect(paths, isNotEmpty);
    for (final path in paths) {
      expect(p.isAbsolute(path), isTrue, reason: path);
      expect(p.isWithin(clubCore, path), isTrue, reason: path);
      expect(File(p.join(path, 'pubspec.yaml')).existsSync(), isTrue);
    }
  });

  test('Issue 186: the website takes its text, theme and media', () async {
    final out = await run(Target.website, appUrl: 'https://app.example.org');
    expect(
      readJson(p.join(out, 'assets/club.json'))['memberAppUrl'],
      'https://app.example.org',
    );
    expect(
      File(p.join(out, 'assets/l10n/app_en.arb')).readAsStringSync(),
      File(p.join(exampleBrand, 'website/app_en.arb')).readAsStringSync(),
    );
    // The brand replaces one media slot; the other keeps the template's.
    final brandHero = File(
      p.join(exampleBrand, 'website/media/page_hero_default.webp'),
    ).readAsBytesSync();
    final templateLanding = File(
      p.join(
        clubCore,
        'cl_club_website/example/assets/media/'
        'landing_background.webp',
      ),
    ).readAsBytesSync();
    expect(
      File(
        p.join(out, 'assets/media/page_hero_default.webp'),
      ).readAsBytesSync(),
      brandHero,
    );
    expect(
      File(
        p.join(out, 'assets/media/landing_background.webp'),
      ).readAsBytesSync(),
      templateLanding,
    );
  });

  group('Issue 186: refusals', () {
    Future<Directory> brandCopy() async {
      final dir = Directory(p.join(tmp.path, 'brand'));
      for (final f in Directory(
        exampleBrand,
      ).listSync(recursive: true).whereType<File>()) {
        final rel = p.relative(f.path, from: exampleBrand);
        File(p.join(dir.path, rel)).parent.createSync(recursive: true);
        f.copySync(p.join(dir.path, rel));
      }
      return dir;
    }

    test('a missing brand file names the file', () async {
      final brand = await brandCopy();
      File(p.join(brand.path, 'contact_info.json')).deleteSync();
      expect(
        () => run(Target.app, brand: brand.path),
        throwsA(
          isA<GeneratorException>().having(
            (e) => e.message,
            'message',
            contains('contact_info.json'),
          ),
        ),
      );
    });

    test('the website needs its text and theme; the app does not', () async {
      final brand = await brandCopy();
      Directory(p.join(brand.path, 'website')).deleteSync(recursive: true);
      await run(Target.app, brand: brand.path);
      expect(
        () => run(Target.website, brand: brand.path),
        throwsA(isA<GeneratorException>()),
      );
    });

    test('a media file that fills no slot', () async {
      final brand = await brandCopy();
      File(
        p.join(brand.path, 'website/media/ring_background.jpg'),
      ).writeAsBytesSync([0]);
      expect(
        () => run(Target.website, brand: brand.path),
        throwsA(isA<GeneratorException>()),
      );
    });

    test('an output folder that is not empty', () async {
      File(p.join(tmp.path, 'app', 'keep'))
        ..createSync(recursive: true)
        ..writeAsStringSync('x');
      expect(() => run(Target.app), throwsA(isA<GeneratorException>()));
    });
  });
}
