import 'package:path/path.dart' as p;

/// Rewrites every relative `path:` dependency in [pubspec] to an absolute
/// path, resolved against [templateDir], the folder the pubspec came from.
///
/// The generated project lives outside club_core, so the template's relative
/// paths (`path: ..`, `path: ../../ui_lib`) would point nowhere. Absolute
/// paths keep them on the same checkout, so no package is pinned by SHA.
///
/// A `path:` inside a `git:` block names a folder within that repository and
/// is left as it is.
String absolutizePathDependencies(String pubspec, String templateDir) {
  final pathLine = RegExp(r'^(\s+path:\s*)(\S+)\s*$');
  final gitLine = RegExp(r'^(\s+)git:\s*$');
  int? gitIndent;
  return pubspec
      .split('\n')
      .map((line) {
        final indent = line.length - line.trimLeft().length;
        if (gitIndent != null &&
            line.trim().isNotEmpty &&
            indent <= gitIndent!) {
          gitIndent = null;
        }
        final git = gitLine.firstMatch(line);
        if (git != null) {
          gitIndent = git[1]!.length;
          return line;
        }
        final m = pathLine.firstMatch(line);
        if (m == null || gitIndent != null || p.isAbsolute(m[2]!)) return line;
        return '${m[1]}${p.normalize(p.join(templateDir, m[2]))}';
      })
      .join('\n');
}
