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

Finder _fieldById(String id) =>
    find.byWidgetPredicate((w) => w is ShadInputFormField && w.id == id);

void main() {
  testWidgets('blocks submit and runs validation when name is empty', (
    tester,
  ) async {
    await _setSurface(tester);
    final key = GlobalKey<VenueCreateFormState>();
    var submits = 0;
    await tester.pumpWidget(
      _wrap(
        VenueCreateForm(
          key: key,
          initialValues: VenueCreateForm.emptyValues,
          onSubmit: (_) async => submits++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await key.currentState!.handleSubmit();
    await tester.pumpAndSettle();

    expect(submits, 0, reason: 'empty name must fail validation');
    expect(find.text('Venue name is required'), findsOneWidget);
  });

  testWidgets('accepts and submits initial values (not defaults)', (
    tester,
  ) async {
    await _setSurface(tester);
    final key = GlobalKey<VenueCreateFormState>();
    Map<String, dynamic>? submitted;
    await tester.pumpWidget(
      _wrap(
        VenueCreateForm(
          key: key,
          initialValues: const {
            'name': 'Main Arena',
            'address': '1 Rink Rd',
            'description': '',
            'mapUri': '',
            'isDefault': true,
            'isFeatured': false,
          },
          onSubmit: (values) async => submitted = values,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await key.currentState!.handleSubmit();
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted!['name'], 'Main Arena');
    expect(submitted!['address'], '1 Rink Rd');
    // The toggle reflects the passed initial value, not the `false` default.
    expect(submitted!['isDefault'], true);
  });

  testWidgets('isDirty is false initially and true after a field change', (
    tester,
  ) async {
    await _setSurface(tester);
    final key = GlobalKey<VenueCreateFormState>();
    await tester.pumpWidget(
      _wrap(
        VenueCreateForm(
          key: key,
          initialValues: const {
            'name': 'Main Arena',
            'address': '',
            'description': '',
            'mapUri': '',
            'isDefault': false,
            'isFeatured': false,
          },
          onSubmit: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      key.currentState!.isDirty,
      isFalse,
      reason: 'unchanged form must not be dirty (no discard prompt)',
    );

    await tester.enterText(_fieldById('name'), 'Practice Rink');
    await tester.pump();

    expect(
      key.currentState!.isDirty,
      isTrue,
      reason: 'editing a field marks the form dirty (discard prompt)',
    );
  });
}
