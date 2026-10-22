import 'package:cl_club_forms/src/widgets/form/form_autofocus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Issue 160: no autofocus in a browser on a phone', () {
    for (final platform in [TargetPlatform.android, TargetPlatform.iOS]) {
      expect(
        FormAutofocus.allowedOn(web: true, platform: platform),
        isFalse,
        reason: '$platform browser',
      );
    }
  });

  test(
    'Issue 160: autofocus stays in a desktop browser and in a native app',
    () {
      for (final platform in [
        TargetPlatform.linux,
        TargetPlatform.macOS,
        TargetPlatform.windows,
      ]) {
        expect(FormAutofocus.allowedOn(web: true, platform: platform), isTrue);
      }
      for (final platform in TargetPlatform.values) {
        expect(FormAutofocus.allowedOn(web: false, platform: platform), isTrue);
      }
    },
  );
}
