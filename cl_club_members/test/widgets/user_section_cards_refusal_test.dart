// Issue 97: the Personal details and Address editors show a refused save
// where it belongs: on the field the server names, or in a toast.
import 'dart:async';

import 'package:cl_club_forms/cl_club_forms.dart' show UserFormFields;
import 'package:cl_club_members/src/models/user_form_helpers.dart';
import 'package:cl_club_members/src/utils/member_write_messages.dart';
import 'package:cl_club_members/src/views/user_profile_view.dart';
import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClUsersMasterNotifier, clUsersMasterProvider;
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

/// Fails every update with [failure].
class _FailingUsers extends ClUsersMasterNotifier {
  _FailingUsers(this.failure);

  final Exception failure;

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
  }) async => throw failure;
}

UserPrivate _user(String username, {bool isSuperAdmin = false}) => UserPrivate(
  username: username,
  displayName: 'Robin',
  status: UserStatus.active,
  isSuperAdmin: isSuperAdmin,
  roles: const UserRoles(isAdmin: true),
  firstName: 'Robin',
  email: '$username@example.test',
  gender: Gender.female,
  dateOfBirthUtc: DateTime.utc(2000),
  address: const Address(addrLine1: '1 Rink Rd', city: 'Pune'),
  createdAtUtc: DateTime.utc(2024, 6, 15),
);

Finder _field(String id) =>
    find.byWidgetPredicate((w) => w is ShadFormBuilderField && w.id == id);

/// Opens [card]'s editor, types [text] into [fieldId] and saves, the save
/// failing with [failure].
Future<void> _saveFailing(
  WidgetTester tester, {
  required Widget card,
  required String fieldId,
  required String text,
  required Exception failure,
  bool superAdmin = false,
}) async {
  await tester.binding.setSurfaceSize(const Size(800, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(
          () => _StubAuthNotifier(_user('viewer', isSuperAdmin: superAdmin)),
        ),
        clUsersMasterProvider.overrideWith(() => _FailingUsers(failure)),
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
  await tester.enterText(
    find.descendant(of: _field(fieldId), matching: find.byType(EditableText)),
    text,
  );
  await tester.tap(find.widgetWithText(ShadButton, 'Save'));
  await tester.pumpAndSettle();
}

ServerException _refused(
  String code, {
  int status = 422,
  Map<String, dynamic>? details,
}) => ServerException(
  statusCode: status,
  code: code,
  message: 'raw server text',
  details: details,
);

void _expectEditorOn(WidgetTester tester, String fieldId) {
  expect(
    tester.widget<ShadFormBuilderField<dynamic>>(_field(fieldId)).enabled,
    isTrue,
  );
  expect(
    tester
        .widget<ShadButton>(find.widgetWithText(ShadButton, 'Save'))
        .onPressed,
    isNotNull,
  );
}

void main() {
  group('Issue 97: the Personal details editor shows a refusal where it '
      'belongs', () {
    Widget card() => PersonalDetailsCard(user: _user('robin'), canEdit: true);

    testWidgets('Issue 97: a date of birth the server does not take shows '
        'on that field, with no toast, and the editor is on again', (
      tester,
    ) async {
      await _saveFailing(
        tester,
        card: card(),
        fieldId: UserFormFields.firstNameId,
        text: 'Sam',
        superAdmin: true,
        failure: _refused(SdkErrorCode.invalidDobNotUtcMidnight),
      );

      expect(
        find.descendant(
          of: _field(UserFormFields.dateOfBirthUtcId),
          matching: find.text(MemberWriteMessages.dateOfBirthRefused),
        ),
        findsOneWidget,
      );
      expect(find.byType(ShadToast), findsNothing);
      expect(find.textContaining('raw server text'), findsNothing);
      _expectEditorOn(tester, UserFormFields.firstNameId);
    });

    testWidgets('Issue 97: fields only a super admin may change, refused, '
        'each show the message on their field', (tester) async {
      await _saveFailing(
        tester,
        card: card(),
        fieldId: UserFormFields.firstNameId,
        text: 'Sam',
        superAdmin: true,
        failure: _refused(
          UserFormSubmit.protectedFieldsCode,
          status: 403,
          details: const {
            'fields': ['gender', 'dateOfBirthUtc'],
          },
        ),
      );

      for (final id in [
        UserFormFields.genderId,
        UserFormFields.dateOfBirthUtcId,
      ]) {
        expect(
          find.descendant(
            of: _field(id),
            matching: find.text(MemberWriteMessages.protectedField),
          ),
          findsOneWidget,
        );
      }
      expect(find.byType(ShadToast), findsNothing);
    });

    testWidgets('Issue 97: a server that cannot be reached is a toast, and '
        'the editor is on again', (tester) async {
      await _saveFailing(
        tester,
        card: card(),
        fieldId: UserFormFields.firstNameId,
        text: 'Sam',
        failure: TimeoutException('connection closed'),
      );

      expect(find.byType(ShadToast), findsOneWidget);
      expect(find.text('Could not save. Please try again.'), findsOneWidget);
      expect(find.textContaining('connection closed'), findsNothing);
      _expectEditorOn(tester, UserFormFields.firstNameId);
    });
  });

  group('Issue 97: the Address editor reports a failed save in a toast', () {
    testWidgets('Issue 97: the server names no field of an address, so a '
        'failed save is a toast and the editor is on again', (tester) async {
      await _saveFailing(
        tester,
        card: AddressCard(user: _user('robin'), canEdit: true),
        fieldId: UserFormFields.cityId,
        text: 'Mumbai',
        failure: _refused('SOMETHING_NEW'),
      );

      expect(find.byType(ShadToast), findsOneWidget);
      expect(find.text('Could not save. Please try again.'), findsOneWidget);
      expect(find.textContaining('raw server text'), findsNothing);
      _expectEditorOn(tester, UserFormFields.cityId);
    });
  });
}
