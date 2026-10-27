// Issue 389: a section card may carry a widget at the right end of its
// title row (the Facts help of the application editor), in both modes.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

void main() {
  testWidgets('Issue 389: the title trailing sits after the pencil, on the '
      'title row, in read and edit mode', (tester) async {
    await tester.pumpWidget(
      ShadApp(
        home: Scaffold(
          body: EditableSectionCard<String>(
            title: 'Facts',
            canEdit: true,
            titleTrailing: const Text('HELP'),
            read: const Text('READ MODE'),
            editBuilder: ({required enabled}) => const Text('EDIT FORM'),
            onValidate: () => 'value',
            onSave: (_) async => true,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final title = tester.getCenter(find.text('Facts'));
    final pencil = tester.getCenter(find.byIcon(LucideIcons.pencil));
    final help = tester.getCenter(find.text('HELP'));
    expect(help.dy, closeTo(title.dy, 2));
    expect(help.dx, greaterThan(pencil.dx));

    await tester.tap(find.byIcon(LucideIcons.pencil));
    await tester.pumpAndSettle();
    expect(find.text('EDIT FORM'), findsOneWidget);
    expect(find.text('HELP'), findsOneWidget);
  });
}
