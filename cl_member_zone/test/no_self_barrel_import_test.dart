import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Issue 248: no file under lib/src imports the cl_member_zone barrel',
    () {
      final files = Directory('lib/src')
          .listSync(recursive: true)
          .whereType<File>()
          .where((f) => f.path.endsWith('.dart'))
          .toList();
      expect(
        files,
        isNotEmpty,
        reason: 'run from the cl_member_zone package root',
      );
      final offenders = [
        for (final f in files)
          if (f.readAsStringSync().contains(
            "import 'package:cl_member_zone/cl_member_zone.dart'",
          ))
            f.path,
      ];
      expect(offenders, isEmpty);
    },
  );
}
