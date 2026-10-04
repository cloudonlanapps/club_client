import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart' show openPdfDownload;
import 'package:url_launcher_platform_interface/link.dart' show LinkDelegate;
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// Records every URL handed to the platform instead of opening it.
class _RecordingLauncher extends UrlLauncherPlatform {
  final List<(String, PreferredLaunchMode)> launched = [];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add((url, options.mode));
    return true;
  }
}

void main() {
  late _RecordingLauncher launcher;

  setUp(() {
    launcher = _RecordingLauncher();
    UrlLauncherPlatform.instance = launcher;
  });

  test(
    'Issue 67: a media-by-uuid API URL is opened as given, not rewritten '
    'onto a /downloads path',
    () async {
      const url =
          'https://api.example.com/v1/media/by_id/abc-123/download'
          '?variant=original';

      await openPdfDownload(url);

      expect(launcher.launched, [
        (url, PreferredLaunchMode.externalApplication),
      ]);
    },
  );

  test('Issue 67: a /static/ URL stays on the API origin', () async {
    const url = 'https://api.example.com/static/docs/rules.pdf';

    await openPdfDownload(url);

    expect(launcher.launched.single.$1, url);
  });
}
