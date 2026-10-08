import 'package:cl_club_forms/src/widgets/age_eligibility/age_eligibility_form_fields.dart'
    show AgeEligibilityFormFields;
import 'package:cl_club_forms/src/widgets/group_form/group_membership_heading.dart'
    show GroupMembershipHeading;
import 'package:cl_club_members/src/models/group_form_helpers.dart'
    show GroupFormSubmit;
import 'package:cl_club_members/src/widgets/group_eligibility_section.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClGroupsMasterNotifier, clGroupMembersProvider, clGroupsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show SectionEditButton;

const _members = [
  GroupMember(membername: 'workflow_a'),
  GroupMember(membername: 'workflow_b'),
];

Group _group({GroupKind kind = GroupKind.semiAuto, bool criteria = true}) =>
    Group(
      id: 7,
      name: 'Juniors',
      kind: kind,
      minAge: criteria ? const Age(years: 5) : null,
      maxAge: criteria ? const Age(years: 18) : null,
      createdAtUtc: DateTime.utc(2025),
    );

/// What one eligibility write carried.
typedef _Sent = ({Age? minAge, Age? maxAge, Gender? gender, bool? semiAuto});

/// Records the eligibility writes the section sends, and refuses them with
/// [refusal] when one is set.
class _Groups extends ClGroupsMasterNotifier {
  _Groups(this.group, {this.refusal});

  final Group group;
  final Exception? refusal;
  final List<_Sent> updated = [];

  @override
  Future<Map<int, Group>> build() async => {group.id: group};

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
    updated.add((
      minAge: minAge?.call(),
      maxAge: maxAge?.call(),
      gender: gender?.call(),
      semiAuto: semiAuto,
    ));
    final refused = refusal;
    if (refused != null) throw refused;
    return group;
  }
}

/// Mounts the section of [group], which has [_members], with its editor
/// open. `memberReads` counts how often the member list was asked for.
Future<({_Groups groups, List<int> memberReads})> _openEditorOf(
  WidgetTester tester,
  Group group, {
  Exception? refusal,
}) async {
  tester.view.physicalSize = const Size(1200, 2400);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final groups = _Groups(group, refusal: refusal);
  final memberReads = <int>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clGroupsMasterProvider.overrideWith(() => groups),
        clGroupMembersProvider.overrideWith((ref, id) async {
          memberReads.add(id);
          return _members;
        }),
      ],
      child: ShadApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: GroupEligibilitySection(group: group, canEdit: true),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byType(SectionEditButton));
  await tester.pumpAndSettle();
  return (groups: groups, memberReads: memberReads);
}

Finder _input(String id) => find.byWidgetPredicate(
  (w) => w is ShadInputFormField && w.id == id,
);

Future<void> _type(WidgetTester tester, String id, String text) async {
  await tester.enterText(_input(id), text);
  await tester.pumpAndSettle();
}

Future<void> _save(WidgetTester tester) async {
  await tester.tap(find.text('Save'));
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
  group('Issue 96: the Eligibility of a group with members is edited like '
      'any other', () {
    testWidgets('Issue 96: a semi-auto group with members: a criteria change '
        'every member meets is saved', (tester) async {
      final host = await _openEditorOf(tester, _group());

      expect(find.text(GroupMembershipHeading.modeHint), findsOneWidget);
      await _type(tester, AgeEligibilityFormFields.maxAgeYearsId, '16');
      await _save(tester);

      final sent = host.groups.updated.single;
      expect(sent.minAge, const Age(years: 5));
      expect(sent.maxAge, const Age(years: 16));
      expect(sent.semiAuto, isTrue);
      expect(find.text('Eligibility updated.'), findsOneWidget);
      expect(find.text('Save'), findsNothing, reason: 'the editor closed');
    });

    testWidgets('Issue 96: a criterion a member does not meet: the form '
        'stays open and names the members inline', (tester) async {
      const refusal = ServerException(
        statusCode: 422,
        code: SdkErrorCode.membersIneligible,
        message: 'refused',
        details: {
          'membernames': ['workflow_a', 'workflow_b'],
        },
      );
      final host = await _openEditorOf(tester, _group(), refusal: refusal);

      await _type(tester, AgeEligibilityFormFields.maxAgeYearsId, '6');
      await _save(tester);

      expect(host.groups.updated, hasLength(1));
      expect(find.text('Save'), findsOneWidget, reason: 'still editing');
      expect(
        find.text(GroupFormSubmit.membersIneligibleMessage(refusal)),
        findsOneWidget,
      );
      expect(find.textContaining('workflow_a, workflow_b'), findsOneWidget);
    });

    testWidgets('Issue 96: a manual group with members switched to auto: the '
        'refusal shows on the Mode field', (tester) async {
      final host = await _openEditorOf(
        tester,
        _group(kind: GroupKind.manual, criteria: false),
        refusal: const ServerException(
          statusCode: 409,
          code: SdkErrorCode.membersExist,
          message: 'refused',
        ),
      );

      await _pickMode(tester, from: 'Manual', mode: 'Auto');
      await _type(tester, AgeEligibilityFormFields.minAgeYearsId, '5');
      await _save(tester);

      final sent = host.groups.updated.single;
      expect(sent.minAge, const Age(years: 5));
      expect(sent.semiAuto, isFalse);
      expect(find.text('Save'), findsOneWidget, reason: 'still editing');
      expect(find.text(GroupFormSubmit.membersExistMessage), findsOneWidget);
    });

    testWidgets('Issue 96: a semi-auto group with members switched to manual '
        'is saved', (tester) async {
      final host = await _openEditorOf(tester, _group());

      await _pickMode(tester, from: 'Semi-auto', mode: 'Manual');
      await _save(tester);

      final sent = host.groups.updated.single;
      expect(sent.minAge, isNull);
      expect(sent.maxAge, isNull);
      expect(sent.gender, isNull);
      expect(sent.semiAuto, isNull, reason: 'Manual');
      expect(find.text('Eligibility updated.'), findsOneWidget);
      expect(find.text('Save'), findsNothing, reason: 'the editor closed');
    });

    testWidgets('Issue 96: an auto group with matching members can be '
        'edited', (tester) async {
      final host = await _openEditorOf(tester, _group(kind: GroupKind.auto));

      await _type(tester, AgeEligibilityFormFields.minAgeYearsId, '7');
      await _save(tester);

      final sent = host.groups.updated.single;
      expect(sent.minAge, const Age(years: 7));
      expect(sent.maxAge, const Age(years: 18));
      expect(sent.semiAuto, isFalse);
      expect(find.text('Eligibility updated.'), findsOneWidget);
    });

    testWidgets('Issue 96: Reset is offered for a group with members that '
        'holds criteria', (tester) async {
      await _openEditorOf(tester, _group());

      expect(find.text('Reset'), findsOneWidget);
    });

    testWidgets('Issue 96: the section does not read the member list', (
      tester,
    ) async {
      final host = await _openEditorOf(tester, _group());

      expect(host.memberReads, isEmpty);
    });
  });
}
