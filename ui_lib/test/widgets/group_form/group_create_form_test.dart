import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

Widget _wrap(Widget child) => ShadApp(
  home: Scaffold(
    body: SingleChildScrollView(child: child),
  ),
);

Future<void> _setSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1024, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  testWidgets('defaults to manual mode and hides eligibility criteria', (
    tester,
  ) async {
    await _setSurface(tester);
    await tester.pumpWidget(_wrap(GroupCreateForm(onSubmit: (_) async {})));
    await tester.pumpAndSettle();

    expect(find.text('Mode'), findsOneWidget);
    expect(find.text('DOB on or after'), findsNothing);
    expect(find.text('Gender'), findsNothing);
  });

  testWidgets('selecting Auto reveals the eligibility criteria', (
    tester,
  ) async {
    await _setSurface(tester);
    await tester.pumpWidget(_wrap(GroupCreateForm(onSubmit: (_) async {})));
    await tester.pumpAndSettle();

    // Open the mode select (shows the current value "Manual") and pick "Auto".
    await tester.tap(find.text('Manual'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Auto').last);
    await tester.pumpAndSettle();

    expect(find.text('DOB on or after'), findsOneWidget);
    expect(find.text('Gender'), findsOneWidget);
  });

  testWidgets('submits manual group with addMe flag in the value map', (
    tester,
  ) async {
    await _setSurface(tester);
    final formKey = GlobalKey<GroupCreateFormState>();
    Map<String, dynamic>? submitted;
    await tester.pumpWidget(
      _wrap(
        GroupCreateForm(
          key: formKey,
          onSubmit: (values) async => submitted = values,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(
      find.byWidgetPredicate(
        (w) => w is ShadInputFormField && w.id == GroupFormFields.nameId,
      ),
      'U12 Boys',
    );
    await formKey.currentState!.handleSubmit();
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted![GroupFormFields.nameId], 'U12 Boys');
    expect(submitted![GroupFormFields.modeId], GroupMode.manual);
    expect(submitted![GroupFormFields.addMeId], false);
  });

  testWidgets('blocks submit when the name is empty', (tester) async {
    await _setSurface(tester);
    final formKey = GlobalKey<GroupCreateFormState>();
    var submitCount = 0;
    await tester.pumpWidget(
      _wrap(
        GroupCreateForm(
          key: formKey,
          onSubmit: (_) async => submitCount++,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await formKey.currentState!.handleSubmit();
    await tester.pumpAndSettle();

    expect(submitCount, 0);
  });

  testWidgets('accepts and submits initial values (not defaults)', (
    tester,
  ) async {
    await _setSurface(tester);
    final formKey = GlobalKey<GroupCreateFormState>();
    Map<String, dynamic>? submitted;
    await tester.pumpWidget(
      _wrap(
        GroupCreateForm(
          key: formKey,
          initialValues: const {
            GroupFormFields.nameId: 'U10 Girls',
            GroupFormFields.descriptionId: 'desc',
            GroupFormFields.modeId: GroupMode.manual,
            GroupFormFields.addMeId: true,
          },
          onSubmit: (values) async => submitted = values,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await formKey.currentState!.handleSubmit();
    await tester.pumpAndSettle();

    expect(submitted, isNotNull);
    expect(submitted![GroupFormFields.nameId], 'U10 Girls');
    // addMe reflects the passed initial value, not the `false` default.
    expect(submitted![GroupFormFields.addMeId], true);
  });

  testWidgets('isDirty is false initially and true after a field change', (
    tester,
  ) async {
    await _setSurface(tester);
    final formKey = GlobalKey<GroupCreateFormState>();
    await tester.pumpWidget(
      _wrap(
        GroupCreateForm(
          key: formKey,
          initialValues: const {
            GroupFormFields.nameId: 'U10 Girls',
            GroupFormFields.descriptionId: '',
            GroupFormFields.modeId: GroupMode.manual,
            GroupFormFields.addMeId: false,
          },
          onSubmit: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      formKey.currentState!.isDirty,
      isFalse,
      reason: 'unchanged form must not be dirty (no discard prompt)',
    );

    await tester.enterText(
      find.byWidgetPredicate(
        (w) => w is ShadInputFormField && w.id == GroupFormFields.nameId,
      ),
      'U12 Girls',
    );
    await tester.pump();

    expect(
      formKey.currentState!.isDirty,
      isTrue,
      reason: 'editing a field marks the form dirty (discard prompt)',
    );
  });
}
