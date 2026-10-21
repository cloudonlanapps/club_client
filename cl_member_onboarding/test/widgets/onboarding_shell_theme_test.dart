import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_member_onboarding/cl_member_onboarding.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show ContactInfo, contactInfoProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class _StubAuth extends AuthNotifier {
  @override
  Future<UserPrivate?> build() async => UserPrivate(
    username: 'u1',
    displayName: 'U One',
    status: UserStatus.registered,
    isSuperAdmin: false,
    roles: const UserRoles(),
    createdAtUtc: DateTime.utc(2024),
    email: 'u1@example.com',
  );
}

void main() {
  testWidgets(
    "Issue 244: the onboarding app bar's bottom line is the theme's border "
    'colour in dark mode',
    (tester) async {
      final dark = ShadThemeData(
        brightness: Brightness.dark,
        colorScheme: const ShadSlateColorScheme.dark(),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authStateProvider.overrideWith(_StubAuth.new),
            contactInfoProvider.overrideWithValue(
              const ContactInfo(
                clubName: 'Club',
                phoneNumber: '+10000000000',
                email: 'club@example.com',
              ),
            ),
          ],
          child: ShadApp(
            themeMode: ThemeMode.dark,
            darkTheme: dark,
            home: OnboardingShell(
              title: (_) => 'Welcome',
              child: const SizedBox.shrink(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();

      final bars = tester
          .widgetList<Container>(find.byType(Container))
          .map((c) => c.decoration)
          .whereType<BoxDecoration>()
          .map((d) => d.border)
          .whereType<Border>()
          .where((b) => b.bottom != BorderSide.none && b.top == BorderSide.none)
          .toList();
      expect(bars, isNotEmpty, reason: 'the app bar has a bottom border');
      expect(bars.first.bottom.color, dark.colorScheme.border);
    },
  );
}
