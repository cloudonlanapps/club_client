import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// Widgets removed as unused (#63, club_client#50): no consumer in
/// club_core or in the apps and sites built on it.
const removed = [
  'reason_popover.dart',
  'avatar_circle.dart',
  'search_input.dart',
];

/// One export of the barrel: the file and the names after `show`.
typedef _Export = ({String file, List<String> names});

final _exportPattern = RegExp(r"export\s+'([^']+)'\s*(?:show\s+([^;]+))?;");

List<_Export> _barrelExports() {
  final barrel = File('lib/ui_lib.dart').readAsStringSync();
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

/// The production code of every other package of the repo: each package's
/// `lib/` and each example app's `lib/`.
String _otherPackagesCode() {
  final code = StringBuffer();
  for (final package in Directory('..').listSync().whereType<Directory>()) {
    if (package.uri.pathSegments.contains('ui_lib')) continue;
    for (final lib in ['lib', 'example/lib']) {
      final dir = Directory('${package.path}/$lib');
      if (!dir.existsSync()) continue;
      for (final file in dir.listSync(recursive: true).whereType<File>()) {
        if (!file.path.endsWith('.dart')) continue;
        code.writeln(_withoutComments(file.readAsStringSync()));
      }
    }
  }
  return code.toString();
}

void main() {
  group('Issue 63: unused ui_lib widgets are gone', () {
    test('Issue 63: neither the files nor their barrel exports remain', () {
      final barrel = File('lib/ui_lib.dart').readAsStringSync();
      for (final name in removed) {
        expect(File('lib/src/widgets/$name').existsSync(), isFalse);
        expect(barrel, isNot(contains("'src/widgets/$name'")));
      }
    });
  });

  group('Issue 50: the barrel exports only what other packages use', () {
    test('Issue 50: every export names what it exports', () {
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

    test("Issue 50: every exported name is used by another package's "
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
}
