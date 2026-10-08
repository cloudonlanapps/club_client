import 'dart:async';

import 'package:cl_club_forms/cl_club_forms.dart'
    show SignupForm, UserFormFields;
import 'package:cl_member_auth/cl_member_auth.dart'
    show AuthNotifier, authStateProvider;
import 'package:cl_member_onboarding/src/models/onboarding_write_messages.dart';
import 'package:cl_member_onboarding/src/models/reapply_form_helpers.dart';
import 'package:cl_member_onboarding/src/widgets/reapply_variant.dart';
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

UserPrivate _user({String? lastName = 'One'}) => UserPrivate(
  username: 'u1',
  displayName: 'U One',
  status: UserStatus.registered,
  isSuperAdmin: false,
  roles: const UserRoles(),
  createdAtUtc: DateTime.utc(2024),
  adminReviewNote: 'Please correct your phone number.',
  firstName: 'Una',
  lastName: lastName,
  email: 'u1@example.com',
  phone: '+14155550100',
  dateOfBirthUtc: DateTime.utc(2000),
  gender: Gender.female,
);

/// Holds the signed-in member and records the one it is replaced with.
class _Auth extends AuthNotifier {
  UserPrivate? stored;

  @override
  Future<UserPrivate?> build() async => _user();

  @override
  void setUser(UserPrivate user) => stored = user;
}

/// The failure of a reapplication the server refuses for no reason the
/// form can show.
const _unknownRefusal = ServerException(
  statusCode: 400,
  code: 'SOMETHING_NEW',
  message: 'raw failure text',
);

/// Records what a reapplication carried, or fails it with [failure].
class _Users extends ClUsersMasterNotifier {
  _Users({this.failure});

  final Exception? failure;
  final lastNames = <String?>[];

  @override
  Future<Map<String, UserInfo>> build() async => {};

  @override
  Future<UserPrivate> reapplyForSelf({
    String? firstName,
    String? middleName,
    String? lastName,
    DateTime? dateOfBirthUtc,
    Gender? gender,
    String? phone,
    String? email,
  }) async {
    final failure = this.failure;
    if (failure != null) throw failure;
    lastNames.add(lastName);
    return _user(lastName: lastName);
  }
}

Finder _field(String id) =>
    find.byWidgetPredicate((w) => w is ShadInputFormField && w.id == id);

Future<(_Users, _Auth)> _pump(
  WidgetTester tester, {
  Exception? failure,
  VoidCallback? onContinue,
  String countryCode = '91',
}) async {
  await tester.binding.setSurfaceSize(const Size(900, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final users = _Users(failure: failure);
  final auth = _Auth();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(() => auth),
        clUsersMasterProvider.overrideWith(() => users),
        defaultCountryCodeProvider.overrideWithValue(countryCode),
      ],
      child: ShadApp(
        home: ShadToaster(
          child: Scaffold(
            body: ReapplyVariant(
              currentUser: _user(),
              onContinue: onContinue ?? () {},
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return (users, auth);
}

Future<void> _submit(WidgetTester tester) async {
  await tester.tap(find.widgetWithText(ShadButton, 'Submit changes'));
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 53: ReapplyVariant owns the title, the note, the button and '
      'the save', () {
    testWidgets('Issue 53: Submit changes validates the form before '
        'resubmitting', (tester) async {
      var continued = 0;
      final (users, _) = await _pump(tester, onContinue: () => continued++);

      expect(find.text('Update your registration'), findsOneWidget);
      expect(find.text('Please correct your phone number.'), findsOneWidget);

      await tester.enterText(_field(UserFormFields.emailId), 'not-an-email');
      await _submit(tester);

      expect(users.lastNames, isEmpty);
      expect(continued, 0);
      expect(find.text('Enter a valid email'), findsOneWidget);
    });

    testWidgets('Issue 53: valid changes are resubmitted, the updated member '
        'is stored and the view continues', (tester) async {
      var continued = 0;
      final (users, auth) = await _pump(tester, onContinue: () => continued++);

      await tester.enterText(_field(UserFormFields.lastNameId), ' Two ');
      await _submit(tester);

      expect(users.lastNames, ['Two']);
      expect(auth.stored?.lastName, 'Two');
      expect(continued, 1);
    });

    testWidgets('Issue 53: a failed resubmission is a fixed toast and the '
        'form takes input again', (tester) async {
      var continued = 0;
      await _pump(
        tester,
        failure: _unknownRefusal,
        onContinue: () => continued++,
      );

      await _submit(tester);

      expect(continued, 0);
      expect(find.text(reapplyFailedMessage), findsOneWidget);
      expect(find.textContaining('raw failure text'), findsNothing);
      expect(
        tester
            .widget<ShadInputFormField>(_field(UserFormFields.emailId))
            .enabled,
        isTrue,
      );
    });
  });

  group('Issue 97: ReapplyVariant shows a refusal where it belongs', () {
    testWidgets('Issue 97: an email another account has shows on the email '
        'field, with no toast, and the form takes input again', (
      tester,
    ) async {
      var continued = 0;
      await _pump(
        tester,
        failure: const ServerException(
          statusCode: 409,
          code: SdkErrorCode.duplicateEmail,
          message: 'raw failure text',
        ),
        onContinue: () => continued++,
      );

      await _submit(tester);

      expect(continued, 0);
      expect(
        find.descendant(
          of: _field(UserFormFields.emailId),
          matching: find.text(ReapplyFormSubmit.emailRegisteredMessage),
        ),
        findsOneWidget,
      );
      expect(find.byType(ShadToast), findsNothing);
      expect(find.textContaining('raw failure text'), findsNothing);
      expect(
        tester
            .widget<ShadInputFormField>(_field(UserFormFields.emailId))
            .enabled,
        isTrue,
      );
      expect(
        tester
            .widget<ShadButton>(
              find.widgetWithText(ShadButton, 'Submit changes'),
            )
            .onPressed,
        isNotNull,
      );
    });

    testWidgets('Issue 97: a server that cannot be reached is a toast, and '
        'no field shows a message', (tester) async {
      await _pump(tester, failure: TimeoutException('connection closed'));

      await _submit(tester);

      expect(find.byType(ShadToast), findsOneWidget);
      expect(find.text(ReapplyFormSubmit.emailRegisteredMessage), findsNothing);
      expect(find.textContaining('connection closed'), findsNothing);
    });
  });

  group(
    'Issue 71: ReapplyVariant gives its form the country code of the club',
    () {
      testWidgets('Issue 71: the form checks a phone in the country the '
          'server reports', (tester) async {
        await _pump(tester, countryCode: '33');

        expect(
          tester.widget<SignupForm>(find.byType(SignupForm)).defaultCountryCode,
          '33',
        );
      });
    },
  );
}
