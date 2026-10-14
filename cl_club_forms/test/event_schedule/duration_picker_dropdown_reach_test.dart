import 'package:cl_club_forms/src/widgets/event_schedule/duration_picker_column.dart';
import 'package:cl_club_forms/src/widgets/event_schedule/duration_picker_dropdown.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../support/form_harness.dart' show kPhoneSurface;

const Size _desktopSurface = Size(1280, 800);

/// Mounts the dropdown at [alignment] on a surface of [size], opens it and
/// returns the rectangles of its two columns.
Future<List<Rect>> _openAt(
  WidgetTester tester, {
  required Size size,
  required Alignment alignment,
}) async {
  await tester.binding.setSurfaceSize(size);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ShadApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Align(
            alignment: alignment,
            child: SizedBox(
              width: 110,
              child: DurationPickerDropdown(
                value: const Duration(hours: 1),
                max: const Duration(hours: 4),
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byType(DurationPickerDropdown));
  await tester.pumpAndSettle();
  return [
    for (final column in find.byType(DurationPickerColumn).evaluate())
      tester.getRect(find.byWidget(column.widget)),
  ];
}

void main() {
  group('Issue 143: the duration popover opens within reach', () {
    for (final (name, size) in [
      ('phone', kPhoneSurface),
      ('desktop', _desktopSurface),
    ]) {
      for (final alignment in [
        Alignment.topRight,
        Alignment.center,
        Alignment.bottomRight,
      ]) {
        testWidgets('Issue 143: both lists are on screen, $name, $alignment', (
          tester,
        ) async {
          final columns = await _openAt(
            tester,
            size: size,
            alignment: alignment,
          );
          final screen = Offset.zero & size;

          expect(columns, hasLength(2));
          for (final column in columns) {
            expect(
              screen.contains(column.topLeft) &&
                  screen.contains(column.bottomRight - const Offset(1, 1)),
              isTrue,
              reason: 'column $column lies outside the screen $screen',
            );
          }
        });
      }
    }

    testWidgets('Issue 143: the popover is as tall as its lists, not the '
        'screen', (tester) async {
      final columns = await _openAt(
        tester,
        size: kPhoneSurface,
        alignment: Alignment.topRight,
      );

      for (final column in columns) {
        expect(column.height, lessThan(kPhoneSurface.height / 2));
      }
    });
  });
}
