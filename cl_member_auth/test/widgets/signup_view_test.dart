import 'package:cl_club_forms/cl_club_forms.dart'
    show SignupFormState, SignupGender, UserFormFields;
import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show defaultCountryCodeProvider, identityVerificationProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Registers nothing: answers every registration with [refusal], or accepts
/// it when there is none, after [latency] as a server would, so the form is
/// drawn turned off while it waits.
class _Auth extends Fake implements AuthSource {
  _Auth(this.refusal);

  static const Duration latency = Duration(milliseconds: 50);

  final Exception? refusal;
  final registered = <String>[];

  @override
  Future<UserInfo> register({
    required String username,
    required String email,
    required String password,
    required String phone,
    required DateTime dateOfBirthUtc,
    required Gender gender,
    String? firstName,
    String? middleName,
    String? lastName,
  }) async {
    await Future<void>.delayed(latency);
    final refusal = this.refusal;
    if (refusal != null) throw refusal;
    registered.add(username);
    return UserInfo(
      username: username,
      displayName: username,
      status: UserStatus.registered,
      isSuperAdmin: false,
      roles: const UserRoles(),
    );
  }
}

class _Client extends Fake implements SecureClient {
  _Client(this.auth);

  @override
  final AuthSource auth;
}

class _ClientNotifier extends ClientNotifier {
  _ClientNotifier(this.client);

  final SecureClient client;

  @override
  Future<SecureClient> build() async => client;
}

Finder _field(String id) =>
    find.byWidgetPredicate((w) => w is ShadInputFormField && w.id == id);

Finder _createAccount() => find.widgetWithText(ShadButton, 'Create account');

/// The test font is wider than any real one, so the sign-in link row
/// overflows its 420-pixel column here. That is layout noise, not what these
/// tests assert; every other error still fails the test.
void _ignoreOverflow() {
  final original = FlutterError.onError;
  FlutterError.onError = (details) {
    if (details.exceptionAsString().contains('overflowed')) return;
    original?.call(details);
  };
  addTearDown(() => FlutterError.onError = original);
}

