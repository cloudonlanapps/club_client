import 'dart:io';

import 'package:args/args.dart';
import 'package:club_project_generator/club_project_generator.dart';
import 'package:path/path.dart' as p;

const _usage = '''
Generates a club's Flutter web project from club_core's templates.

  dart run bin/generate.dart --target app|website --brand <dir> --out <dir>
      --api-url <url> [--app-url <url>] [--website-url <url>]

URLs are whole http(s) URLs, used as given.''';

Future<void> main(List<String> args) async {
  final parser = ArgParser()
    ..addOption('target', allowed: ['app', 'website'], mandatory: true)
    ..addOption('brand', mandatory: true, help: 'the brand folder')
    ..addOption('out', mandatory: true, help: 'the project to create')
    ..addOption('api-url', mandatory: true)
    ..addOption('app-url', help: "the member app's URL (website target)")
    ..addOption(
      'website-url',
      help:
          "the website's URL: the app's link to it, and the base of the "
          "website's robots.txt and sitemap.xml",
    )
    ..addOption(
      'club-core',
      help: 'the club_core checkout (default: the one holding this tool)',
    )
    ..addFlag(
      'check',
      defaultsTo: true,
      help: 'resolve the project and run its brand-file test',
    )
    ..addFlag('help', abbr: 'h', negatable: false);

  try {
    final a = parser.parse(args);
    if (a.flag('help')) {
      stdout.writeln('$_usage\n\n${parser.usage}');
      return;
    }
    // The generator lives in the club_core checkout it builds from.
    final clubCore = a.option('club-core') ?? p.dirname(await generatorRoot());
    await generate(
      GenerateOptions(
        clubCore: p.absolute(clubCore),
        target: Target.parse(a.option('target')!),
        brand: p.absolute(a.option('brand')!),
        out: p.absolute(a.option('out')!),
        apiUrl: a.option('api-url')!,
        appUrl: a.option('app-url'),
        websiteUrl: a.option('website-url'),
        check: a.flag('check'),
      ),
      log: stdout.writeln,
    );
  } on ArgParserException catch (e) {
    stderr.writeln('${e.message}\n\n$_usage\n\n${parser.usage}');
    exitCode = 64;
  } on GeneratorException catch (e) {
    stderr.writeln('ERROR: $e');
    exitCode = 1;
  }
}
