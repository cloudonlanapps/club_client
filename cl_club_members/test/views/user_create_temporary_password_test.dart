import 'package:cl_club_forms/cl_club_forms.dart'
    show SignupGender, UserForm, UserFormFields, UserFormState;
import 'package:cl_club_members/src/views/user_create_view.dart';
import 'package:cl_club_members/src/widgets/default_password_dialog.dart';
import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        ClUsersMasterNotifier,
        clUsersMasterProvider,
        defaultCountryCodeProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class _Admin extends AuthNotifier {
  @override
  Future<UserPrivate?> build() async => UserPrivate(
    username: 'admin',
    displayName: 'Admin',
    status: UserStatus.active,
    isSuperAdmin: false,
    roles: const UserRoles(isAdmin: true),
    createdAtUtc: DateTime.utc(2024, 6, 15),
  );
}

/// Records the password each creation sends.
class _Users extends ClUsersMasterNotifier {
  _Users(this.sent);

  final List<String> sent;

  @override
  Future<Map<String, UserInfo>> build() async => {};

  @override
  Future<UserPrivate> createUser({
    required String username,
    required String email,
    required String passwordHash,
    required String phone,
    required DateTime dateOfBirthUtc,
    required Gender gender,
    String? firstName,
    String? middleName,
    String? lastName,
    String? bio,
    String? achievements,
    String? emergencyContact,
    String? medicalNotes,
    Address? address,
  }) async {
    sent.add(passwordHash);
    return UserPrivate(
      username: username,
      displayName: username,
      status: UserStatus.active,
      isSuperAdmin: false,
      roles: const UserRoles(),
      createdAtUtc: DateTime.utc(2024, 6, 15),
    );
  }
}

Finder _field(String id) =>
    find.byWidgetPredicate((w) => w is ShadInputFormField && w.id == id);

/// Opens a fresh New User page, reads the password Show reveals, and
/// creates [username] with "Use default password" left ticked. Returns the
/// password shown.
Future<String> _createWithDefaultPassword(
  WidgetTester tester,
  String username,
  List<String> sent,
) async {
  await tester.pumpWidget(
    ProviderScope(
      key: UniqueKey(),
      overrides: [
        authStateProvider.overrideWith(_Admin.new),
        clUsersMasterProvider.overrideWith(() => _Users(sent)),
        defaultCountryCodeProvider.overrideWithValue('91'),
      ],
      child: ShadApp(
        home: ShadToaster(
          child: Scaffold(
            body: UserCreateView(onCreated: () {}, onCancel: () {}),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.tap(find.text('Show'));
  await tester.pumpAndSettle();
  final shown = tester
      .widget<SelectableText>(
        find.descendant(
          of: find.byType(DefaultPasswordDialog),
          matching: find.byType(SelectableText),
        ),
      )
      .data!;
  await tester.tap(find.text('OK'));
  await tester.pumpAndSettle();

  await tester.enterText(_field(UserFormFields.usernameId), username);
  await tester.enterText(_field(UserFormFields.firstNameId), 'Robin');
  await tester.enterText(_field(UserFormFields.phoneId), '9876543210');
  await tester.enterText(
    _field(UserFormFields.emailId),
    '$username@example.test',
  );
  tester
      .state<UserFormState>(find.byType(UserForm))
      .formKey
      .currentState!
      .setValue({
        UserFormFields.genderId: SignupGender.female,
        UserFormFields.dateOfBirthUtcId: DateTime(2010, 3, 4),
      });
  await tester.pumpAndSettle();
  await tester.tap(find.widgetWithText(ShadButton, 'Create user'));
  await tester.pumpAndSettle();
  return shown;
}

void main() {
  testWidgets('Issue 221: two users created with the default password get '
      'different ones, each the one the dialog showed', (tester) async {
    await tester.binding.setSurfaceSize(const Size(1024, 2400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final sent = <String>[];

    final shownRobin = await _createWithDefaultPassword(tester, 'robin', sent);
    final shownSam = await _createWithDefaultPassword(tester, 'sam', sent);

    expect(sent, [shownRobin, shownSam]);
    expect(shownRobin, isNot(shownSam));
    expect(sent, isNot(contains('ChangeMe123')));
  });
}
