import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:path/path.dart' as p;

import 'club_json.dart';
import 'pubspec_paths.dart';
import 'search_files.dart';
import 'target.dart';
import 'urls.dart';
import 'web_colors.dart';
import 'web_files.dart';

/// Brand files every target needs, relative to the brand folder.
const brandFiles = [
  'club.json',
  'contact_info.json',
  'club_logo.png',
  'icon_1024.png',
];

/// Website-only brand files, relative to the brand folder.
const websiteFiles = ['website/app_en.arb', 'website/theme.json'];

/// The website's media slots a brand may replace (`website/media/<name>`).
/// Any it leaves out keep the template's neutral image.
const mediaSlots = {'landing_background.webp', 'page_hero_default.webp'};

/// Template entries not copied: build output, tool state, the integration
/// suite and its platform folders, and `web/`, which is generated.
const _skipped = {
  '.dart_tool',
  '.flutter-plugins',
  '.flutter-plugins-dependencies',
  '.idea',
  'CLAUDE.md',
  'android',
  'build',
  'integration_test',
  'ios',
  'linux',
  'macos',
  'test_driver',
  'web',
  'windows',
};

/// What to generate, and from what.
class GenerateOptions {
  GenerateOptions({
    required this.clubCore,
    required this.target,
    required this.brand,
    required this.out,
    required String apiUrl,
    String? appUrl,
    String? websiteUrl,
    this.check = true,
  }) : apiUrl = checkUrl('--api-url', apiUrl),
       appUrl = appUrl == null ? null : checkUrl('--app-url', appUrl),
       websiteUrl = websiteUrl == null
           ? null
           : checkUrl('--website-url', websiteUrl);

  /// The club_core checkout the templates and packages come from.
  final String clubCore;
  final Target target;

  /// The brand folder.
  final String brand;

  /// The project to create. Must not exist, or be an empty folder.
  final String out;

  final String apiUrl;

  /// The member app's URL, for the website's link to it.
  final String? appUrl;

  /// The website's URL: the app's link to it, and where the website's own
  /// `robots.txt` and `sitemap.xml` say its pages are.
  final String? websiteUrl;

  /// Run `flutter pub get` and the template's brand-file test on the result.
  final bool check;
}

/// Generates the project, then (unless [GenerateOptions.check] is off)
/// resolves it and runs the brand-file test, failing on any problem.
Future<void> generate(GenerateOptions o, {void Function(String)? log}) async {
  final say = log ?? (_) {};
  final template = p.join(o.clubCore, o.target.templatePath);
  if (!File(p.join(template, 'pubspec.yaml')).existsSync()) {
    throw GeneratorException('no template at $template');
  }
  _checkBrand(o);
  _checkOut(o.out);

  say('==> copying ${o.target.templatePath}');
  _copyTree(Directory(template), Directory(o.out));

  final pubspec = File(p.join(o.out, 'pubspec.yaml'));
  final rewritten = absolutizePathDependencies(
    pubspec.readAsStringSync(),
    template,
  );
  pubspec.writeAsStringSync(rewritten);

  say('==> brand files from ${o.brand}');
  final brandJson = _readJson(p.join(o.brand, 'club.json'));
  final clubJson = clubJsonFor(
    brand: brandJson,
    target: o.target,
    apiUrl: o.apiUrl,
    appUrl: o.appUrl,
    websiteUrl: o.websiteUrl,
  );
  _write(
    p.join(o.out, 'assets/club.json'),
    '${const JsonEncoder.withIndent('  ').convert(clubJson)}\n',
  );
  _copy(o.brand, 'contact_info.json', o.out, 'assets/data/contact_info.json');
  _copy(o.brand, 'club_logo.png', o.out, 'assets/images/club_logo.png');
  if (o.target == Target.website) {
    _copy(o.brand, 'website/app_en.arb', o.out, 'assets/l10n/app_en.arb');
    _copy(o.brand, 'website/theme.json', o.out, 'assets/config/theme.json');
    for (final slot in _brandMedia(o.brand)) {
      _copy(o.brand, 'website/media/$slot', o.out, 'assets/media/$slot');
    }
  }

  say('==> web/');
  final names = WebNames.fromClubJson(clubJson);
  final colors = WebColors.fromClubJson(clubJson);
  _write(
    p.join(o.out, 'web/index.html'),
    renderIndexHtml(
      template: File(
        p.join(await generatorRoot(), 'templates/web/index.html'),
      ).readAsStringSync(),
      target: o.target,
      names: names,
      colors: colors,
    ),
  );
  _write(
    p.join(o.out, 'web/manifest.json'),
    renderManifest(target: o.target, names: names, colors: colors),
  );
  final icons = renderIcons(
    File(p.join(o.brand, 'icon_1024.png')).readAsBytesSync(),
  );
  for (final MapEntry(key: path, value: bytes) in icons.entries) {
    File(p.join(o.out, 'web', path))
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);
  }

  final websiteUrl = o.websiteUrl;
  if (o.target == Target.website && websiteUrl != null) {
    _write(
      p.join(o.out, 'web/robots.txt'),
      renderRobotsTxt(websiteUrl: websiteUrl),
    );
    _write(
      p.join(o.out, 'web/sitemap.xml'),
      renderSitemapXml(websiteUrl: websiteUrl, routes: sitemapRoutes(clubJson)),
    );
  }

  if (!o.check) return;
  say('==> flutter pub get');
  await _flutter(['pub', 'get'], o.out);
  say('==> checking the brand files (test/brand_files_test.dart)');
  await _flutter(['test', 'test/brand_files_test.dart'], o.out);
}

