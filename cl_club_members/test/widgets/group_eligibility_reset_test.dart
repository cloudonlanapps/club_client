import 'package:cl_club_members/src/views/group_create_view.dart';
import 'package:cl_club_members/src/widgets/group_eligibility_section.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClGroupsMasterNotifier, clGroupMembersProvider, clGroupsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/age_eligibility/age_eligibility_fields.dart'
    show AgeEligibilityFields;
import 'package:ui_lib/src/widgets/age_eligibility/age_eligibility_form_fields.dart'
    show AgeEligibilityFormFields;
import 'package:ui_lib/ui_lib.dart' show GroupFormFields, SectionEditButton;

Group _group({
  GroupKind kind = GroupKind.semiAuto,
  Gender? gender,
  Age? minAge,
  Age? maxAge,
  bool strictAge = false,
}) => Group(
  id: 7,
  name: 'Juniors',
  kind: kind,
  gender: gender,
  minAge: minAge,
  maxAge: maxAge,
  strictAge: strictAge,
  createdAtUtc: DateTime.utc(2025),
);

/// What one group write carried.
class _Sent {
  _Sent({
    required this.name,
    required this.minAge,
    required this.maxAge,
    required this.strictAge,
    required this.gender,
    required this.semiAuto,
    required this.sentEveryGetter,
  });
  final String? name;
  final Age? minAge;
  final Age? maxAge;
  final bool? strictAge;
  final Gender? gender;
  final bool? semiAuto;

  /// Whether gender and both ages came with a getter (so they are cleared,
  /// not left as they were).
  final bool sentEveryGetter;
}

/// Records the group writes the hosts send.
class _RecordingGroups extends ClGroupsMasterNotifier {
  final Group answer = _group();
  final List<_Sent> created = [];
  final List<_Sent> updated = [];

  @override
  Future<Map<int, Group>> build() async => {answer.id: answer};

  @override
  Future<Group> createGroup({
    required String name,
    String? description,
    Age? minAge,
    Age? maxAge,
    bool? strictAge,
    Gender? gender,
    bool? semiAuto,
  }) async {
    created.add(
      _Sent(
        name: name,
        minAge: minAge,
        maxAge: maxAge,
        strictAge: strictAge,
        gender: gender,
        semiAuto: semiAuto,
        sentEveryGetter: true,
      ),
    );
    return answer;
  }

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
    updated.add(
      _Sent(
        name: name,
        minAge: minAge?.call(),
        maxAge: maxAge?.call(),
        strictAge: strictAge,
        gender: gender?.call(),
        semiAuto: semiAuto,
        sentEveryGetter: minAge != null && maxAge != null && gender != null,
      ),
    );
    return answer;
  }
}

Future<_RecordingGroups> _pump(
  WidgetTester tester,
  Widget child, {
  List<GroupMember> members = const [],
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final groups = _RecordingGroups();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clGroupsMasterProvider.overrideWith(() => groups),
        clGroupMembersProvider.overrideWith((ref, id) async => members),
      ],
      child: ShadApp(home: Scaffold(body: child)),
    ),
  );
  await tester.pumpAndSettle();
  return groups;
}

Future<_RecordingGroups> _pumpSection(
  WidgetTester tester,
  Group group, {
  List<GroupMember> members = const [],
}) => _pump(
  tester,
  SingleChildScrollView(
    child: GroupEligibilitySection(group: group, canEdit: true),
  ),
  members: members,
);

Finder _input(String id) => find.byWidgetPredicate(
  (w) => w is ShadInputFormField && w.id == id,
);

String _text(WidgetTester tester, String id) => tester
    .widget<EditableText>(
      find.descendant(of: _input(id), matching: find.byType(EditableText)),
    )
    .controller
    .text;

Future<void> _openEditor(WidgetTester tester) async {
  await tester.tap(find.byType(SectionEditButton));
  await tester.pumpAndSettle();
}

Future<void> _tap(WidgetTester tester, String label) async {
  await tester.tap(find.text(label));
  await tester.pumpAndSettle();
}

