import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../dashboard_event_nav.dart';
import '../dummy/my_events_dummy_overrides.dart';
import '../my_events_panel_body.dart';

/// Stand-alone preview for design iteration on the My Events panel.
///
/// Wraps [MyEventsPanelBody] in a [ProviderScope] with the dummy overrides
/// from `my_events_dummy_overrides.dart` and a fake auth user. Use only for
/// visual / interaction iteration; not exported from the package barrel.
class MyEventsDummyPreview extends StatelessWidget {
  const MyEventsDummyPreview({super.key});

  @override
  Widget build(BuildContext context) {
    return ProviderScope(
      overrides: [
        authStateProvider.overrideWith(StaticAuthNotifier.new),
        ...myEventsDummyOverrides(),
      ],
      child: ShadApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 480,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: DashboardEventNav(
                      onAdminEventTap: (_) {},
                      onMyEventTap: (_, _) {},
                      onSeeMoreNotifications: () {},
                      onSeeMorePendingActions: () {},
                      onNotificationDeepLink: (_) {},
                      onHome: () {},
                      child: const MyEventsPanelBody(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class StaticAuthNotifier extends AuthNotifier {
  static final UserPrivate _user = UserPrivate(
    username: 'demo_user',
    publicId: 'demo',
    displayName: 'Demo User',
    roles: const UserRoles(),
    status: UserStatus.active,
    isSuperAdmin: false,
    createdAtUtc: DateTime.now().toUtc(),
  );

  @override
  Future<UserPrivate?> build() async => _user;
}
