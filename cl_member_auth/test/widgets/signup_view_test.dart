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
/// it when there is none.
class _Auth extends Fake implements AuthSource {
  _Auth(this.refusal);

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
}) async {
  await tester.binding.setSurfaceSize(const Size(1024, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  _ignoreOverflow();
  final auth = _Auth(refusal);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clientProvider.overrideWith(() => _ClientNotifier(_Client(auth))),
        usernameAvailabilityProvider.overrideWith(
          (ref, username) async => UsernameAvailability.available,
        ),
        identityVerificationProvider.overrideWithValue(
          identityDocumentsRequired,
        ),
        defaultCountryCodeProvider.overrideWithValue('91'),
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

/// Fills the form, the username confirmed available, and taps Create
/// account.
Future<void> _fillAndSubmit(WidgetTester tester) async {
  await tester.enterText(_field(UserFormFields.usernameId), 'robin');
  await tester.pumpAndSettle();
  await tester.tap(find.text('Check availability'));
  await tester.pumpAndSettle();
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
    testWidgets('Issue 53: Create account stays off until the username is '
        'confirmed available', (tester) async {
      await _pump(tester);

      expect(find.text('Create an account'), findsOneWidget);
      expect(tester.widget<ShadButton>(_createAccount()).onPressed, isNull);

      await tester.enterText(_field(UserFormFields.usernameId), 'robin');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Check availability'));
      await tester.pumpAndSettle();

      expect(tester.widget<ShadButton>(_createAccount()).onPressed, isNotNull);
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
}
