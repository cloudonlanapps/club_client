import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

Widget _wrap(Widget child) => ShadApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

Future<void> _setSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1024, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  testWidgets('UserAddressForm.validate returns only the address keys', (
    tester,
  ) async {
    await _setSurface(tester);
    final key = GlobalKey<UserAddressFormState>();
    await tester.pumpWidget(
      _wrap(
        UserAddressForm(
          key: key,
          initialValues: const {
            UserFormFields.cityId: 'Pune',
            UserFormFields.addrLine1Id: 'MG Road',
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final values = key.currentState!.validate();
    expect(values, isNotNull);
    expect(values!.keys.toSet(), UserFormFields.addressIds.toSet());
    expect(values[UserFormFields.addrLine1Id], 'MG Road');
    expect(values[UserFormFields.cityId], 'Pune');
  });

  testWidgets(
    'UserPersonalDetailsForm omits protected keys when not editable',
    (tester) async {
      await _setSurface(tester);
      final key = GlobalKey<UserPersonalDetailsFormState>();
      await tester.pumpWidget(
        _wrap(
          UserPersonalDetailsForm(
            key: key,
            initialValues: const {UserFormFields.firstNameId: 'Asha'},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final values = key.currentState!.validate();
      expect(values, isNotNull);
      // Protected fields must not be sent when the editor can't change them.
      expect(values!.containsKey(UserFormFields.genderId), isFalse);
      expect(values.containsKey(UserFormFields.dateOfBirthUtcId), isFalse);
      expect(values.containsKey(UserFormFields.useNamePubliclyId), isFalse);
      expect(values[UserFormFields.firstNameId], 'Asha');
    },
  );

  testWidgets(
    'UserPersonalDetailsForm includes protected keys when editable',
    (tester) async {
      await _setSurface(tester);
      final key = GlobalKey<UserPersonalDetailsFormState>();
      await tester.pumpWidget(
        _wrap(
          UserPersonalDetailsForm(
            key: key,
            initialValues: {
              UserFormFields.firstNameId: 'Asha',
              UserFormFields.genderId: SignupGender.female,
              UserFormFields.dateOfBirthUtcId: DateTime.utc(2000, 5, 1),
            },
            canEditGender: true,
            canEditDateOfBirth: true,
            canEditUseNamePublicly: true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final values = key.currentState!.validate();
      expect(values, isNotNull);
      expect(values!.containsKey(UserFormFields.genderId), isTrue);
      expect(values.containsKey(UserFormFields.dateOfBirthUtcId), isTrue);
      expect(values.containsKey(UserFormFields.useNamePubliclyId), isTrue);
    },
  );

  testWidgets('UserPersonalDetailsForm blocks submit with no name', (
    tester,
  ) async {
    await _setSurface(tester);
    final key = GlobalKey<UserPersonalDetailsFormState>();
    await tester.pumpWidget(
      _wrap(
        UserPersonalDetailsForm(key: key, initialValues: const {}),
      ),
    );
    await tester.pumpAndSettle();

    expect(key.currentState!.validate(), isNull);
  });

  testWidgets('UserContactForm returns its keys and respects initial values', (
    tester,
  ) async {
    await _setSurface(tester);
    final key = GlobalKey<UserContactFormState>();
    await tester.pumpWidget(
      _wrap(
        UserContactForm(
          key: key,
          initialValues: const {
            UserFormFields.emailId: 'asha@example.com',
            UserFormFields.phoneId: '9876543210',
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Initial values render (not blank).
    expect(find.text('asha@example.com'), findsOneWidget);

    final values = key.currentState!.validate();
    expect(values, isNotNull);
    expect(values!.keys.toSet(), UserFormFields.contactIds.toSet());
    expect(values[UserFormFields.emailId], 'asha@example.com');
    expect(values[UserFormFields.phoneId], '9876543210');
  });

  testWidgets('UserContactForm blocks submit on invalid email / phone', (
    tester,
  ) async {
    await _setSurface(tester);
    final key = GlobalKey<UserContactFormState>();
    await tester.pumpWidget(
      _wrap(
        UserContactForm(
          key: key,
          initialValues: const {
            UserFormFields.emailId: 'not-an-email',
            UserFormFields.phoneId: '12',
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(key.currentState!.validate(), isNull);
    await tester.pumpAndSettle();
    expect(find.text('Enter a valid email'), findsOneWidget);
    expect(find.text('Enter a valid phone number'), findsOneWidget);
  });
}
