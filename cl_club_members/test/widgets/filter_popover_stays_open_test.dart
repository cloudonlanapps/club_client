import 'package:cl_club_members/src/models/group_list_filter.dart';
import 'package:cl_club_members/src/widgets/group_filter_popover.dart';
import 'package:cl_club_members/src/widgets/user_filter_popover.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class _StubUsersMasterNotifier extends ClUsersMasterNotifier {
  @override
  Future<Map<String, UserInfo>> build() async => const {};
}

Future<void> _pump(WidgetTester tester, Widget popover) async {
  await tester.binding.setSurfaceSize(const Size(1200, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clUsersMasterProvider.overrideWith(_StubUsersMasterNotifier.new),
        clRegisteredUsersProvider.overrideWith((ref) async => const []),
      ],
      child: ShadApp(
        home: Scaffold(body: Center(child: popover)),
      ),
    ),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byType(ShadButton).first);
  await tester.pumpAndSettle();
}

void main() {
  group('Issue 143: a pick in a filter leaves the filter open', () {
    testWidgets('Issue 143: the user filter stays open after a status pick', (
      tester,
    ) async {
      final chosen = <UserListFilter>[];
      await _pump(
        tester,
        UserFilterPopover(
          filter: const UserListFilter(),
          onFilterChanged: chosen.add,
        ),
      );

      await tester.tap(find.text('All statuses'));
      await tester.pumpAndSettle();
      await tester.tap(find.textContaining('Active').last);
      await tester.pumpAndSettle();

      expect(chosen.single.status, UserStatus.active);
      expect(find.text('Status'), findsOneWidget);
    });

    testWidgets('Issue 143: the group filter stays open after a type pick', (
      tester,
    ) async {
      final chosen = <GroupListFilter>[];
      await _pump(
        tester,
        GroupFilterPopover(
          filter: const GroupListFilter(),
          onFilterChanged: chosen.add,
        ),
      );

      await tester.tap(find.byType(ShadSelect<GroupTypeFilter>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Manual').last);
      await tester.pumpAndSettle();

      expect(chosen.single.typeFilter, GroupTypeFilter.manual);
      expect(find.text('Type'), findsOneWidget);
    });
  });
}
