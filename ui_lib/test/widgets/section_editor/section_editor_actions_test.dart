import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/section_editor/section_editor_actions.dart';

Future<void> _pump(WidgetTester tester, {required bool saving}) =>
    tester.pumpWidget(
      ShadApp(
        home: Scaffold(
          body: SectionEditorActions(
            saving: saving,
            onCancel: () {},
            onSave: () {},
          ),
        ),
      ),
    );

ShadButton _save(WidgetTester tester) =>
    tester.widget<ShadButton>(find.byType(ShadButton).last);

void main() {
  group('Issue 108: SectionEditorActions', () {
    testWidgets('Issue 108: Save reads "Save" and is live when nothing is '
        'in flight', (tester) async {
      await _pump(tester, saving: false);

      expect(find.widgetWithText(ShadButton, 'Save'), findsOneWidget);
      expect(find.text('Saving…'), findsNothing);
      expect(_save(tester).enabled, isTrue);
      expect(_save(tester).onPressed, isNotNull);
    });

    testWidgets('Issue 108: while the save is in flight Save is off and '
        'reads "Saving…", with no spinner', (tester) async {
      await _pump(tester, saving: true);

      expect(find.widgetWithText(ShadButton, 'Saving…'), findsOneWidget);
      expect(find.text('Save'), findsNothing);
      expect(find.byType(CircularProgressIndicator), findsNothing);
      expect(_save(tester).enabled, isFalse);
      expect(_save(tester).onPressed, isNull);
    });
  });
}
