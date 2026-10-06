import 'package:url_launcher_platform_interface/link.dart' show LinkDelegate;
import 'package:url_launcher_platform_interface/url_launcher_platform_interface.dart';

/// A [UrlLauncherPlatform] that records every URL it is asked to open instead
/// of opening it, so a widget test can assert what a tap would launch.
class RecordingUrlLauncher extends UrlLauncherPlatform {
  /// URLs passed to [launchUrl], in call order.
  final List<String> launched = [];

  @override
  LinkDelegate? get linkDelegate => null;

  @override
  Future<bool> canLaunch(String url) async => true;

  @override
  Future<bool> launchUrl(String url, LaunchOptions options) async {
    launched.add(url);
    return true;
  }
}
