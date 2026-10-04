import 'package:cl_club_website/cl_club_website.dart'
    show SiteStrings, memberAppUriProvider, routeLabel;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:ui_lib/ui_lib.dart' as ui_lib;

import 'member_app_button.dart';

class MobileMenuDrawer extends ConsumerWidget {
  const MobileMenuDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = SiteStrings.of(context);
    final memberApp = ref.watch(memberAppUriProvider);
    return ui_lib.MobileMenuDrawer(
      title: strings.navMenu,
      menuItemGroups: [
        [
          ui_lib.BorderedMenuItem(
            label: strings.navHome,
            onTap: () => _navigate(context, '/'),
          ),
          ui_lib.BorderedMenuItem(
            label: routeLabel(strings, 'events')!.replaceAll('\n', ' '),
            onTap: () => _navigate(context, '/public/events'),
          ),
          ui_lib.BorderedMenuItem(
            label: routeLabel(strings, 'programs')!.replaceAll('\n', ' '),
            onTap: () => _navigate(context, '/public/programs'),
          ),
          ui_lib.BorderedMenuItem(
            label: routeLabel(strings, 'one-off')!.replaceAll('\n', ' '),
            onTap: () => _navigate(context, '/public/one-off'),
          ),
          ui_lib.BorderedMenuItem(
            label: routeLabel(strings, 'coaches')!.replaceAll('\n', ' '),
            onTap: () => _navigate(context, '/public/coaches'),
          ),
          ui_lib.BorderedMenuItem(
            label: routeLabel(strings, 'rinks')!.replaceAll('\n', ' '),
            onTap: () => _navigate(context, '/public/rinks'),
          ),
          ui_lib.BorderedMenuItem(
            label: routeLabel(strings, 'about-us')!.replaceAll('\n', ' '),
            onTap: () => _navigate(context, '/public/about-us'),
          ),
        ],
        [
          ui_lib.BorderedMenuItem(
            label: routeLabel(strings, 'contact-us')!.replaceAll('\n', ' '),
            onTap: () => _navigate(context, '/public/contact-us'),
          ),
        ],
      ],
      // Set apart at the bottom: a way out of the site, not one of its
      // pages (club_core#184).
      footerItems: [
        if (memberApp != null)
          ui_lib.BorderedMenuItem(
            label: strings.navMemberApp,
            onTap: () => openMemberApp(memberApp),
          ),
      ],
    );
  }

  void _navigate(BuildContext context, String path) {
    final router = GoRouter.of(context);
    final currentPath = router.routerDelegate.currentConfiguration.uri
        .toString();
    Navigator.pop(context);
    if (currentPath == path) return;
    if (path == '/') {
      router.go('/', extra: DateTime.now().millisecondsSinceEpoch);
    } else {
      router.go(path);
    }
  }
}
