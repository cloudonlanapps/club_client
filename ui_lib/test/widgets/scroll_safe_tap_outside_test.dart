import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ui_lib/ui_lib.dart';

const _fieldKey = Key('field');
const _outsideKey = Key('outside');

Future<FocusNode> _pump(WidgetTester tester) async {
  final focus = FocusNode();
  addTearDown(focus.dispose);
  await tester.pumpWidget(
    ScrollSafeTapOutside(
      unfocusOnTouchTap: true,
      child: MaterialApp(
        home: Scaffold(
          body: ListView(
            children: [
              TextField(key: _fieldKey, focusNode: focus),
              const SizedBox(key: _outsideKey, height: 2000),
            ],
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.byKey(_fieldKey));
  await tester.pump();
  expect(focus.hasFocus, isTrue);
  return focus;
}

Offset _outside(WidgetTester tester) =>
    tester.getTopLeft(find.byKey(_outsideKey)) + const Offset(40, 120);

void main() {
  testWidgets('Issue 159: a touch drag that starts outside the field keeps '
      'its focus', (tester) async {
    final focus = await _pump(tester);

    await tester.dragFrom(
      _outside(tester),
      const Offset(0, -200),
      kind: PointerDeviceKind.touch,
    );
    await tester.pumpAndSettle();

    expect(focus.hasFocus, isTrue);
  });

  testWidgets('Issue 159: a touch tap outside the field drops its focus', (
    tester,
  ) async {
    final focus = await _pump(tester);

    await tester.tapAt(_outside(tester), kind: PointerDeviceKind.touch);
    await tester.pump();

    expect(focus.hasFocus, isFalse);
  });

  testWidgets('Issue 159: a mouse press outside the field drops its focus '
      'as before', (tester) async {
    final focus = await _pump(tester);

    final gesture = await tester.startGesture(
      _outside(tester),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pump();
    expect(focus.hasFocus, isFalse);
    await gesture.up();
  });

  testWidgets(
    'Issue 159: in a native app a touch tap outside keeps the focus',
    (tester) async {
      final focus = FocusNode();
      addTearDown(focus.dispose);
      await tester.pumpWidget(
        ScrollSafeTapOutside(
          child: MaterialApp(
            home: Scaffold(
              body: ListView(
                children: [
                  TextField(key: _fieldKey, focusNode: focus),
                  const SizedBox(key: _outsideKey, height: 2000),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.byKey(_fieldKey));
      await tester.pump();

      await tester.tapAt(_outside(tester), kind: PointerDeviceKind.touch);
      await tester.pump();

      expect(focus.hasFocus, isTrue);
    },
  );
}
