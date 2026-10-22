import 'package:flutter/foundation.dart';

/// Whether a form's first field may take the focus as its page opens.
///
/// In a phone's browser a field that takes the focus before the phone has
/// shown a keyboard starts text editing early, which is one of the focus
/// hops that can leave a blank band where the keyboard was (#160). There
/// the member taps the field instead; everywhere else the first field
/// still takes the cursor as the page opens.
abstract final class FormAutofocus {
  /// Whether autofocus is allowed on this device.
  static bool get allowed =>
      allowedOn(web: kIsWeb, platform: defaultTargetPlatform);

  /// Whether autofocus is allowed on a device that is [web] or not, of
  /// [platform]: everywhere except a browser on Android or iOS.
  static bool allowedOn({required bool web, required TargetPlatform platform}) {
    if (!web) return true;
    return switch (platform) {
      TargetPlatform.android || TargetPlatform.iOS => false,
      _ => true,
    };
  }
}
