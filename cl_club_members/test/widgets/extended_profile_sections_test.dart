// Issue 320: the extended profile's sections on a member's profile —
// shown only while the server reports the extended profile, to the member
// and admins; each saves its own fields; a refused choice shows on its
// field. The membership date sits in the account section, an admin's.
import 'package:cl_club_forms/cl_club_forms.dart' show UserFormFields;
import 'package:cl_club_members/src/constants/extended_profile_strings.dart';
import 'package:cl_club_members/src/views/user_profile_view.dart';
import 'package:cl_club_members/src/widgets/account_info_section.dart';
import 'package:cl_club_members/src/widgets/extended_profile_sections.dart';
import 'package:cl_club_members/src/widgets/sports_details_card.dart';
import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        ClUsersMasterNotifier,
        ProfileOptionsNotifier,
        avatarImageProvider,
        capabilitiesProvider,
        clUserPrivateProvider,
        clUsersMasterProvider,
        profileOptionsProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class _StubAuthNotifier extends AuthNotifier {
  _StubAuthNotifier(this.user);

  final UserPrivate user;

  @override
  Future<UserPrivate?> build() async => user;
}

class _FixedOptions extends ProfileOptionsNotifier {
  @override
  Future<ProfileOptions> build() async => const ProfileOptions(
    positions: [
      ProfilePosition(value: 'Forward', label: {'en': 'Forward (F)'}),
      ProfilePosition(value: 'Goalie', label: {'en': 'Goalie'}),
    ],
    languages: [
      ProfileLanguage(code: 'en', name: 'English'),
      ProfileLanguage(code: 'mr', name: 'Marathi'),
    ],
  );
}

/// Records the fields of each update, or fails it with [failure].
class _RecordingUsers extends ClUsersMasterNotifier {
  _RecordingUsers({this.failure});

  final Exception? failure;
  final List<Set<String>> sent = [];
  final List<DateTime?> membershipDates = [];

  @override
  Future<Map<String, UserInfo>> build() async => {};

  @override
  Future<UserPrivate> updateUser(
    String username, {
    String? email,
    String? Function()? firstName,
    String? Function()? middleName,
    String? Function()? lastName,
    String? Function()? phone,
    DateTime? Function()? dateOfBirthUtc,
    String? Function()? bio,
    String? Function()? achievements,
    String? Function()? emergencyContact,
    String? Function()? medicalNotes,
    String? Function()? nickname,
    bool? useNamePublicly,
    Gender? Function()? gender,
    Address? Function()? address,
    bool? isPublicProfile,
    String? Function()? clubDistrict,
    List<String>? preferredPositions,
    String? Function()? pastExperience,
    String? Function()? nationality,
    List<String>? preferredLanguages,
    Guardian? Function()? guardian,
    DateTime? Function()? membershipDateUtc,
  }) async {
    final thrown = failure;
    if (thrown != null) throw thrown;
    sent.add({
      if (email != null) 'email',
      if (firstName != null) 'firstName',
      if (phone != null) 'phone',
      if (address != null) 'address',
      if (clubDistrict != null) 'clubDistrict',
      if (preferredPositions != null) 'preferredPositions',
      if (pastExperience != null) 'pastExperience',
      if (nationality != null) 'nationality',
      if (preferredLanguages != null) 'preferredLanguages',
      if (guardian != null) 'guardian',
      if (membershipDateUtc != null) 'membershipDateUtc',
    });
    if (membershipDateUtc != null) membershipDates.add(membershipDateUtc());
    return _user(username);
  }
}

UserPrivate _user(
  String username, {
  bool isAdmin = false,
  bool isCoach = false,
  String? position,
}) => UserPrivate(
  username: username,
  displayName: username,
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: UserRoles(isAdmin: isAdmin, isCoach: isCoach, isMember: true),
  createdAtUtc: DateTime.utc(2024, 6, 15),
  preferredPositions: [?position],
  membershipDateUtc: DateTime.utc(2025, 4, 2),
);

Finder _field(String id) =>
    find.byWidgetPredicate((w) => w is ShadFormBuilderField && w.id == id);

Finder _pencilOf(Key cardKey) => find.descendant(
  of: find.byKey(cardKey),
  matching: find.byIcon(LucideIcons.pencil),
);

