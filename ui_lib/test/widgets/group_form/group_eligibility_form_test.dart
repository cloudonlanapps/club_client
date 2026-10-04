import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

Widget _wrap(Widget child) => ShadApp(
  home: Scaffold(body: SingleChildScrollView(child: child)),
);

Future<void> _setSurface(WidgetTester tester) async {
  await tester.binding.setSurfaceSize(const Size(1024, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
}

void main() {
  testWidgets('manual mode validates with no criteria', (tester) async {
    await _setSurface(tester);
    final key = GlobalKey<GroupEligibilityFormState>();
    await tester.pumpWidget(
      _wrap(
        GroupEligibilityForm(
          key: key,
          initialValues: const {GroupFormFields.modeId: GroupMode.manual},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final values = key.currentState!.validate();
    expect(values, isNotNull);
    expect(values![GroupFormFields.modeId], GroupMode.manual);
  });

  testWidgets('auto mode requires at least one criterion', (tester) async {
    await _setSurface(tester);
    final key = GlobalKey<GroupEligibilityFormState>();
    await tester.pumpWidget(
      _wrap(
        GroupEligibilityForm(
          key: key,
          initialValues: const {GroupFormFields.modeId: GroupMode.auto},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(key.currentState!.validate(), isNull);
    await tester.pumpAndSettle();
    expect(find.textContaining('at least one criterion'), findsOneWidget);
  });

  testWidgets('auto mode validates once a gender criterion is set', (
    tester,
  ) async {
    await _setSurface(tester);
    final key = GlobalKey<GroupEligibilityFormState>();
    await tester.pumpWidget(
      _wrap(
        GroupEligibilityForm(
          key: key,
          initialValues: const {
            GroupFormFields.modeId: GroupMode.auto,
            GroupFormFields.genderId: GroupGender.female,
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    final values = key.currentState!.validate();
    expect(values, isNotNull);
    expect(values![GroupFormFields.genderId], GroupGender.female);
  });
}