/// Picks [mode] in the Mode select, which currently shows [from].
Future<void> _pickMode(
  WidgetTester tester, {
  required String from,
  required String mode,
}) async {
  await tester.tap(find.text(from));
  await tester.pumpAndSettle();
  await tester.tap(find.text(mode).last);
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 34: the group Eligibility section', () {
    testWidgets('Issue 34: no Reset in read mode, nor in the editor of a '
        'Manual group', (tester) async {
      await _pumpSection(tester, _group(kind: GroupKind.manual));
      expect(find.text('Reset'), findsNothing);

      await _openEditor(tester);

      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Reset'), findsNothing);
    });

    testWidgets('Issue 34: Reset shows as soon as the editor opens on a '
        'group with a gender, an age or the Strict age check', (tester) async {
      for (final group in [
        _group(gender: Gender.female),
        _group(minAge: const Age(years: 5)),
        _group(maxAge: const Age(years: 18)),
        _group(minAge: const Age(years: 5), strictAge: true),
      ]) {
        await _pumpSection(tester, group);
        expect(find.text('Reset'), findsNothing, reason: 'read mode');

        await _openEditor(tester);

        expect(find.text('Reset'), findsOneWidget, reason: '$group');
        await tester.pumpWidget(const SizedBox.shrink());
      }
    });

    testWidgets('Issue 34: Reset appears once a criterion is typed into a '
        'Manual group switched to Semi-auto', (tester) async {
      await _pumpSection(tester, _group(kind: GroupKind.manual));
      await _openEditor(tester);
      await _pickMode(tester, from: 'Manual', mode: 'Semi-auto');
      expect(find.text('Reset'), findsNothing);

      await tester.enterText(
        _input(AgeEligibilityFormFields.minAgeYearsId),
        '5',
      );
      await tester.pumpAndSettle();

      expect(find.text('Reset'), findsOneWidget);
    });

    testWidgets('Issue 34: pressing Reset empties the criteria, sets the '
        'mode to Manual, hides the button and stores nothing', (tester) async {
      final groups = await _pumpSection(
        tester,
        _group(
          gender: Gender.female,
          minAge: const Age(years: 5),
          maxAge: const Age(years: 18),
          strictAge: true,
        ),
      );
      await _openEditor(tester);

      await _tap(tester, 'Reset');

      expect(find.text('Reset'), findsNothing);
      expect(find.text('Save'), findsOneWidget, reason: 'still editing');
      expect(find.text('Manual'), findsOneWidget);
      expect(find.text(AgeEligibilityFields.minAgeTitle), findsNothing);
      expect(groups.updated, isEmpty);
    });

    testWidgets('Issue 34: Save after Reset stores a Manual group with no '
        'eligibility', (tester) async {
      final groups = await _pumpSection(
        tester,
        _group(
          gender: Gender.female,
          minAge: const Age(years: 5),
          maxAge: const Age(years: 18),
          strictAge: true,
        ),
      );
      await _openEditor(tester);
      await _tap(tester, 'Reset');

      await _tap(tester, 'Save');

      final sent = groups.updated.single;
      expect(sent.sentEveryGetter, isTrue);
      expect(sent.gender, isNull);
      expect(sent.minAge, isNull);
      expect(sent.maxAge, isNull);
      expect(sent.strictAge, isFalse);
      expect(sent.semiAuto, isNull, reason: 'Manual');
    });

    testWidgets('Issue 34: Cancel after Reset stores nothing and the editor '
        'reopens on the old values', (tester) async {
      final groups = await _pumpSection(
        tester,
        _group(minAge: const Age(years: 5), maxAge: const Age(years: 18)),
      );
      await _openEditor(tester);
      await _tap(tester, 'Reset');

      await _tap(tester, 'Cancel');

      expect(groups.updated, isEmpty);
      expect(find.text('Open to members aged 5 to 18.'), findsOneWidget);

      await _openEditor(tester);

      expect(find.text('Semi-auto'), findsOneWidget);
      expect(_text(tester, AgeEligibilityFormFields.minAgeYearsId), '5');
      expect(_text(tester, AgeEligibilityFormFields.maxAgeYearsId), '18');
      expect(find.text('Reset'), findsOneWidget);
    });

    testWidgets('Issue 34: Reset is not shown while the mode is locked '
        'because the group has members', (tester) async {
      await _pumpSection(
        tester,
        _group(minAge: const Age(years: 5), maxAge: const Age(years: 18)),
        members: const [GroupMember(membername: 'workflow_a')],
      );
      await _openEditor(tester);

      expect(
        find.text('Mode cannot be changed — the group already has members.'),
        findsOneWidget,
      );
      expect(find.text('Save'), findsOneWidget);
      expect(find.text('Reset'), findsNothing);
    });
  });

  group('Issue 34: group create', () {
    Future<_RecordingGroups> pumpCreate(WidgetTester tester) => _pump(
      tester,
      GroupCreateView(onCreated: () {}, onCancel: () {}),
    );

    testWidgets('Issue 34: no Reset on a fresh Manual group; it appears in '
        'the eligibility block once a criterion is set', (tester) async {
      await pumpCreate(tester);
      expect(find.text('Reset'), findsNothing);

      await _pickMode(tester, from: 'Manual', mode: 'Auto');
      expect(find.text('Reset'), findsNothing);

      await tester.enterText(
        _input(AgeEligibilityFormFields.maxAgeYearsId),
        '12',
      );
      await tester.pumpAndSettle();

      final reset = find.text('Reset');
      expect(reset, findsOneWidget);
      // Inside the eligibility block, not down with Cancel / Create group.
      expect(
        tester.getTopLeft(reset).dy,
        lessThan(tester.getTopLeft(find.text('Add me into the group')).dy),
      );
    });

    testWidgets('Issue 34: Reset empties the block and sets the mode to '
        'Manual; Create group then stores a group with no eligibility', (
      tester,
    ) async {
      final groups = await pumpCreate(tester);
      await tester.enterText(_input(GroupFormFields.nameId), 'Juniors');
      await _pickMode(tester, from: 'Manual', mode: 'Auto');
      await tester.enterText(
        _input(AgeEligibilityFormFields.maxAgeYearsId),
        '12',
      );
      await tester.tap(find.byType(ShadCheckbox));
      await tester.pumpAndSettle();

      await _tap(tester, 'Reset');

      expect(find.text('Reset'), findsNothing);
      expect(find.text('Manual'), findsOneWidget);
      expect(find.text(AgeEligibilityFields.maxAgeTitle), findsNothing);
      expect(groups.created, isEmpty);

      await _tap(tester, 'Create group');

      final sent = groups.created.single;
      expect(sent.name, 'Juniors');
      expect(sent.gender, isNull);
      expect(sent.minAge, isNull);
      expect(sent.maxAge, isNull);
      expect(sent.strictAge, isFalse);
      expect(sent.semiAuto, isNull, reason: 'Manual');
    });
  });
}
