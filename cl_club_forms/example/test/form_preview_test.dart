import 'package:cl_club_forms_example/constants/demo_keys.dart';
import 'package:cl_club_forms_example/data/form_demo_entries.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'support/demo_harness.dart';

/// Anything a person would take for a button or a switch.
final Finder anyControl = find.byWidgetPredicate(
  (widget) =>
      widget is ShadButton ||
      widget is ShadSwitch ||
      widget is IconButton ||
      widget is ButtonStyleButton ||
      widget is Switch,
  description: 'a button or a switch',
);

/// The demo's own controls, by key. All are in the top bar.
final Set<Key> topBarControls = {
  DemoKeys.validate,
  DemoKeys.reset,
  DemoKeys.themeToggle,
  DemoKeys.openSidebar,
};

/// The controls on screen that are neither the top bar's nor inside [form].
List<Widget> controlsOutside(Finder form) => [
  for (final control in anyControl.evaluate())
    if (!topBarControls.contains(control.widget.key) &&
        find
            .ancestor(
              of: find.byWidget(control.widget),
              matching: find.byWidgetPredicate(
                (widget) => topBarControls.contains(widget.key),
              ),
            )
            .evaluate()
            .isEmpty &&
        find
            .descendant(of: form, matching: find.byWidget(control.widget))
            .evaluate()
            .isEmpty)
      control.widget,
];

void main() {
  for (final surface in kSurfaces.entries) {
    for (final entry in FormDemoEntries.all) {
      testWidgets(
        'Issue 76: "${entry.title}" mounts with no exception, ${surface.key}',
        (tester) async {
          await pumpEntry(tester, entry, surface.value);

          expect(tester.takeException(), isNull);
          expect(
            find.descendant(
              of: find.byKey(DemoKeys.formCard),
              matching: find.byType(entry.formType),
            ),
            findsOneWidget,
          );
        },
      );

      testWidgets('Issue 76: the card of "${entry.title}" holds no button '
          'other than the form\'s own, ${surface.key}', (tester) async {
        await pumpEntry(tester, entry, surface.value);

        expect(
          controlsOutside(find.byType(entry.formType)),
          isEmpty,
          reason: 'controls outside the form and the top bar',
        );
      });
    }
  }
}
