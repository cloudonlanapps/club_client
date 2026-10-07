import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Finder _field(String id) =>
    find.byWidgetPredicate((w) => w is ShadInputFormField && w.id == id);

Future<GlobalKey<SignupFormState>> _pump(
  WidgetTester tester, {
  String? username,
  Map<String, dynamic>? initialValues,
  ValueChanged<bool>? onCanSubmitChanged,
}) async {
  await tester.binding.setSurfaceSize(const Size(1024, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final key = GlobalKey<SignupFormState>();
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: SignupForm(
            key: key,
            username: username,
            initialValues: initialValues,
            onCheckUsernameAvailable: (_) async => true,
            onCanSubmitChanged: onCanSubmitChanged,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return key;
}

/// Fills everything a signing-up form asks for, the username confirmed
/// available.
Future<void> _fillSignup(
  WidgetTester tester,
  GlobalKey<SignupFormState> key, {
  String confirmPassword = 'secret-password',
}) async {
  await tester.enterText(_field(UserFormFields.usernameId), 'robin');
  await tester.pumpAndSettle();
  await tester.tap(find.text('Check availability'));
  await tester.pumpAndSettle();
  await tester.enterText(
    _field(UserFormFields.passwordId),
    'secret-password',
  );
  await tester.enterText(
    _field(UserFormFields.confirmPasswordId),
    confirmPassword,
  );
  await tester.enterText(_field(UserFormFields.firstNameId), ' Robin ');
  await tester.enterText(_field(UserFormFields.phoneId), ' 9876543210 ');
  await tester.enterText(
    _field(UserFormFields.emailId),
    ' robin@example.test ',
  );
  key.currentState!.formKey.currentState!.setValue({
    UserFormFields.genderId: SignupGender.female,
    UserFormFields.dateOfBirthUtcId: DateTime(2010, 3, 4, 15),
  });
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 53: SignupForm follows the form contract', () {
    testWidgets('Issue 53: SignupForm has fields only: no heading, submit '
        'button or sign-in link', (tester) async {
      await _pump(tester);

      expect(find.byType(ShadButton), findsNothing);
      expect(find.text('Create an account'), findsNothing);
      expect(find.text('Create account'), findsNothing);
      expect(find.text('Sign in'), findsNothing);
      expect(find.text('Username *'), findsOneWidget);
      expect(find.text('Middle name'), findsOneWidget);
    });

    testWidgets('Issue 53: signing up, canSubmit turns true once the '
        'username is confirmed available', (tester) async {
      final reported = <bool>[];
      final key = await _pump(tester, onCanSubmitChanged: reported.add);
      expect(reported, [false]);

      await _fillSignup(tester, key);

      expect(reported, [false, true]);
      expect(key.currentState!.canSubmit, isTrue);
    });

    testWidgets('Issue 53: validate returns the assembled signup values', (
      tester,
    ) async {
      final key = await _pump(tester);
      await _fillSignup(tester, key);

      expect(key.currentState!.validate(), {
        UserFormFields.usernameId: 'robin',
        UserFormFields.passwordId: 'secret-password',
        UserFormFields.emailId: 'robin@example.test',
        UserFormFields.phoneId: '9876543210',
        UserFormFields.firstNameId: 'Robin',
        UserFormFields.middleNameId: null,
        UserFormFields.lastNameId: null,
        UserFormFields.dateOfBirthUtcId: DateTime.utc(2010, 3, 4),
        UserFormFields.genderId: SignupGender.female,
      });
    });

    testWidgets('Issue 53: differing passwords are refused inline', (
      tester,
    ) async {
      final key = await _pump(tester);
      await _fillSignup(tester, key, confirmPassword: 'something-else');

      expect(key.currentState!.validate(), isNull);
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('Issue 53: an unchecked username is refused inline', (
      tester,
    ) async {
      final key = await _pump(tester);
      await _fillSignup(tester, key);
      await tester.enterText(_field(UserFormFields.usernameId), 'robin2');
      await tester.pumpAndSettle();

      expect(key.currentState!.canSubmit, isFalse);
      expect(key.currentState!.validate(), isNull);
      await tester.pumpAndSettle();

      expect(
        find.text('Run the availability check before creating the account.'),
        findsOneWidget,
      );
    });

    testWidgets('Issue 53: showErrors puts a server refusal on its field', (
      tester,
    ) async {
      final key = await _pump(tester);

      key.currentState!.showErrors(
        fieldErrors: {
          UserFormFields.emailId: 'That email is already registered.',
        },
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: _field(UserFormFields.emailId),
          matching: find.text('That email is already registered.'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('Issue 53: reapplying, the username is fixed, no password '
        'is asked and the values carry neither', (tester) async {
      final reported = <bool>[];
      final key = await _pump(
        tester,
        username: 'robin',
        initialValues: {
          UserFormFields.firstNameId: 'Robin',
          UserFormFields.phoneId: '9876543210',
          UserFormFields.emailId: 'robin@example.test',
          UserFormFields.genderId: SignupGender.other,
          UserFormFields.dateOfBirthUtcId: DateTime.utc(2010, 3, 4),
        },
        onCanSubmitChanged: reported.add,
      );

      expect(reported, [true]);
      expect(find.text('robin'), findsOneWidget);
      expect(_field(UserFormFields.usernameId), findsNothing);
      expect(_field(UserFormFields.passwordId), findsNothing);
      expect(key.currentState!.isDirty, isFalse);

      final values = key.currentState!.validate();
      expect(values, isNotNull);
      expect(values!.containsKey(UserFormFields.usernameId), isFalse);
      expect(values.containsKey(UserFormFields.passwordId), isFalse);
      expect(values[UserFormFields.genderId], SignupGender.other);

      await tester.enterText(_field(UserFormFields.lastNameId), 'Rao');
      expect(key.currentState!.isDirty, isTrue);
    });
  });
}