/// This package's folder, which holds `templates/`, found from where Dart
/// resolves its own library: the same under `dart run`, a test, or a snapshot.
Future<String> generatorRoot() async {
  final lib = await Isolate.resolvePackageUri(
    Uri.parse('package:club_project_generator/club_project_generator.dart'),
  );
  if (lib == null) {
    throw const GeneratorException('cannot locate club_project_generator');
  }
  return p.dirname(p.dirname(p.fromUri(lib)));
}

void _checkBrand(GenerateOptions o) {
  if (!Directory(o.brand).existsSync()) {
    throw GeneratorException('no brand folder at ${o.brand}');
  }
  final needed = [
    ...brandFiles,
    if (o.target == Target.website) ...websiteFiles,
  ];
  final missing = needed
      .where((f) => !File(p.join(o.brand, f)).existsSync())
      .toList();
  if (missing.isNotEmpty) {
    throw GeneratorException(
      'brand folder ${o.brand} is missing: ${missing.join(', ')}',
    );
  }
  if (o.target == Target.website) _brandMedia(o.brand);
}

/// The media slots the brand replaces. Refuses a file that fills no slot,
/// so a misnamed image is an error rather than silently unused.
List<String> _brandMedia(String brand) {
  final dir = Directory(p.join(brand, 'website/media'));
  if (!dir.existsSync()) return const [];
  final names = dir.listSync().whereType<File>().map((f) => p.basename(f.path));
  final unknown = names.where((n) => !mediaSlots.contains(n)).toList();
  if (unknown.isNotEmpty) {
    throw GeneratorException(
      'website/media/${unknown.join(', ')} fills no media slot; '
      'slots: ${mediaSlots.join(', ')}',
    );
  }
  return names.toList()..sort();
}

void _checkOut(String out) {
  final dir = Directory(out);
  if (dir.existsSync() && dir.listSync().isNotEmpty) {
    throw GeneratorException('$out exists and is not empty');
  }
}

void _copyTree(Directory from, Directory to) {
  to.createSync(recursive: true);
  for (final entity in from.listSync()) {
    final name = p.basename(entity.path);
    if (_skipped.contains(name)) continue;
    final dest = p.join(to.path, name);
    if (entity is Directory) {
      _copyTree(entity, Directory(dest));
    } else if (entity is File) {
      entity.copySync(dest);
    }
  }
}

Map<String, dynamic> _readJson(String path) {
  try {
    final value = json.decode(File(path).readAsStringSync());
    if (value is Map<String, dynamic>) return value;
  } on FormatException catch (e) {
    throw GeneratorException('$path is not valid JSON: ${e.message}');
  }
  throw GeneratorException('$path must hold a JSON object');
}

void _copy(String fromDir, String from, String toDir, String to) {
  final dest = File(p.join(toDir, to))..parent.createSync(recursive: true);
  File(p.join(fromDir, from)).copySync(dest.path);
}

void _write(String path, String content) {
  File(path)
    ..parent.createSync(recursive: true)
    ..writeAsStringSync(content);
}

Future<void> _flutter(List<String> args, String dir) async {
  final result = await Process.run('flutter', args, workingDirectory: dir);
  if (result.exitCode != 0) {
    throw GeneratorException(
      'flutter ${args.join(' ')} failed in $dir:\n'
      '${result.stdout}${result.stderr}',
    );
  }
}
