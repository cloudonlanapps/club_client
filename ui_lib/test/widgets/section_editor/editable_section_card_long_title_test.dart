// Issue 408: a section card's title wraps on a phone, keeping the pencil
// and the title trailing at the end of the title row.
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

const String _longTitle =
    'Selection: attend training camp and the district championship '
    'selection trials';

Future<void> _pump(
  WidgetTester tester, {
  required String title,
  Widget? titleTrailing,
  IconData? leadingIcon,
}) async {
  await tester.binding.setSurfaceSize(const Size(360, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: EditableSectionCard<String>(
            title: title,
            canEdit: true,
            leadingIcon: leadingIcon,
            titleTrailing: titleTrailing,
            read: const Text('READ MODE'),
            editBuilder: ({required enabled}) => const Text('EDIT FORM'),
            onValidate: () => 'value',
            onSave: (_) async => true,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 408: a long section title at 360 px', () {
    testWidgets('Issue 408: wraps without overflow in read and edit mode, '
        'the pencil at the end of the row', (tester) async {
      await _pump(tester, title: _longTitle, leadingIcon: LucideIcons.list);
      expect(tester.takeException(), isNull);

      final title = find.text(_longTitle);
      final pencil = find.byType(SectionEditButton);
      // Wrapped: taller than one line of its own style.
      expect(tester.getSize(title).height, greaterThan(40));
      expect(
        tester.getTopLeft(pencil).dx,
        greaterThanOrEqualTo(tester.getTopRight(title).dx),
      );
      expect(tester.getTopRight(pencil).dx, lessThanOrEqualTo(360));

      await tester.tap(pencil);
      await tester.pumpAndSettle();
      expect(find.text('EDIT FORM'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('Issue 408: wraps without overflow beside a title trailing', (
      tester,
    ) async {
      await _pump(
        tester,
        title: _longTitle,
        titleTrailing: const Icon(LucideIcons.circleHelp, size: 18),
      );
      expect(tester.takeException(), isNull);
      final help = find.byIcon(LucideIcons.circleHelp);
      expect(
        tester.getTopLeft(help).dx,
        greaterThan(tester.getTopRight(find.byType(SectionEditButton)).dx),
      );
      expect(tester.getTopRight(help).dx, lessThanOrEqualTo(360));

      await tester.tap(find.byType(SectionEditButton));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(help, findsOneWidget);
    });

    testWidgets('Issue 408: a short title keeps the pencil at the right end '
        'of the card', (tester) async {
      await _pump(tester, title: 'Contact');
      expect(tester.takeException(), isNull);
      final title = find.text('Contact');
      final pencil = find.byType(SectionEditButton);
      expect(
        tester.getCenter(pencil).dy,
        closeTo(tester.getCenter(title).dy, 2),
      );
      // The pencil sits at the card's right padding, far from the title.
      expect(tester.getTopRight(pencil).dx, greaterThan(300));
      expect(tester.getTopLeft(title).dx, lessThan(60));
    });
  });
}
