import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart' show launchContactUrl;
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

import '../support/recording_url_launcher.dart';

void main() {
  late RecordingUrlLauncher launcher;

  setUp(() {
    final original = UrlLauncherPlatform.instance;
    launcher = RecordingUrlLauncher();
    UrlLauncherPlatform.instance = launcher;
    addTearDown(() => UrlLauncherPlatform.instance = original);
  });

  test('Issue 32: launchContactUrl hands the link to the platform', () async {
    await launchContactUrl('tel:+919876543210');

    expect(launcher.launched, ['tel:+919876543210']);
  });

  test('Issue 32: launchContactUrl opens nothing for an empty link', () async {
    await launchContactUrl('');

    expect(launcher.launched, isEmpty);
  });
}
