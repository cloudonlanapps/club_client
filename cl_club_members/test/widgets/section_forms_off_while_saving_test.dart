import 'dart:async';

import 'package:cl_club_forms/cl_club_forms.dart'
    show
        GroupEligibilityForm,
        UserAddressForm,
        UserContactForm,
        UserFormFields,
        UserPersonalDetailsForm;
import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_form_fields.dart'
    show AgeEligibilityFormFields;
import 'package:cl_club_members/src/views/user_profile_view.dart'
    show AddressCard, PersonalDetailsCard;
import 'package:cl_club_members/src/widgets/group_eligibility_section.dart';
import 'package:cl_club_members/src/widgets/user_contact_info_card.dart';
import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        ClGroupsMasterNotifier,
        ClUsersMasterNotifier,
        clGroupMembersProvider,
        clGroupsMasterProvider,
        clUsersMasterProvider,
        defaultCountryCodeProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

const _refusal = ServerException(
  statusCode: 500,
  code: 'INTERNAL',
  message: 'raw server text',
);

class _StubAuthNotifier extends AuthNotifier {
  _StubAuthNotifier(this.user);

  final UserPrivate user;

  @override
  Future<UserPrivate?> build() async => user;
}

/// Holds every update until [answer] completes, then refuses it.
class _HeldUsers extends ClUsersMasterNotifier {
  final Completer<void> answer = Completer<void>();

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
  }) async {
    await answer.future;
    throw _refusal;
  }
}

/// Holds every update until [answer] completes, then refuses it.
class _HeldGroups extends ClGroupsMasterNotifier {
  _HeldGroups(this.group);

  final Group group;
  final Completer<void> answer = Completer<void>();

  @override
  Future<Map<int, Group>> build() async => {group.id: group};

  @override
  Future<Group> updateGroup(
    int id, {
    String? name,
    String? Function()? description,
    Age? Function()? minAge,
    Age? Function()? maxAge,
    bool? strictAge,
    Gender? Function()? gender,
    bool? semiAuto,
  }) async {
    await answer.future;
    throw _refusal;
  }
}

UserPrivate _user(String username, {bool isAdmin = false}) => UserPrivate(
  username: username,
  displayName: 'Robin',
  firstName: 'Robin',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: UserRoles(isAdmin: isAdmin),
  email: '$username@example.test',
  phone: '+919876543210',
  createdAtUtc: DateTime.utc(2024, 6, 15),
);

Finder _field(String id) =>
    find.byWidgetPredicate((w) => w is ShadInputFormField && w.id == id);

/// Pumps a user section [card], the server holding its save, and opens its
/// editor.
Future<_HeldUsers> _pumpUserCard(WidgetTester tester, Widget card) async {
  await tester.binding.setSurfaceSize(const Size(800, 1800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final users = _HeldUsers();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(
          () => _StubAuthNotifier(_user('viewer', isAdmin: true)),
        ),
        clUsersMasterProvider.overrideWith(() => users),
        defaultCountryCodeProvider.overrideWithValue('91'),
      ],
      child: ShadApp(
        home: ShadToaster(
          child: Scaffold(body: SingleChildScrollView(child: card)),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(LucideIcons.pencil));
  await tester.pumpAndSettle();
  return users;
}

/// Taps Save, checks the form (read by [formOn]) is off while the server
/// holds the save, lets the server refuse it, and checks the form is on
/// again in the editor, still open.
Future<void> _saveAndExpectOffThenOn(
  WidgetTester tester, {
  required Completer<void> answer,
  required bool Function() formOn,
}) async {
  expect(formOn(), isTrue, reason: 'on before Save');
  await tester.tap(find.widgetWithText(ShadButton, 'Save'));
  await tester.pump();
  expect(formOn(), isFalse, reason: 'off while the save is in flight');

  answer.complete();
  await tester.pumpAndSettle();
  expect(formOn(), isTrue, reason: 'on again once the save is refused');
}

void main() {
  group('Issue 91: a section form is off while its save is in flight', () {
    testWidgets('Issue 91: user contact', (tester) async {
      final users = await _pumpUserCard(
        tester,
        UserContactInfoCard(user: _user('robin'), canEdit: true),
      );
      await tester.enterText(
        _field(UserFormFields.emailId),
        'sam@example.test',
      );

      await _saveAndExpectOffThenOn(
        tester,
        answer: users.answer,
        formOn: () => tester
            .widget<UserContactForm>(find.byType(UserContactForm))
            .enabled,
      );
    });

    testWidgets('Issue 91: user personal details', (tester) async {
      final users = await _pumpUserCard(
        tester,
        PersonalDetailsCard(user: _user('robin'), canEdit: true),
      );
      await tester.enterText(_field(UserFormFields.firstNameId), 'Sam');

      await _saveAndExpectOffThenOn(
        tester,
        answer: users.answer,
        formOn: () => tester
            .widget<UserPersonalDetailsForm>(
              find.byType(UserPersonalDetailsForm),
            )
            .enabled,
      );
    });

    testWidgets('Issue 91: user address', (tester) async {
      final users = await _pumpUserCard(
        tester,
        AddressCard(user: _user('robin'), canEdit: true),
      );
      await tester.enterText(_field(UserFormFields.cityId), 'Springfield');

      await _saveAndExpectOffThenOn(
        tester,
        answer: users.answer,
        formOn: () => tester
            .widget<UserAddressForm>(find.byType(UserAddressForm))
            .enabled,
      );
    });

    testWidgets('Issue 91: group eligibility', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final groups = _HeldGroups(
        Group(
          id: 7,
          name: 'Juniors',
          kind: GroupKind.semiAuto,
          minAge: const Age(years: 5),
          createdAtUtc: DateTime.utc(2025),
        ),
      );
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            clGroupsMasterProvider.overrideWith(() => groups),
            clGroupMembersProvider.overrideWith(
              (ref, id) async => const <GroupMember>[],
            ),
          ],
          child: ShadApp(
            home: ShadToaster(
              child: Scaffold(
                body: SingleChildScrollView(
                  child: GroupEligibilitySection(
                    group: groups.group,
                    canEdit: true,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(LucideIcons.pencil));
      await tester.pumpAndSettle();
      await tester.enterText(
        _field(AgeEligibilityFormFields.maxAgeYearsId),
        '12',
      );
      await tester.pumpAndSettle();

      await _saveAndExpectOffThenOn(
        tester,
        answer: groups.answer,
        formOn: () => tester
            .widget<GroupEligibilityForm>(find.byType(GroupEligibilityForm))
            .enabled,
      );
    });
  });
}
