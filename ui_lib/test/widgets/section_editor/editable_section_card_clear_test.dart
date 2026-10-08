import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

/// A host whose "form" is one flag: it holds a value until Clear empties it.
class _Host extends StatefulWidget {
  const _Host({required this.offersClear, this.startsWithValue = true});

  final bool offersClear;
  final bool startsWithValue;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late bool hasValue = widget.startsWithValue;
  int clears = 0;
  final List<String> saved = [];

  @override
  Widget build(BuildContext context) {
    return EditableSectionCard<String>(
      title: 'Demo',
      canEdit: true,
      read: const Text('READ MODE'),
      editBuilder: ({required enabled}) =>
          Text(hasValue ? 'FORM WITH VALUE' : 'EMPTY FORM'),
      onValidate: () => hasValue ? 'value' : 'empty',
      isDirty: () => true,
      onSave: (value) async {
        saved.add(value);
        return true;
      },
      onClear: widget.offersClear
          ? () => setState(() {
              hasValue = false;
              clears++;
            })
          : null,
      canClear: widget.offersClear ? () => hasValue : null,
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
  testWidgets('Issue 34: a card given no clear action shows no Clear', (
    tester,
  ) async {
    await _pump(tester, const _Host(offersClear: false));
    expect(find.text('Clear'), findsNothing);

    await _openEditor(tester);

    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Clear'), findsNothing);
  });

  testWidgets('Issue 34: Clear shows in edit mode only, beside Cancel and '
      'Save', (tester) async {
    await _pump(tester, const _Host(offersClear: true));
    expect(find.text('Clear'), findsNothing, reason: 'read mode');

    await _openEditor(tester);

    final clear = find.text('Clear');
    expect(clear, findsOneWidget);
    final clearBox = tester.getRect(clear);
    final cancelBox = tester.getRect(find.text('Cancel'));
    final saveBox = tester.getRect(find.text('Save'));
    expect(clearBox.center.dy, moreOrLessEquals(cancelBox.center.dy));
    expect(clearBox.right, lessThan(cancelBox.left));
    expect(cancelBox.right, lessThan(saveBox.left));
  });

  testWidgets('Issue 34: Clear is hidden while the form holds no value', (
    tester,
  ) async {
    await _pump(
      tester,
      const _Host(offersClear: true, startsWithValue: false),
    );
    await _openEditor(tester);

    expect(find.text('Save'), findsOneWidget);
    expect(find.text('Clear'), findsNothing);
  });

  testWidgets('Issue 34: pressing Clear calls the host, hides the button and '
      'keeps the card in edit mode without saving', (tester) async {
    final host = await _pump(tester, const _Host(offersClear: true));
    await _openEditor(tester);

    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    expect(host.clears, 1);
    expect(host.saved, isEmpty);
    expect(find.text('EMPTY FORM'), findsOneWidget);
    expect(find.text('Clear'), findsNothing);
    expect(find.text('Save'), findsOneWidget, reason: 'still editing');
  });

  testWidgets('Issue 34: Save after Clear saves the emptied form', (
    tester,
  ) async {
    final host = await _pump(tester, const _Host(offersClear: true));
    await _openEditor(tester);
    await tester.tap(find.text('Clear'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Save'));
    await tester.pumpAndSettle();

    expect(host.saved, ['empty']);
    expect(find.text('READ MODE'), findsOneWidget);
  });
}
