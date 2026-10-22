import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_member_zone/cl_member_zone.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show LoadingView;

const _username = 'issue162_member';

UserPrivate _member() => UserPrivate(
  username: _username,
  displayName: 'Issue 162 Member',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(),
  createdAtUtc: DateTime.utc(2026),
);

class _StaticAuthNotifier extends AuthNotifier {
  @override
  Future<UserPrivate?> build() async => _member();
}

void main() {
  testWidgets('Issue 162: a change to the signed-in user keeps My Events '
      'and the search being typed', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authStateProvider.overrideWith(_StaticAuthNotifier.new),
          clMyEventsAggregatedProvider(
            _username,
          ).overrideWith((ref) async => const <AggregatedMyEvent>[]),
        ],
        child: ShadApp(
          home: Scaffold(
            body: MyEventsAllScreen(targetUsername: _username, onHome: () {}),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText), 'camp');
    await tester.pump();

    // A profile save hands the returned user to the session, as
    // syncSignedInUser does; the access gate watches it and reloads.
    ProviderScope.containerOf(
      tester.element(find.byType(MyEventsAllScreen)),
    ).read(authStateProvider.notifier).setUser(_member());
    await tester.pump();
    expect(find.byType(LoadingView), findsNothing);

    await tester.pumpAndSettle();
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      'camp',
    );
  });
}
