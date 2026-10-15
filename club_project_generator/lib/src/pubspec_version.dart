import 'dart:io';

import 'package:path/path.dart' as p;

import 'target.dart';

/// The file at the club_core checkout's root holding its one version number.
/// No `pubspec.yaml` in the checkout carries a version; the generator writes
/// this one into each project it creates.
const versionFile = 'VERSION';

/// Reads `<major>.<minor>.<patch>` from [clubCore]'s [versionFile].
String readClubVersion(String clubCore) {
  final file = File(p.join(clubCore, versionFile));
  if (!file.existsSync()) {
    throw GeneratorException('no $versionFile at $clubCore');
  }
  final version = file.readAsStringSync().trim();
  if (!RegExp(r'^\d+\.\d+\.\d+$').hasMatch(version)) {
    throw GeneratorException(
      '$clubCore/$versionFile must hold <major>.<minor>.<patch>, '
      'got "$version"',
    );
  }
  return version;
}

/// Writes `version: [version]` into [pubspec], after its top-level `name:`.
///
/// Refuses a template that already carries a version, so a second number
/// cannot creep back into the checkout and silently win.
String withVersion(String pubspec, String version) {
  final lines = pubspec.split('\n');
  if (lines.any(RegExp('^version:').hasMatch)) {
    throw const GeneratorException(
      'the template pubspec.yaml carries a version; '
      "the only version is club_core's $versionFile",
    );
  }
  final name = lines.indexWhere(RegExp('^name:').hasMatch);
  if (name < 0) {
    throw const GeneratorException('the template pubspec.yaml has no name');
  }
  lines.insert(name + 1, 'version: $version');
  return lines.join('\n');
}
