// Issue 335: a member chooses any number of preferred positions and
// languages, ticked in the Sports details and Background cards. The cards
// read every chosen value; a value the club removed later stays ticked and
// is sent back unchanged; none ticked sends an empty list.
import 'package:cl_club_forms/cl_club_forms.dart' show UserFormFields;
import 'package:cl_club_members/src/constants/extended_profile_strings.dart';
import 'package:cl_club_members/src/widgets/background_card.dart';
import 'package:cl_club_members/src/widgets/sports_details_card.dart';
import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        ClUsersMasterNotifier,
        ProfileOptionsNotifier,
        capabilitiesProvider,
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
      ProfilePosition(value: 'Defense', label: {'en': 'Defence'}),
      ProfilePosition(value: 'Goalie', label: {'en': 'Goalie'}),
    ],
    languages: ['English', 'Marathi', 'Hindi'],
  );
}

/// Records the lists each update sends.
class _RecordingUsers extends ClUsersMasterNotifier {
  final List<List<String>?> positions = [];
  final List<List<String>?> languages = [];

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
    if (preferredPositions != null) positions.add(preferredPositions);
    if (preferredLanguages != null) languages.add(preferredLanguages);
    return _user(username);
  }
}

UserPrivate _user(
  String username, {
  List<String> positions = const [],
  List<String> languages = const [],
}) => UserPrivate(
  username: username,
  displayName: username,
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(isMember: true),
  createdAtUtc: DateTime.utc(2024, 6, 15),
  preferredPositions: positions,
  preferredLanguages: languages,
);

Finder _field(String id) =>
    find.byWidgetPredicate((w) => w is ShadFormBuilderField && w.id == id);

Finder _box(String id, String label) => find.descendant(
  of: _field(id),
  matching: find.widgetWithText(ShadCheckbox, label),
);

bool _ticked(WidgetTester tester, String id, String label) =>
    tester.widget<ShadCheckbox>(_box(id, label)).value;

Future<void> _tick(WidgetTester tester, String id, String label) async {
  await tester.tap(_box(id, label), warnIfMissed: false);
  await tester.pumpAndSettle();
}

Future<void> _edit(WidgetTester tester, Key cardKey) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(cardKey),
      matching: find.byIcon(LucideIcons.pencil),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester, Key cardKey) async {
  await tester.tap(
    find.descendant(
      of: find.byKey(cardKey),
      matching: find.widgetWithText(ShadButton, 'Save'),
    ),
  );
  await tester.pumpAndSettle();
}

Future<_RecordingUsers> _pump(WidgetTester tester, UserPrivate user) async {
  await tester.binding.setSurfaceSize(const Size(900, 3000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final users = _RecordingUsers();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(() => _StubAuthNotifier(user)),
        capabilitiesProvider.overrideWith(
          (ref) async => const Capabilities(extendedProfile: true),
        ),
        profileOptionsProvider.overrideWith(_FixedOptions.new),
        clUsersMasterProvider.overrideWith(() => users),
      ],
      child: ShadApp(
        home: ShadToaster(
          child: Scaffold(
            body: SingleChildScrollView(
              child: Column(
                children: [
                  SportsDetailsCard(user: user, canEdit: true),
                  BackgroundCard(user: user, canEdit: true),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return users;
}

void main() {
  group('Issue 335: several preferred positions and languages', () {
    testWidgets('Issue 335: two positions and two languages ticked are '
        'both saved', (tester) async {
      final users = await _pump(tester, _user('robin'));

      await _edit(tester, SportsDetailsCard.cardKey);
      await _tick(tester, UserFormFields.preferredPositionsId, 'Forward (F)');
      await _tick(tester, UserFormFields.preferredPositionsId, 'Goalie');
      await _save(tester, SportsDetailsCard.cardKey);

      await _edit(tester, BackgroundCard.cardKey);
      await _tick(tester, UserFormFields.preferredLanguagesId, 'Marathi');
      await _tick(tester, UserFormFields.preferredLanguagesId, 'English');
      await _save(tester, BackgroundCard.cardKey);

      expect(users.positions, [
        ['Forward', 'Goalie'],
      ]);
      expect(users.languages, [
        ['English', 'Marathi'],
      ]);
    });

    testWidgets('Issue 335: the cards read every chosen value', (
      tester,
    ) async {
      await _pump(
        tester,
        _user(
          'robin',
          positions: ['Forward', 'Goalie'],
          languages: ['Marathi', 'Hindi'],
        ),
      );

      expect(find.text(ExtendedProfileStrings.preferredPositions), findsOne);
      expect(find.text('Forward (F), Goalie'), findsOneWidget);
      expect(find.text(ExtendedProfileStrings.preferredLanguages), findsOne);
      expect(find.text('Marathi, Hindi'), findsOneWidget);
    });

    testWidgets('Issue 335: a value the club removed stays ticked and is '
        'sent back unchanged', (tester) async {
      final users = await _pump(
        tester,
        _user('robin', positions: ['Centre', 'Goalie'], languages: ['Tamil']),
      );

      expect(find.text('Centre, Goalie'), findsOneWidget);
      expect(find.text('Tamil'), findsOneWidget);

      await _edit(tester, SportsDetailsCard.cardKey);
      expect(
        _ticked(tester, UserFormFields.preferredPositionsId, 'Centre'),
        isTrue,
      );
      await tester.enterText(
        find.descendant(
          of: _field(UserFormFields.clubDistrictId),
          matching: find.byType(EditableText),
        ),
        'Pune',
      );
      await _save(tester, SportsDetailsCard.cardKey);

      await _edit(tester, BackgroundCard.cardKey);
      expect(
        _ticked(tester, UserFormFields.preferredLanguagesId, 'Tamil'),
        isTrue,
      );
      await _tick(tester, UserFormFields.preferredLanguagesId, 'Hindi');
      await _save(tester, BackgroundCard.cardKey);

      expect(users.positions, [
        ['Centre', 'Goalie'],
      ]);
      expect(users.languages, [
        ['Hindi', 'Tamil'],
      ]);
    });

    testWidgets('Issue 335: none ticked sends an empty list', (tester) async {
      final users = await _pump(
        tester,
        _user('robin', positions: ['Goalie'], languages: ['English']),
      );

      await _edit(tester, SportsDetailsCard.cardKey);
      await _tick(tester, UserFormFields.preferredPositionsId, 'Goalie');
      await _save(tester, SportsDetailsCard.cardKey);

      await _edit(tester, BackgroundCard.cardKey);
      await _tick(tester, UserFormFields.preferredLanguagesId, 'English');
      await _save(tester, BackgroundCard.cardKey);

      expect(users.positions, [<String>[]]);
      expect(users.languages, [<String>[]]);
    });

    testWidgets('Issue 335: an unchanged list is not a change', (
      tester,
    ) async {
      final users = await _pump(
        tester,
        _user('robin', positions: ['Forward', 'Goalie']),
      );

      await _edit(tester, SportsDetailsCard.cardKey);
      await _save(tester, SportsDetailsCard.cardKey);

      expect(users.positions, isEmpty);
    });
  });
}
