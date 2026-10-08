import 'dart:async';

import 'package:cl_club_forms/cl_club_forms.dart' show GroupFormFields;
import 'package:cl_club_members/src/views/group_create_view.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show ClGroupsMasterNotifier, clGroupsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ConfirmDialog, DiscardChangesPrompt;

/// Counts the creates the view sends on [host]; each waits for [hold] when
/// there is one.
class _Groups extends ClGroupsMasterNotifier {
  _Groups(this.host, this.hold);

  final _Host host;
  final Completer<void>? hold;

  @override
  Future<Map<int, Group>> build() async => {};

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
    host.sent++;
    await hold?.future;
    return Group(
      id: 7,
      name: name,
      kind: GroupKind.manual,
      createdAtUtc: DateTime.utc(2025),
    );
  }
}

/// What the view told its host, and how many creates were sent.
class _Host {
  final List<String> log = [];
  int sent = 0;
}

/// Presses the system back button.
Future<void> _systemBack(WidgetTester tester) async {
  await tester.binding.handlePopRoute();
  await tester.pumpAndSettle();
}

Finder _input(String id) =>
    find.byWidgetPredicate((w) => w is ShadInputFormField && w.id == id);

/// Pushes the view over a first page, so a system back has a route to pop.
/// The host leaves by popping that route, as the app's router does. With
/// [hold], a create waits for it.
Future<_Host> _push(WidgetTester tester, {Completer<void>? hold}) async {
  tester.view.physicalSize = const Size(1200, 2600);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);
  final host = _Host();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        clGroupsMasterProvider.overrideWith(() => _Groups(host, hold)),
      ],
      child: ShadApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ShadButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (routeContext) => Scaffold(
                    body: GroupCreateView(
                      onCreated: () => host.log.add('created'),
                      onCancel: () {
                        host.log.add('cancelled');
                        Navigator.of(routeContext).pop();
                      },
                    ),
                  ),
                ),
              ),
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    ),
  );
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();
  return host;
}

void main() {
  group('Issue 98: system back on Create group', () {
    testWidgets(
      'Issue 98: Create group: system back after typing asks to discard, '
      'and stays until Discard is chosen',
      (tester) async {
        final host = await _push(tester);
        await tester.enterText(_input(GroupFormFields.nameId), 'Juniors');
        await tester.pump();

        await _systemBack(tester);

        expect(find.byType(ConfirmDialog), findsOneWidget);
        expect(find.text(DiscardChangesPrompt.title), findsOneWidget);
        expect(find.text(DiscardChangesPrompt.message), findsOneWidget);
        expect(find.byType(GroupCreateView), findsOneWidget);
        expect(host.log, isEmpty);

        await tester.tap(find.text(DiscardChangesPrompt.keepEditingLabel));
        await tester.pumpAndSettle();

        expect(find.byType(GroupCreateView), findsOneWidget);
        expect(host.log, isEmpty);

        await _systemBack(tester);
        await tester.tap(find.text(DiscardChangesPrompt.discardLabel));
        await tester.pumpAndSettle();

        expect(host.log, ['cancelled']);
        expect(find.byType(GroupCreateView), findsNothing);
      },
    );

    testWidgets(
      'Issue 98: Create group: system back on an untouched form leaves '
      'at once',
      (tester) async {
        final host = await _push(tester);

        await _systemBack(tester);

        expect(find.byType(ConfirmDialog), findsNothing);
        expect(host.log, ['cancelled']);
        expect(find.byType(GroupCreateView), findsNothing);
      },
    );

    testWidgets(
      'Issue 98: Create group: nothing leaves on system back while the '
      'save is in flight',
      (tester) async {
        final answer = Completer<void>();
        final host = await _push(tester, hold: answer);
        await tester.enterText(_input(GroupFormFields.nameId), 'Juniors');
        await tester.pump();
        await tester.tap(find.text('Create group'));
        await tester.pump();
        expect(host.sent, 1);

        await _systemBack(tester);

        expect(find.byType(ConfirmDialog), findsNothing);
        expect(find.byType(GroupCreateView), findsOneWidget);
        expect(host.log, isEmpty);

        answer.complete();
        await tester.pumpAndSettle();

        expect(host.log, ['created']);
      },
    );
  });
}
