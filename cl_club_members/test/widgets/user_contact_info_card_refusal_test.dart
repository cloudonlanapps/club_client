import 'package:cl_club_forms/cl_club_forms.dart' show UserFormFields;
import 'package:cl_club_members/src/widgets/user_contact_info_card.dart';
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

class _StubAuthNotifier extends AuthNotifier {
  _StubAuthNotifier(this.user);

  final UserPrivate user;

  @override
  Future<UserPrivate?> build() async => user;
}

/// Refuses every update with [refusal].
class _RefusingUsers extends ClUsersMasterNotifier {
  _RefusingUsers(this.refusal);

  final ServerException refusal;

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
  }) async => throw refusal;
}

UserPrivate _user(String username, {bool isAdmin = false}) => UserPrivate(
  username: username,
  displayName: 'Robin',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: UserRoles(isAdmin: isAdmin),
  email: '$username@example.test',
  phone: '+919876543210',
  createdAtUtc: DateTime.utc(2024, 6, 15),
);

Finder _field(String id) =>
    find.byWidgetPredicate((w) => w is ShadInputFormField && w.id == id);

/// Opens the card's editor, changes the email and saves, the server
/// answering with [code].
Future<void> _saveRefused(WidgetTester tester, String code) async {
  await tester.binding.setSurfaceSize(const Size(800, 1800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(
          () => _StubAuthNotifier(_user('viewer', isAdmin: true)),
        ),
        clUsersMasterProvider.overrideWith(
          () => _RefusingUsers(
            ServerException(
              statusCode: 409,
              code: code,
              message: 'raw server text',
            ),
          ),
        ),
        defaultCountryCodeProvider.overrideWithValue('91'),
      ],
      child: ShadApp(
        home: ShadToaster(
          child: Scaffold(
            body: SingleChildScrollView(
              child: UserContactInfoCard(user: _user('robin'), canEdit: true),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byIcon(LucideIcons.pencil));
  await tester.pumpAndSettle();
  await tester.enterText(_field(UserFormFields.emailId), 'sam@example.test');
  await tester.tap(find.widgetWithText(ShadButton, 'Save'));
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 53: the contact card shows a refused email on its field', () {
    testWidgets('Issue 53: an email another member has shows on the email '
        'field, and the editor stays open', (tester) async {
      await _saveRefused(tester, SdkErrorCode.duplicateEmail);

      expect(
        find.descendant(
          of: _field(UserFormFields.emailId),
          matching: find.text('That email is already in use.'),
        ),
        findsOneWidget,
      );
      expect(find.text('That email is already in use.'), findsOneWidget);
      expect(find.textContaining('raw server text'), findsNothing);
    });

    testWidgets('Issue 53: a refusal that names no field stays a toast', (
      tester,
    ) async {
      await _saveRefused(tester, SdkErrorCode.insufficientPermission);

      expect(
        find.text('You do not have permission for that action.'),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: _field(UserFormFields.emailId),
          matching: find.text('You do not have permission for that action.'),
        ),
        findsNothing,
      );
    });
  });
}
