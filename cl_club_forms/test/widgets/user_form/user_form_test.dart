import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Finder _field(String id) =>
    find.byWidgetPredicate((w) => w is ShadInputFormField && w.id == id);

Future<GlobalKey<UserFormState>> _pumpCreate(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1024, 2400));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final key = GlobalKey<UserFormState>();
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: UserForm(
            key: key,
            canAssignCoach: true,
            onCheckUsernameAvailable: (_) async => true,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return key;
}

Future<void> _fill(WidgetTester tester, GlobalKey<UserFormState> key) async {
  await tester.enterText(_field(UserFormFields.usernameId), 'robin');
  await tester.enterText(_field(UserFormFields.firstNameId), 'Robin');
  await tester.enterText(_field(UserFormFields.phoneId), '9876543210');
  await tester.enterText(_field(UserFormFields.emailId), 'robin@example.test');
  key.currentState!.formKey.currentState!.setValue({
    UserFormFields.genderId: SignupGender.female,
    UserFormFields.dateOfBirthUtcId: DateTime.utc(2010, 3, 4),
  });
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 53: UserForm follows the form contract', () {
    testWidgets('Issue 53: UserForm has no title and is not dirty until a '
        'field changes', (tester) async {
      final key = await _pumpCreate(tester);

      expect(find.text('Creating new profile'), findsNothing);
      expect(key.currentState!.isDirty, isFalse);

      await tester.enterText(_field(UserFormFields.firstNameId), 'Robin');

      expect(key.currentState!.isDirty, isTrue);
    });

    testWidgets('Issue 53: creating, an unchecked username is refused inline '
        'and the values come once it is confirmed', (tester) async {
      final key = await _pumpCreate(tester);
      await _fill(tester, key);

      expect(key.currentState!.validate(), isNull);
      await tester.pumpAndSettle();
      expect(
        find.text('Run the availability check before creating the account.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Check availability'));
      await tester.pumpAndSettle();
      expect(
        find.text('Run the availability check before creating the account.'),
        findsNothing,
      );

      final values = key.currentState!.validate();
      expect(values, isNotNull);
      expect(values![UserFormFields.usernameId], 'robin');
      expect(values[UserFormFields.useDefaultPasswordId], isTrue);
      expect(values[UserFormFields.assignCoachId], isFalse);
      expect(values[UserFormFields.genderId], SignupGender.female);
    });

    testWidgets('Issue 53: a user with no name is refused inline', (
      tester,
    ) async {
      final key = await _pumpCreate(tester);
      await _fill(tester, key);
      await tester.tap(find.text('Check availability'));
      await tester.pumpAndSettle();
      await tester.enterText(_field(UserFormFields.firstNameId), '');

      expect(key.currentState!.validate(), isNull);
      await tester.pumpAndSettle();

      expect(find.text('First name or last name is required'), findsOneWidget);
    });

    testWidgets('Issue 53: showErrors puts a refused username on its field', (
      tester,
    ) async {
      final key = await _pumpCreate(tester);

      key.currentState!.showErrors(
        fieldErrors: {
          UserFormFields.usernameId: 'That username is already taken.',
        },
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: _field(UserFormFields.usernameId),
          matching: find.text('That username is already taken.'),
        ),
        findsOneWidget,
      );
    });
  });
}
