import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../support/form_harness.dart';

/// What the application form tests share on top of `form_harness.dart`.

/// The selects inside the field with [id], in order.
Finder selectsIn(String id) => find.descendant(
  of: fieldWithId(id),
  matching: find.byWidgetPredicate(
    (widget) => widget.runtimeType.toString().startsWith('ShadSelect<'),
  ),
);

/// Opens the [index]th select inside the field with [id].
Future<void> openIn(WidgetTester tester, String id, int index) async {
  final select = selectsIn(id).at(index);
  await tester.ensureVisible(select);
  await tester.pumpAndSettle();
  await tester.tapAt(tester.getTopLeft(select) + const Offset(24, 16));
  await tester.pumpAndSettle();
}

/// Opens the [index]th select inside the field with [id] and picks the
/// option reading [option].
Future<void> pickIn(
  WidgetTester tester,
  String id,
  int index,
  String option,
) async {
  await openIn(tester, id, index);
  await tester.tap(find.text(option).last);
  await tester.pumpAndSettle();
}

/// The [index]th text input inside the field with [id].
Finder inputIn(String id, int index) => find
    .descendant(of: fieldWithId(id), matching: find.byType(EditableText))
    .at(index);

/// Types [text] into the [index]th text input inside the field with [id].
Future<void> typeIn(
  WidgetTester tester,
  String id,
  int index,
  String text,
) async {
  await tester.enterText(inputIn(id, index), text);
  await tester.pump();
}

/// Taps the [index]th widget [matching] inside the field with [id].
Future<void> tapIn(
  WidgetTester tester,
  String id,
  Finder matching, [
  int index = 0,
]) async {
  final target = find
      .descendant(of: fieldWithId(id), matching: matching)
      .at(index);
  await tester.ensureVisible(target);
  await tester.pumpAndSettle();
  await tester.tap(target);
  await tester.pumpAndSettle();
}
