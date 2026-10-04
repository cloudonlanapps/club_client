import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import 'sign_out_destination.dart';

/// The browsing context that replaces the app with the website.
const String sameTabTarget = '_self';

/// Leaves the member zone after a chosen sign-out: to [publicSite] on the
/// web when there is one, otherwise to the app's home, which shows login.
void afterSignOut(BuildContext context, Uri? publicSite) {
  final destination = signOutDestination(publicSite, isWeb: kIsWeb);
  if (destination == null) {
    context.go('/');
  } else {
    unawaited(launchUrl(destination, webOnlyWindowName: sameTabTarget));
  }
}
