import 'package:cl_club_members/src/widgets/cards/group_card.dart'
    show GroupMetaLine;
import 'package:cl_club_members/src/widgets/group_eligibility_section.dart';
import 'package:cl_club_members/src/widgets/group_member_list.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show clGroupMembersProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show AgeEligibilityText, FormAge;

Group _group({
  GroupKind kind = GroupKind.semiAuto,
  Age? minAge,
  Age? maxAge,
  DateTime? dobOnOrAfterUtc,
  DateTime? dobOnOrBeforeUtc,
  DateTime? eligibilityReferenceDayUtc,
}) => Group(
  id: 7,
  name: 'Juniors',
  kind: kind,
  minAge: minAge,
  maxAge: maxAge,
  dobOnOrAfterUtc: dobOnOrAfterUtc,
  dobOnOrBeforeUtc: dobOnOrBeforeUtc,
  eligibilityReferenceDayUtc: eligibilityReferenceDayUtc,
  createdAtUtc: DateTime.utc(2025),
);

Widget _wrap(Widget child, {List<Override> overrides = const []}) =>
    ProviderScope(
      overrides: overrides,
      child: ShadApp(
        home: Scaffold(body: SingleChildScrollView(child: child)),
      ),
    );

void main() {
  group('Issue 33: the group Eligibility section reads the age band', () {
    testWidgets('Issue 33: the age sentence, with the dates and the '
        'reference day beneath in muted text', (tester) async {
      await tester.pumpWidget(
        _wrap(
          GroupEligibilitySection(
            group: _group(
              minAge: const Age(years: 5),
              maxAge: const Age(years: 18),
              dobOnOrAfterUtc: DateTime.utc(2007, 6, 16),
              dobOnOrBeforeUtc: DateTime.utc(2022, 6, 14),
              eligibilityReferenceDayUtc: DateTime.utc(2026, 6, 15),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final sentence = find.text('Open to members aged 5 to 18.');
      final window = find.text(
        'Born 16 Jun 2007 – 14 Jun 2022, counted on 15 Jun 2026.',
      );
      expect(sentence, findsOneWidget);
      expect(window, findsOneWidget);
      expect(
        tester.getTopLeft(window).dy,
        greaterThan(tester.getTopLeft(sentence).dy),
      );
      expect(
        tester.widget<Text>(window).style?.color,
        ShadTheme.of(tester.element(window)).textTheme.muted.color,
      );
      expect(find.textContaining('age-based eligibility'), findsNothing);
    });

    testWidgets('Issue 33: a group with no age band shows no age sentence', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(GroupEligibilitySection(group: _group(kind: GroupKind.manual))),
      );
      await tester.pumpAndSettle();

      expect(find.text('This group is open to all.'), findsOneWidget);
      expect(find.textContaining('Open to members aged'), findsNothing);
      expect(find.textContaining('Born'), findsNothing);
    });
  });

  group('Issue 33: the group card reads the same age sentence', () {
    testWidgets('Issue 33: a banded group shows the sentence, not dates', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(
          GroupMetaLine(
            group: _group(
              minAge: const Age(years: 5),
              dobOnOrBeforeUtc: DateTime.utc(2022, 6, 14),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Open to members aged 5 and over'), findsOneWidget);
      // The card's text is the shared sentence itself.
      expect(
        find.text(
          AgeEligibilityText.sentence(minAge: const FormAge(years: 5))!,
        ),
        findsOneWidget,
      );
      expect(find.textContaining('DOB'), findsNothing);
    });

    testWidgets('Issue 33: a group with no age band shows no age text', (
      tester,
    ) async {
      await tester.pumpWidget(
        _wrap(GroupMetaLine(group: _group(kind: GroupKind.manual))),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Open to members'), findsNothing);
      expect(find.byIcon(LucideIcons.cake), findsNothing);
    });
  });

  group('Issue 33: the member list marks members no longer eligible', () {
    Future<void> pumpList(
      WidgetTester tester,
      List<GroupMember> members,
    ) async {
      await tester.pumpWidget(
        _wrap(
          const GroupMemberList(groupId: 7, kind: GroupKind.semiAuto),
          overrides: [
            clGroupMembersProvider.overrideWith((ref, id) async => members),
          ],
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Issue 33: a member reported not eligible is marked, and the '
        'list shows the count', (tester) async {
      await pumpList(tester, const [
        GroupMember(membername: 'workflow_a', firstName: 'Asha'),
        GroupMember(
          membername: 'workflow_b',
          firstName: 'Bala',
          eligible: false,
        ),
        GroupMember(
          membername: 'workflow_c',
          firstName: 'Chitra',
          eligible: false,
        ),
      ]);

      expect(find.text(AgeEligibilityText.noLongerEligible), findsNWidgets(2));
      expect(find.text('2 members no longer eligible'), findsOneWidget);
      // The mark sits in the ineligible member's own row.
      final balaRow = find.ancestor(
        of: find.text('@workflow_b'),
        matching: find.byType(Column),
      );
      expect(
        find.descendant(
          of: balaRow.first,
          matching: find.text(AgeEligibilityText.noLongerEligible),
        ),
        findsOneWidget,
      );
      final ashaRow = find.ancestor(
        of: find.text('@workflow_a'),
        matching: find.byType(Column),
      );
      expect(
        find.descendant(
          of: ashaRow.first,
          matching: find.text(AgeEligibilityText.noLongerEligible),
        ),
        findsNothing,
      );
    });

    testWidgets('Issue 33: one ineligible member reads in the singular', (
      tester,
    ) async {
      await pumpList(tester, const [
        GroupMember(membername: 'workflow_b', eligible: false),
      ]);

      expect(find.text('1 member no longer eligible'), findsOneWidget);
    });

    testWidgets('Issue 33: with every member eligible there is no mark and '
        'no count', (tester) async {
      await pumpList(tester, const [
        GroupMember(membername: 'workflow_a'),
        GroupMember(membername: 'workflow_b'),
      ]);

      expect(find.text(AgeEligibilityText.noLongerEligible), findsNothing);
      expect(find.textContaining('no longer eligible'), findsNothing);
    });
  });
}
