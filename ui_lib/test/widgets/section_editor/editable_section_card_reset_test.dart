import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

/// A host whose "form" is one flag: it holds a value until Reset empties it.
class _Host extends StatefulWidget {
  const _Host({required this.offersReset, this.startsWithValue = true});

  final bool offersReset;
  final bool startsWithValue;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late bool hasValue = widget.startsWithValue;
  int resets = 0;
  final List<String> saved = [];

  @override
  Widget build(BuildContext context) {
    return EditableSectionCard<String>(
      title: 'Demo',
      canEdit: true,
      read: const Text('READ MODE'),
      editBuilder: () => Text(hasValue ? 'FORM WITH VALUE' : 'EMPTY FORM'),
      onValidate: () => hasValue ? 'value' : 'empty',
      isDirty: () => true,
      onSave: (value) async {
        saved.add(value);
        return true;
      },
      onReset: widget.offersReset
          ? () => setState(() {
              hasValue = false;
              resets++;
            })
          : null,
      canReset: widget.offersReset ? () => hasValue : null,
    );
  }
}

Future<_HostState> _pump(WidgetTester tester, _Host host) async {
  await tester.pumpWidget(ShadApp(home: Scaffold(body: host)));
  await tester.pumpAndSettle();
  return tester.state<_HostState>(find.byType(_Host));
}

Future<void> _openEditor(WidgetTester tester) async {
  await tester.tap(find.byType(SectionEditButton));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Issue 34: a card given no reset action shows no Reset', (
    tester,
  ) async {
    await _pump(tester, const _Host(offersReset: false));
    expect(find.text('Reset'), findsNothing);

    await _openEditor(tester);

    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Reset'), findsNothing);
  });

  testWidgets('Issue 34: Reset shows in edit mode only, beside Cancel and '
      'Save', (tester) async {
    await _pump(tester, const _Host(offersReset: true));
    expect(find.text('Reset'), findsNothing, reason: 'read mode');

    await _openEditor(tester);

    final reset = find.text('Reset');
    expect(reset, findsOneWidget);
    final resetBox = tester.getRect(reset);
    final cancelBox = tester.getRect(find.text('Cancel'));
    final saveBox = tester.getRect(find.text('Save'));
    expect(resetBox.center.dy, moreOrLessEquals(cancelBox.center.dy));
    expect(resetBox.right, lessThan(cancelBox.left));
    expect(cancelBox.right, lessThan(saveBox.left));
  });

  testWidgets('Issue 34: Reset is hidden while the form holds no value', (
    tester,
  ) async {
    await _pump(
      tester,
      const _Host(offersReset: true, startsWithValue: false),
    );
    await _openEditor(tester);

    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Reset'), findsNothing);
  });

  testWidgets('Issue 34: pressing Reset calls the host, hides the button and '
      'keeps the card in edit mode without saving', (tester) async {
    final host = await _pump(tester, const _Host(offersReset: true));
    await _openEditor(tester);

    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    expect(host.resets, 1);
    expect(host.saved, isEmpty);
    expect(find.text('EMPTY FORM'), findsOneWidget);
    expect(find.text('Reset'), findsNothing);
    expect(find.text('Save'), findsOneWidget, reason: 'still editing');
  });

  testWidgets('Issue 34: Save after Reset saves the emptied form', (
    tester,
  ) async {
    final host = await _pump(tester, const _Host(offersReset: true));
    await _openEditor(tester);
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(host.saved, ['empty']);
    expect(find.text('READ MODE'), findsOneWidget);
  });
}
