// Issue 340: a pending member's own profile cards on onboarding's profile
// page — the profile's cards, every one editable, the extended sections
// only while the server has the extended profile on.
import 'package:cl_club_members/cl_club_members.dart' show OwnProfileCards;
import 'package:cl_club_members/src/constants/extended_profile_strings.dart';
import 'package:cl_club_members/src/widgets/profile_credit_line.dart';
import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        ClUsersMasterNotifier,
        ProfileOptionsNotifier,
        avatarImageProvider,
        clUsersMasterProvider,
        creditSystemProvider,
        extendedProfileProvider,
        profileOptionsProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show EditableSectionCard, SectionEditButton;

class _StubAuth extends AuthNotifier {
  _StubAuth(this.user);

  final UserPrivate user;

  @override
  Future<UserPrivate?> build() async => user;
}

class _NoOptions extends ProfileOptionsNotifier {
  @override
  Future<ProfileOptions> build() async =>
      const ProfileOptions(positions: [], languages: []);
}

class _NoUsers extends ClUsersMasterNotifier {
  @override
  Future<Map<String, UserInfo>> build() async => {};
}

final UserPrivate _pending = UserPrivate(
  username: 'robin',
  displayName: 'Robin',
  status: UserStatus.pending,
  isSuperAdmin: false,
  roles: const UserRoles(),
  createdAtUtc: DateTime.utc(2024, 6, 15),
  email: 'robin@example.com',
  phone: '+919800000000',
  address: const Address(addrLine1: '1 Rink Road', city: 'Pune'),
);

Future<void> _pump(
  WidgetTester tester, {
  required bool? extendedProfile,
  bool creditSystem = false,
}) async {
  await tester.binding.setSurfaceSize(const Size(900, 4000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(() => _StubAuth(_pending)),
        extendedProfileProvider.overrideWithValue(extendedProfile),
        creditSystemProvider.overrideWithValue(creditSystem),
        profileOptionsProvider.overrideWith(_NoOptions.new),
        clUsersMasterProvider.overrideWith(_NoUsers.new),
        avatarImageProvider(_pending.username).overrideWith((_) async => null),
      ],
      child: ShadApp(
        home: ShadToaster(
          child: Scaffold(
            body: SingleChildScrollView(child: OwnProfileCards(user: _pending)),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Finder _card(String title) => find.byWidgetPredicate(
  (w) => w is EditableSectionCard && w.title == title,
);

void main() {
  group('Issue 340: OwnProfileCards', () {
    testWidgets('Issue 340: a pending member may edit every card of their '
        'own profile', (tester) async {
      await _pump(tester, extendedProfile: true);

      for (final title in [
        'Personal details',
        'Contact',
        'Address',
        ExtendedProfileStrings.sportsDetailsTitle,
        ExtendedProfileStrings.backgroundTitle,
        ExtendedProfileStrings.guardianTitle,
      ]) {
        final card = _card(title);
        expect(card, findsOneWidget, reason: title);
        final editable = tester.widget<EditableSectionCard<dynamic>>(card);
        expect(editable.canEdit, isTrue, reason: title);
      }
      expect(find.text('Tap to add bio'), findsOneWidget);
    });

    testWidgets('Issue 340: the edit button of a pending member’s card opens '
        'its editor', (tester) async {
      await _pump(tester, extendedProfile: false);

      await tester.tap(
        find.descendant(
          of: _card('Address'),
          matching: find.byType(SectionEditButton),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(of: _card('Address'), matching: find.text('Save')),
        findsOneWidget,
      );
    });

    for (final flag in [false, null]) {
      testWidgets('Issue 340: no extended section while the extended '
          'profile is $flag', (tester) async {
        await _pump(tester, extendedProfile: flag);

        expect(_card('Address'), findsOneWidget);
        for (final title in [
          ExtendedProfileStrings.sportsDetailsTitle,
          ExtendedProfileStrings.backgroundTitle,
          ExtendedProfileStrings.guardianTitle,
        ]) {
          expect(find.text(title), findsNothing, reason: title);
        }
      });
    }

    testWidgets('Issue 340: a pending member’s own card shows no credit, '
        'which the server answers to active members only', (tester) async {
      await _pump(tester, extendedProfile: false, creditSystem: true);

      expect(find.byType(ProfileCreditLine), findsOneWidget);
      expect(find.bySemanticsLabel(RegExp('Credit')), findsNothing);
    });
  });
}