Future<void> _pump(
  WidgetTester tester, {
  required Widget child,
  required UserPrivate viewer,
  bool extendedProfile = true,
  _RecordingUsers? users,
  UserPrivate? target,
}) async {
  await tester.binding.setSurfaceSize(const Size(900, 3000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(() => _StubAuthNotifier(viewer)),
        capabilitiesProvider.overrideWith(
          (ref) async => Capabilities(extendedProfile: extendedProfile),
        ),
        profileOptionsProvider.overrideWith(_FixedOptions.new),
        clUsersMasterProvider.overrideWith(() => users ?? _RecordingUsers()),
        if (target != null) ...[
          clUserPrivateProvider(
            target.username,
          ).overrideWith((_) async => target),
          avatarImageProvider(target.username).overrideWith((_) async => null),
        ],
      ],
      child: ShadApp(
        home: ShadToaster(
          child: Scaffold(
            body: target != null ? child : SingleChildScrollView(child: child),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 320: ExtendedProfileSections', () {
    testWidgets('Issue 320: it shows nothing while the extended profile is '
        'off', (tester) async {
      await _pump(
        tester,
        viewer: _user('robin'),
        extendedProfile: false,
        child: ExtendedProfileSections(user: _user('robin'), canEdit: true),
      );

      expect(
        find.text(ExtendedProfileStrings.sportsDetailsTitle),
        findsNothing,
      );
      expect(find.text(ExtendedProfileStrings.guardianTitle), findsNothing);
    });

    testWidgets('Issue 320: it shows the three sections, ready to add to, '
        'while it is on', (tester) async {
      await _pump(
        tester,
        viewer: _user('robin'),
        child: ExtendedProfileSections(user: _user('robin'), canEdit: true),
      );

      for (final title in [
        ExtendedProfileStrings.sportsDetailsTitle,
        ExtendedProfileStrings.backgroundTitle,
        ExtendedProfileStrings.guardianTitle,
      ]) {
        expect(find.text(title), findsOneWidget);
      }
      expect(
        find.text(ExtendedProfileStrings.sportsDetailsEmptyHint),
        findsOneWidget,
      );
    });

    testWidgets("Issue 320: a position reads as the club's English label", (
      tester,
    ) async {
      final user = _user('robin', position: 'Forward');
      await _pump(
        tester,
        viewer: user,
        child: ExtendedProfileSections(user: user, canEdit: true),
      );

      expect(find.text('Forward (F)'), findsOneWidget);
    });

    testWidgets('Issue 320: saving Sports details sends its three fields '
        'alone', (tester) async {
      final users = _RecordingUsers();
      final user = _user('robin', position: 'Forward');
      await _pump(
        tester,
        viewer: user,
        users: users,
        child: ExtendedProfileSections(user: user, canEdit: true),
      );

      await tester.tap(_pencilOf(SportsDetailsCard.cardKey));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: _field(UserFormFields.clubDistrictId),
          matching: find.byType(EditableText),
        ),
        'Pune',
      );
      await tester.tap(find.widgetWithText(ShadButton, 'Save'));
      await tester.pumpAndSettle();

      expect(users.sent, [
        {'clubDistrict', 'preferredPositions', 'pastExperience'},
      ]);
      expect(find.text(ExtendedProfileStrings.sportsDetailsSaved), findsOne);
    });

    testWidgets('Issue 320: a position the club does not offer is refused '
        'on that field, with no toast', (tester) async {
      final users = _RecordingUsers(
        failure: const InvalidProfileOptionException(
          message: 'raw server text',
          field: 'preferredPositions',
          value: 'Forward',
        ),
      );
      final user = _user('robin', position: 'Forward');
      await _pump(
        tester,
        viewer: user,
        users: users,
        child: ExtendedProfileSections(user: user, canEdit: true),
      );

      await tester.tap(_pencilOf(SportsDetailsCard.cardKey));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: _field(UserFormFields.clubDistrictId),
          matching: find.byType(EditableText),
        ),
        'Pune',
      );
      await tester.tap(find.widgetWithText(ShadButton, 'Save'));
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: _field(UserFormFields.preferredPositionsId),
          matching: find.text(ExtendedProfileStrings.optionRefused),
        ),
        findsOneWidget,
      );
      expect(find.text('raw server text'), findsNothing);
    });
  });

  group('Issue 320: who sees the extended profile on a profile', () {
    Future<void> profile(
      WidgetTester tester, {
      required UserPrivate viewer,
      bool extendedProfile = true,
    }) {
      final target = _user('robin');
      return _pump(
        tester,
        viewer: viewer,
        target: target,
        extendedProfile: extendedProfile,
        child: UserProfileView(targetUsername: target.username),
      );
    }

    Finder sections() => find.byType(ExtendedProfileSections);

    testWidgets('Issue 320: the member sees their own', (tester) async {
      await profile(tester, viewer: _user('robin'));
      expect(sections(), findsOneWidget);
      expect(find.text(ExtendedProfileStrings.guardianTitle), findsOneWidget);
    });

    testWidgets('Issue 320: an admin sees a member', (tester) async {
      await profile(tester, viewer: _user('admin1', isAdmin: true));
      expect(sections(), findsOneWidget);
    });

    testWidgets('Issue 320: a coach viewing a member does not', (tester) async {
      await profile(tester, viewer: _user('coach1', isCoach: true));
      expect(sections(), findsNothing);
    });

    testWidgets('Issue 320: with the extended profile off, no section and '
        'no membership date', (tester) async {
      await profile(
        tester,
        viewer: _user('admin1', isAdmin: true),
        extendedProfile: false,
      );
      expect(find.text(ExtendedProfileStrings.guardianTitle), findsNothing);
      expect(find.text(ExtendedProfileStrings.membershipDate), findsNothing);
      expect(_pencilOf(AccountInfoSection.cardKey), findsNothing);
    });

    testWidgets('Issue 320: the member reads their membership date and '
        'cannot change it', (tester) async {
      await profile(tester, viewer: _user('robin'));
      expect(find.text(ExtendedProfileStrings.membershipDate), findsOneWidget);
      expect(find.text('2 Apr 2025'), findsOneWidget);
      expect(_pencilOf(AccountInfoSection.cardKey), findsNothing);
    });
  });

  group('Issue 320: the membership date in the account section', () {
    testWidgets('Issue 320: an admin corrects it, sending it alone', (
      tester,
    ) async {
      final users = _RecordingUsers();
      await _pump(
        tester,
        viewer: _user('admin1', isAdmin: true),
        users: users,
        child: AccountInfoSection(
          user: _user('robin'),
          canEditMembershipDate: true,
        ),
      );

      await tester.tap(_pencilOf(AccountInfoSection.cardKey));
      await tester.pumpAndSettle();
      tester
          .state<FormFieldState<dynamic>>(
            _field(UserFormFields.membershipDateUtcId),
          )
          .didChange(DateTime(2025, 5, 9));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ShadButton, 'Save'));
      await tester.pumpAndSettle();

      expect(users.sent, [
        {'membershipDateUtc'},
      ]);
      expect(users.membershipDates, [DateTime.utc(2025, 5, 9)]);
    });
  });
}
