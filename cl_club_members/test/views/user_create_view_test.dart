import 'package:cl_club_forms/cl_club_forms.dart'
    show SignupGender, UserForm, UserFormFields, UserFormState;
import 'package:cl_club_members/src/views/user_create_view.dart';
import 'package:cl_member_auth/cl_member_auth.dart'
    show
        AuthNotifier,
        UsernameAvailability,
        authStateProvider,
        usernameAvailabilityProvider;
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

class _StubAuthNotifier extends AuthNotifier {
  @override
  Future<UserPrivate?> build() async => UserPrivate(
    username: 'admin',
    displayName: 'Admin',
    status: UserStatus.active,
    isSuperAdmin: false,
    roles: const UserRoles(isAdmin: true),
    email: 'admin@example.test',
    createdAtUtc: DateTime.utc(2024, 6, 15),
  );
}

/// Creates nothing: answers every creation with [refusal], or records the
/// username when there is none.
class _Users extends ClUsersMasterNotifier {
  _Users(this.refusal);

  final ServerException? refusal;
  final created = <String>[];

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
    final refusal = this.refusal;
    if (refusal != null) throw refusal;
    created.add(username);
    return UserPrivate(
      username: username,
      displayName: username,
      status: UserStatus.active,
      isSuperAdmin: false,
      roles: const UserRoles(),
      email: email,
      createdAtUtc: DateTime.utc(2024, 6, 15),
    );
  }
}

Finder _field(String id) =>
    find.byWidgetPredicate((w) => w is ShadInputFormField && w.id == id);

Finder _createUser() => find.widgetWithText(ShadButton, 'Create user');

Future<_Users> _pump(
  WidgetTester tester, {
  String? refusalCode,
  VoidCallback? onCreated,
  VoidCallback? onCancel,
  String countryCode = '91',
}) async {
  await tester.binding.setSurfaceSize(const Size(1024, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final users = _Users(
    refusalCode == null
        ? null
        : ServerException(
            statusCode: 409,
            code: refusalCode,
            message: 'raw server text',
          ),
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(_StubAuthNotifier.new),
        clUsersMasterProvider.overrideWith(() => users),
        usernameAvailabilityProvider.overrideWith(
          (ref, username) async => UsernameAvailability.available,
        ),
        defaultCountryCodeProvider.overrideWithValue(countryCode),
      ],
      child: ShadApp(
        home: ShadToaster(
          child: Scaffold(
            body: UserCreateView(
              onCreated: onCreated ?? () {},
              onCancel: onCancel ?? () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return users;
}

/// Fills the form, the username confirmed available, and taps Create user.
Future<void> _fillAndSubmit(WidgetTester tester) async {
  await tester.enterText(_field(UserFormFields.usernameId), 'robin');
  await tester.pumpAndSettle();
  await tester.tap(find.text('Check availability'));
  await tester.pumpAndSettle();
  await tester.enterText(_field(UserFormFields.firstNameId), 'Robin');
  await tester.enterText(_field(UserFormFields.phoneId), '9876543210');
  await tester.enterText(_field(UserFormFields.emailId), 'robin@example.test');
  tester
      .state<UserFormState>(find.byType(UserForm))
      .formKey
      .currentState!
      .setValue({
        UserFormFields.genderId: SignupGender.female,
        UserFormFields.dateOfBirthUtcId: DateTime(2010, 3, 4),
      });
  await tester.pumpAndSettle();
  await tester.tap(_createUser());
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 53: UserCreateView owns the title, the buttons and the '
      'save', () {
    testWidgets('Issue 53: the view shows the form heading, and Create user '
        'stays off until the username is confirmed available', (tester) async {
      await _pump(tester);

      expect(find.text('Creating new profile'), findsOneWidget);
      expect(tester.widget<ShadButton>(_createUser()).onPressed, isNull);

      await tester.enterText(_field(UserFormFields.usernameId), 'robin');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Check availability'));
      await tester.pumpAndSettle();

      expect(tester.widget<ShadButton>(_createUser()).onPressed, isNotNull);
    });

    testWidgets('Issue 53: a valid form creates the user', (tester) async {
      var created = 0;
      final users = await _pump(tester, onCreated: () => created++);

      await _fillAndSubmit(tester);

      expect(users.created, ['robin']);
      expect(created, 1);
      expect(find.text('Created robin.'), findsOneWidget);
    });

    for (final (code, id, message) in [
      (
        SdkErrorCode.duplicateUsername,
        UserFormFields.usernameId,
        'That username is already taken.',
      ),
      (
        SdkErrorCode.duplicateEmail,
        UserFormFields.emailId,
        'That email is already registered.',
      ),
    ]) {
      testWidgets('Issue 53: a refused $id shows on that field', (
        tester,
      ) async {
        var created = 0;
        await _pump(tester, refusalCode: code, onCreated: () => created++);

        await _fillAndSubmit(tester);

        expect(created, 0);
        expect(
          find.descendant(of: _field(id), matching: find.text(message)),
          findsOneWidget,
        );
        expect(find.text(message), findsOneWidget);
        expect(find.textContaining('raw server text'), findsNothing);
      });
    }

    testWidgets('Issue 53: a refusal that names no field is a fixed toast', (
      tester,
    ) async {
      await _pump(tester, refusalCode: 'SOMETHING_NEW');

      await _fillAndSubmit(tester);

      expect(find.text('Could not create user.'), findsOneWidget);
    });

    testWidgets('Issue 53: Cancel leaves an untouched form without asking, '
        'and asks once a field changed', (tester) async {
      var cancelled = 0;
      await _pump(tester, onCancel: () => cancelled++);

      await tester.tap(find.widgetWithText(ShadButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(cancelled, 1);
      expect(find.text('Discard changes?'), findsNothing);

      await tester.enterText(_field(UserFormFields.firstNameId), 'Robin');
      await tester.tap(find.widgetWithText(ShadButton, 'Cancel'));
      await tester.pumpAndSettle();
      expect(cancelled, 1);
      expect(find.text('Discard changes?'), findsOneWidget);
    });
  });

  group(
    'Issue 71: UserCreateView gives its form the country code of the club',
    () {
      testWidgets('Issue 71: the form checks a phone in the country the '
          'server reports', (tester) async {
        await _pump(tester, countryCode: '33');

        expect(
          tester.widget<UserForm>(find.byType(UserForm)).defaultCountryCode,
          '33',
        );
      });
    },
  );
}
