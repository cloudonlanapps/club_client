import 'package:cl_club_forms/cl_club_forms.dart'
    show RenameForm, RenameFormFields;
import 'package:cl_club_members/src/views/group_profile_view.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClGroupsMasterNotifier, clGroupsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

final _group = Group(
  id: 7,
  name: 'Juniors',
  kind: GroupKind.manual,
  createdAtUtc: DateTime.utc(2025),
);

/// Records the renames the view sends, and refuses them with [refusal] when
/// one is set.
class _Groups extends ClGroupsMasterNotifier {
  _Groups({this.refusal});

  final Exception? refusal;
  final List<String?> renamed = [];

  @override
  Future<Map<int, Group>> build() async => {_group.id: _group};

  @override
  Future<Group> updateGroup(
    int id, {
    String? name,
    String? Function()? description,
    Age? Function()? minAge,
    Age? Function()? maxAge,
    bool? strictAge,
    Gender? Function()? gender,
    bool? semiAuto,
  }) async {
    renamed.add(name);
    final refused = refusal;
    if (refused != null) throw refused;
    return _group;
  }
}

/// Mounts a button that runs the admin view's Rename action for [_group].
Future<_Groups> _pump(WidgetTester tester, {Exception? refusal}) async {
  final groups = _Groups(refusal: refusal);
  final view = AdminGroupProfileView(
    groupId: _group.id,
    onOpenRequests: () {},
    onOpenAllMembers: () {},
    onDeleted: () {},
  );
  await tester.pumpWidget(
    ProviderScope(
      overrides: [clGroupsMasterProvider.overrideWith(() => groups)],
      child: ShadApp(
        home: Scaffold(
          body: Consumer(
            builder: (context, ref, _) {
              ref.watch(clGroupsMasterProvider);
              return ShadButton(
                onPressed: () => view.handleRename(ref, context),
                child: const Text('Rename'),
              );
            },
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return groups;
}

Finder _nameField() => find.byWidgetPredicate(
  (w) => w is ShadInputFormField && w.id == RenameFormFields.valueId,
);

Future<void> _rename(WidgetTester tester, String name) async {
  await tester.tap(find.text('Rename'));
  await tester.pumpAndSettle();
  await tester.enterText(_nameField(), name);
  await tester.tap(find.widgetWithText(ShadButton, 'Save'));
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 95: the group profile renames while the dialog is open', () {
    testWidgets('Issue 95: a refused group rename leaves the dialog open '
        'with the typed name and the message on the field', (tester) async {
      final groups = await _pump(tester, refusal: Exception('refused'));

      await _rename(tester, 'Seniors');

      expect(groups.renamed, ['Seniors']);
      expect(_nameField(), findsOneWidget);
      expect(find.text('Seniors'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(RenameForm),
          matching: find.text(AdminGroupProfileView.renameFailedMessage),
        ),
        findsOneWidget,
      );
      expect(find.text('Group renamed.'), findsNothing);
    });

    testWidgets('Issue 95: a saved group rename closes the dialog and says '
        'so', (tester) async {
      final groups = await _pump(tester);

      await _rename(tester, 'Seniors');

      expect(groups.renamed, ['Seniors']);
      expect(_nameField(), findsNothing);
      expect(find.text('Group renamed.'), findsOneWidget);
    });
  });
}
