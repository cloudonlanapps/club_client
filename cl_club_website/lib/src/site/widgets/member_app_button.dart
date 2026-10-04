import 'dart:async';

import 'package:cl_club_website/cl_club_website.dart'
    show SiteStrings, memberAppUriProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:url_launcher/url_launcher.dart';

/// The browsing context the member app opens in: this tab, since the app is
/// the visitor's next step rather than a side trip.
const String memberAppTarget = '_self';

/// The navbar's size for its icon buttons.
const double memberAppIconSize = 18;

/// Opens the club's member app at its home, which shows the dashboard or
/// the login page by the visitor's session (club_core#179).
///
/// Only the desktop navbar shows it: wherever a menu button opens the side
/// menu, the menu's Member Area stands in for it (club_core#184). Renders
/// nothing when `memberAppUriProvider` is null.
class MemberAppButton extends ConsumerWidget {
  const MemberAppButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memberApp = ref.watch(memberAppUriProvider);
    if (memberApp == null) return const SizedBox.shrink();
    return Semantics(
      button: true,
      label: SiteStrings.of(context).navMemberApp,
      excludeSemantics: true,
      child: ShadButton.ghost(
        size: ShadButtonSize.sm,
        onPressed: () => openMemberApp(memberApp),
        child: const Icon(LucideIcons.circleUser, size: memberAppIconSize),
      ),
    );
  }
}

/// Replaces the site with the member app at [memberApp].
void openMemberApp(Uri memberApp) =>
    unawaited(launchUrl(memberApp, webOnlyWindowName: memberAppTarget));
