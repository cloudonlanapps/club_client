import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// One export of the barrel: the file and the names after `show`.
typedef _Export = ({String file, List<String> names});

final _exportPattern = RegExp(r"export\s+'([^']+)'\s*(?:show\s+([^;]+))?;");

List<_Export> _barrelExports() {
  final barrel = File('lib/cl_club_forms.dart').readAsStringSync();
  return [
    for (final match in _exportPattern.allMatches(barrel))
      (
        file: match.group(1)!,
        names: [
          for (final name in (match.group(2) ?? '').split(','))
            if (name.trim().isNotEmpty) name.trim(),
        ],
      ),
  ];
}

String _withoutComments(String source) =>
    source.replaceAll(RegExp('//[^\n]*'), '');

Iterable<File> _dartFiles(String dir) =>
    Directory(
          dir,
        )
        .listSync(recursive: true)
        .whereType<File>()
        .where(
          (file) => file.path.endsWith('.dart'),
        );

/// The production code of every other package of the repo: each package's
/// `lib/` and each example app's `lib/`.
String _otherPackagesCode() {
  final code = StringBuffer();
  for (final package in Directory('..').listSync().whereType<Directory>()) {
    if (package.uri.pathSegments.contains('cl_club_forms')) continue;
    for (final lib in ['lib', 'example/lib']) {
      if (!Directory('${package.path}/$lib').existsSync()) continue;
      for (final file in _dartFiles('${package.path}/$lib')) {
        code.writeln(_withoutComments(file.readAsStringSync()));
      }
    }
  }
  return code.toString();
}

// Spelt in two parts so this file does not match its own search.
const _uiLibImport =
    'package:'
    'ui_lib/';
const _formsImport =
    'package:'
    'cl_club_forms/';

void main() {
  group('Issue 60: cl_club_forms stands apart from ui_lib', () {
    test('Issue 60: neither its code nor its pubspec names ui_lib', () {
      final offenders = [
        for (final dir in ['lib', 'test'])
          for (final file in _dartFiles(dir))
            if (file.readAsStringSync().contains(_uiLibImport)) file.path,
      ];
      expect(offenders, isEmpty);
      expect(
        File('pubspec.yaml').readAsStringSync(),
        isNot(contains('ui_lib')),
      );
    });

    test('Issue 60: ui_lib names cl_club_forms nowhere', () {
      final offenders = [
        for (final dir in ['../ui_lib/lib', '../ui_lib/test'])
          for (final file in _dartFiles(dir))
            if (file.readAsStringSync().contains(_formsImport)) file.path,
      ];
      expect(offenders, isEmpty);
      expect(
        File('../ui_lib/pubspec.yaml').readAsStringSync(),
        isNot(contains('cl_club_forms')),
      );
    });

    test("Issue 60: the only forms left in ui_lib are evaluation's", () {
      final forms = [
        for (final file in _dartFiles('../ui_lib/lib'))
          if (file.readAsStringSync().contains('ShadForm(') &&
              !file.path.contains('/widgets/evaluation/'))
            file.path,
      ];
      expect(forms, isEmpty);
    });
  });

  group('Issue 60: the barrel exports only what other packages use', () {
    test('Issue 60: every export names what it exports', () {
      final exports = _barrelExports();
      expect(exports, isNotEmpty);
      expect(
        [
          for (final export in exports)
            if (export.names.isEmpty) export.file,
        ],
        isEmpty,
        reason: 'exports without `show`',
      );
    });

    test("Issue 60: every exported name is used by another package's "
        'production code', () {
      final code = _otherPackagesCode();
      expect(code, isNotEmpty);
      final unused = <String>[];
      for (final export in _barrelExports()) {
        final source = File('lib/${export.file}').readAsStringSync();
        for (final name in export.names) {
          // An extension is used through its members, never by its name.
          if (RegExp('extension\\s+$name\\s+on\\b').hasMatch(source)) continue;
          if (!RegExp('\\b$name\\b').hasMatch(code)) unused.add(name);
        }
      }
      expect(unused, isEmpty, reason: 'exported, but used by no other package');
    });
  });

  group('Issue 107: a form opens nothing', () {
    test('Issue 107: cl_club_forms/lib calls no showShadDialog and holds no '
        'dialog', () {
      final files = _dartFiles('lib').toList();
      expect(files, isNotEmpty);
      final opens = RegExp(r'show\w*(Dialog|Sheet)\s*[<(]');
      final builds = RegExp(r'\b\w*Dialog(\.\w+)?\(');
      final offenders = [
        for (final file in files)
          if (_withoutComments(file.readAsStringSync()) case final code
              when opens.hasMatch(code) || builds.hasMatch(code))
            file.path,
      ];
      expect(offenders, isEmpty);
    });
  });
}