Future<_Auth> _pump(
  WidgetTester tester, {
  bool? identityDocumentsRequired,
  Exception? refusal,
  VoidCallback? onSignupSuccess,
  String countryCode = '91',
}) async {
  await tester.binding.setSurfaceSize(const Size(1024, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  _ignoreOverflow();
  final auth = _Auth(refusal);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clientProvider.overrideWith(() => _ClientNotifier(_Client(auth))),
        identityVerificationProvider.overrideWithValue(
          identityDocumentsRequired,
        ),
        defaultCountryCodeProvider.overrideWithValue(countryCode),
      ],
      child: ShadApp(
        home: ShadToaster(
          child: Scaffold(
            body: SignupView(
              onSignupSuccess: onSignupSuccess ?? () {},
              onNavigateToLogin: () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return auth;
}

/// Fills the form with [username] and taps Create account.
Future<void> _fillAndSubmit(
  WidgetTester tester, {
  String username = 'robin',
}) async {
  await tester.enterText(_field(UserFormFields.usernameId), username);
  await tester.enterText(_field(UserFormFields.passwordId), 'secret-password');
  await tester.enterText(
    _field(UserFormFields.confirmPasswordId),
    'secret-password',
  );
  await tester.enterText(_field(UserFormFields.firstNameId), 'Robin');
  await tester.enterText(_field(UserFormFields.phoneId), '9876543210');
  await tester.enterText(_field(UserFormFields.emailId), 'robin@example.test');
  tester
      .state<SignupFormState>(find.byType(SignupForm))
      .formKey
      .currentState!
      .setValue({
        UserFormFields.genderId: SignupGender.female,
        UserFormFields.dateOfBirthUtcId: DateTime(2010, 3, 4),
      });
  await tester.pumpAndSettle();
  await tester.tap(_createAccount());
  // The frame drawn while the registration is in flight: the form is off.
  await tester.pump();
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 84: SignupForm intro follows identity verification', () {
    testWidgets('on: says identity documents will be asked for', (
      tester,
    ) async {
      await _pump(tester, identityDocumentsRequired: true);

      expect(find.textContaining('identity documents'), findsOneWidget);
    });

    for (final state in [false, null]) {
      testWidgets('${state == null ? 'unknown' : 'off'}: names no document', (
        tester,
      ) async {
        await _pump(tester, identityDocumentsRequired: state);

        expect(find.textContaining('document'), findsNothing);
        expect(
          find.textContaining('An admin will review your application'),
          findsOneWidget,
        );
      });
    }
  });

  group('Issue 53: SignupView owns the title, the buttons and the save', () {
    testWidgets('Issue 161: Create account is on before a username is '
        'typed, with no availability check beside the field', (tester) async {
      await _pump(tester);

      expect(find.text('Create an account'), findsOneWidget);
      expect(tester.widget<ShadButton>(_createAccount()).onPressed, isNotNull);

      await tester.enterText(_field(UserFormFields.usernameId), 'robin');
      await tester.pumpAndSettle();

      expect(find.text('Check availability'), findsNothing);
      expect(tester.widget<ShadButton>(_createAccount()).onPressed, isNotNull);
    });

    testWidgets('Issue 161: a username the server refuses as taken shows on '
        'the username field, with the focus there and what was typed kept', (
      tester,
    ) async {
      var succeeded = 0;
      final auth = await _pump(
        tester,
        refusal: const ServerException(
          statusCode: 409,
          code: SdkErrorCode.duplicateUsername,
          message: 'raw server text',
        ),
        onSignupSuccess: () => succeeded++,
      );

      await _fillAndSubmit(tester);

      expect(succeeded, 0);
      expect(auth.registered, isEmpty);
      expect(
        find.descendant(
          of: _field(UserFormFields.usernameId),
          matching: find.text('That username is already taken.'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('raw server text'), findsNothing);
      final usernameInput = tester.widget<EditableText>(
        find.descendant(
          of: _field(UserFormFields.usernameId),
          matching: find.byType(EditableText),
        ),
      );
      expect(usernameInput.focusNode.hasFocus, isTrue);
      expect(usernameInput.controller.text, 'robin');
      final emailInput = tester.widget<EditableText>(
        find.descendant(
          of: _field(UserFormFields.emailId),
          matching: find.byType(EditableText),
        ),
      );
      expect(emailInput.controller.text, 'robin@example.test');
    });

    testWidgets('Issue 161: a badly formed username is refused on its field '
        'before any request', (tester) async {
      var succeeded = 0;
      final auth = await _pump(tester, onSignupSuccess: () => succeeded++);

      await _fillAndSubmit(tester, username: 'ro');

      expect(succeeded, 0);
      expect(auth.registered, isEmpty);
      expect(
        find.descendant(
          of: _field(UserFormFields.usernameId),
          matching: find.text('At least 3 characters'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Issue 53: a valid form registers and reports success', (
      tester,
    ) async {
      var succeeded = 0;
      final auth = await _pump(tester, onSignupSuccess: () => succeeded++);

      await _fillAndSubmit(tester);

      expect(auth.registered, ['robin']);
      expect(succeeded, 1);
    });

    testWidgets('Issue 53: an email the server refuses as taken shows on '
        'the email field', (tester) async {
      var succeeded = 0;
      await _pump(
        tester,
        refusal: const ServerException(
          statusCode: 409,
          code: SdkErrorCode.duplicateEmail,
          message: 'raw server text',
        ),
        onSignupSuccess: () => succeeded++,
      );

      await _fillAndSubmit(tester);

      expect(succeeded, 0);
      expect(
        find.descendant(
          of: _field(UserFormFields.emailId),
          matching: find.text('That email is already registered.'),
        ),
        findsOneWidget,
      );
      expect(find.textContaining('raw server text'), findsNothing);
    });

    testWidgets('Issue 53: a failure no field explains is a fixed toast', (
      tester,
    ) async {
      await _pump(tester, refusal: Exception('offline'));

      await _fillAndSubmit(tester);

      expect(
        find.text('Could not create account. Please try again.'),
        findsOneWidget,
      );
      expect(find.textContaining('offline'), findsNothing);
    });
  });

  group('Issue 71: SignupView gives its form the country code of the club', () {
    testWidgets('Issue 71: the form checks a phone in the country the '
        'server reports', (tester) async {
      await _pump(tester, countryCode: '33');

      expect(
        tester.widget<SignupForm>(find.byType(SignupForm)).defaultCountryCode,
        '33',
      );
    });
  });
}
