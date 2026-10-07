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
          initialValues: const {'city': 'Pune', 'addrLine1': 'MG Road'},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final values = key.currentState!.validate();
    expect(values, isNotNull);
    expect(values!.keys.toSet(), UserAddressForm.ids.toSet());
    expect(values['addrLine1'], 'MG Road');
    expect(values['city'], 'Pune');
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
            initialValues: const {'firstName': 'Asha'},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final values = key.currentState!.validate();
      expect(values, isNotNull);
      // Protected fields must not be sent when the editor can't change them.
      expect(values!.containsKey('gender'), isFalse);
      expect(values.containsKey('dateOfBirthUtc'), isFalse);
      expect(values.containsKey('useNamePublicly'), isFalse);
      expect(values['firstName'], 'Asha');
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
              'firstName': 'Asha',
              'gender': SignupGender.female,
              'dateOfBirthUtc': DateTime.utc(2000, 5, 1),
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
      expect(values!.containsKey('gender'), isTrue);
      expect(values.containsKey('dateOfBirthUtc'), isTrue);
      expect(values.containsKey('useNamePublicly'), isTrue);
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
            'email': 'asha@example.com',
            'phone': '9876543210',
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    // Initial values render (not blank).
    expect(find.text('asha@example.com'), findsOneWidget);

    final values = key.currentState!.validate();
    expect(values, isNotNull);
    expect(values!.keys.toSet(), UserContactForm.ids.toSet());
    expect(values['email'], 'asha@example.com');
    expect(values['phone'], '9876543210');
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
          initialValues: const {'email': 'not-an-email', 'phone': '12'},
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
