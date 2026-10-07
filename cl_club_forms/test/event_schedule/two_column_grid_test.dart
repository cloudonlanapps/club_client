import 'package:cl_club_forms/cl_club_forms.dart' show TwoColumnGrid;
import 'package:cl_club_forms/src/constants/form_breakpoints.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _a = Key('a');
const _b = Key('b');
const _c = Key('c');

Widget _box(Key key) => SizedBox(key: key, height: 40);

/// Mounts [grid] in a box [width] wide.
Future<void> _pump(WidgetTester tester, double width, Widget grid) async {
  await tester.binding.setSurfaceSize(const Size(1200, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    Directionality(
      textDirection: TextDirection.ltr,
      child: Align(
        alignment: Alignment.topLeft,
        child: SizedBox(width: width, child: grid),
      ),
    ),
  );
}

void main() {
  testWidgets('Issue 61: below the breakpoint the children stack in one '
      'column, each the full width', (tester) async {
    const width = FormBreakpoints.singleColumnMaxWidth - 1;
    await _pump(
      tester,
      width,
      TwoColumnGrid(children: [_box(_a), _box(_b), _box(_c)]),
    );

    expect(tester.getSize(find.byKey(_a)).width, width);
    expect(tester.getSize(find.byKey(_b)).width, width);
    expect(tester.getTopLeft(find.byKey(_a)), Offset.zero);
    // Each next child sits below the last, after the run spacing (12).
    expect(tester.getTopLeft(find.byKey(_b)), const Offset(0, 52));
    expect(tester.getTopLeft(find.byKey(_c)), const Offset(0, 104));
  });

  testWidgets('Issue 61: at the breakpoint the children pair up in two '
      'equal columns', (tester) async {
    const width = FormBreakpoints.singleColumnMaxWidth;
    await _pump(
      tester,
      width,
      TwoColumnGrid(children: [_box(_a), _box(_b), _box(_c)]),
    );

    // Two columns share the width less the spacing (12) between them.
    const column = (width - 12) / 2;
    expect(tester.getSize(find.byKey(_a)).width, column);
    expect(tester.getSize(find.byKey(_b)).width, column);
    expect(tester.getTopLeft(find.byKey(_a)), Offset.zero);
    expect(tester.getTopLeft(find.byKey(_b)), const Offset(column + 12, 0));
    // The odd child starts the next row and keeps to the left column.
    expect(tester.getTopLeft(find.byKey(_c)), const Offset(0, 52));
    expect(tester.getSize(find.byKey(_c)).width, column);
  });

  testWidgets('Issue 61: the breakpoint is 600 and is measured on the '
      "grid's own width, not the screen's", (tester) async {
    expect(FormBreakpoints.singleColumnMaxWidth, 600);

    // The surface is 1200 wide; the grid has 400 of it.
    await _pump(tester, 400, TwoColumnGrid(children: [_box(_a), _box(_b)]));

    expect(tester.getTopLeft(find.byKey(_b)).dx, 0);
    expect(tester.getTopLeft(find.byKey(_b)).dy, greaterThan(0));
  });

  testWidgets('Issue 61: a breakpoint of its own moves where the grid '
      'collapses', (tester) async {
    Widget grid() => TwoColumnGrid(
      singleColumnBreakpoint: 300,
      children: [_box(_a), _box(_b)],
    );

    await _pump(tester, 299, grid());
    expect(tester.getTopLeft(find.byKey(_b)).dx, 0);

    await _pump(tester, 300, grid());
    expect(tester.getTopLeft(find.byKey(_b)).dy, 0);
    expect(tester.getTopLeft(find.byKey(_b)).dx, greaterThan(0));
  });

  testWidgets('Issue 61: spacing separates the columns and runSpacing the '
      'rows, in both layouts', (tester) async {
    Widget grid() => TwoColumnGrid(
      spacing: 20,
      runSpacing: 30,
      children: [_box(_a), _box(_b), _box(_c)],
    );

    await _pump(tester, 800, grid());
    expect(tester.getTopLeft(find.byKey(_b)), const Offset(410, 0));
    expect(tester.getTopLeft(find.byKey(_c)), const Offset(0, 70));

    await _pump(tester, 500, grid());
    expect(tester.getTopLeft(find.byKey(_b)), const Offset(0, 70));
    expect(tester.getTopLeft(find.byKey(_c)), const Offset(0, 140));
  });

  testWidgets('Issue 61: in two columns the cells of a row align at the '
      'top by default', (tester) async {
    await _pump(
      tester,
      800,
      TwoColumnGrid(
        children: [
          const SizedBox(key: _a, height: 100),
          _box(_b),
        ],
      ),
    );

    expect(tester.getTopLeft(find.byKey(_b)).dy, 0);
    expect(tester.getSize(find.byType(TwoColumnGrid)).height, 100);
  });

  testWidgets('Issue 61: a single child is laid out alone at the full '
      'width, on any width', (tester) async {
    await _pump(tester, 800, TwoColumnGrid(children: [_box(_a)]));

    expect(tester.getSize(find.byKey(_a)).width, 800);
    expect(find.byType(Row), findsNothing);
  });

  testWidgets('Issue 61: no children take no space', (tester) async {
    await _pump(tester, 800, const TwoColumnGrid(children: []));

    expect(tester.getSize(find.byType(TwoColumnGrid)).height, 0);
  });
}
