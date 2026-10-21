import 'package:cl_club_forms/cl_club_forms.dart' show UserAddressForm;
import 'package:cl_club_members/src/views/user_profile_view.dart'
    show UserProfileView;
import 'package:cl_club_members/src/widgets/address_card.dart';
import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show avatarImageProvider, clUserGroupsProvider, clUserPrivateProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show LoadingView;

class _StubAuthNotifier extends AuthNotifier {
  _StubAuthNotifier(this._user);
  final UserPrivate? _user;
  @override
  Future<UserPrivate?> build() async => _user;
}

UserPrivate _user(String username, {bool isAdmin = false, String? bio}) =>
    UserPrivate(
      username: username,
      displayName: username,
      status: UserStatus.active,
      isSuperAdmin: false,
      roles: UserRoles(isAdmin: isAdmin),
      bio: bio,
      createdAtUtc: DateTime.utc(2024, 6, 15),
    );

/// How many sections have saved; the profile provider follows it, as it
/// follows the user's entry in the master.
final _saves = StateProvider<int>((_) => 0);

void main() {
  testWidgets('Issue 229: saving one profile section keeps the page and the '
      'other sections on screen', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1400, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final container = ProviderContainer(
      overrides: [
        clUserPrivateProvider('robin').overrideWith((ref) async {
          final saves = ref.watch(_saves);
          return _user('robin', bio: 'saved $saves times');
        }),
        clUserGroupsProvider('robin').overrideWith((_) async => const []),
        authStateProvider.overrideWith(
          () => _StubAuthNotifier(_user('admin1', isAdmin: true)),
        ),
        avatarImageProvider('robin').overrideWith((_) async => null),
      ],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const ShadApp(
          home: Scaffold(body: UserProfileView(targetUsername: 'robin')),
        ),
      ),
    );
    await tester.pumpAndSettle();
    // Open the Address editor: the state another section's save must keep.
    await tester.tap(
      find.descendant(
        of: find.byType(AddressCard),
        matching: find.byIcon(LucideIcons.pencil),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(UserAddressForm), findsOneWidget);

    // Another section saves; the profile provider reloads with the answer.
    container.read(_saves.notifier).state++;
    for (var i = 0; i < 5; i++) {
      await tester.pump();
      expect(find.byType(LoadingView), findsNothing);
    }
    await tester.pumpAndSettle();

    expect(find.byType(LoadingView), findsNothing);
    expect(
      find.byType(UserAddressForm),
      findsOneWidget,
      reason: 'the Address editor stays open',
    );
  });
}
