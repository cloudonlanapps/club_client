import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_member_zone/cl_member_zone.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

final UserPrivate _admin = UserPrivate(
  username: 'admin1',
  displayName: 'Admin One',
  status: UserStatus.active,
  isSuperAdmin: false,
  roles: const UserRoles(isAdmin: true),
  createdAtUtc: DateTime.utc(2024),
);

class _StubAuth extends AuthNotifier {
  _StubAuth(this._u);
  final UserPrivate _u;
  @override
  Future<UserPrivate?> build() async => _u;
}

/// The number of sent broadcasts listed: more than a screen holds.
const int _sentCount = 30;

/// Lists [_sentCount] sent broadcasts and records every send.
class _Broadcasts extends ClBroadcastsMasterNotifier {
  final List<String> sent = [];

  @override
  Future<Map<int, Broadcast>> build() async => {
    for (var id = 1; id <= _sentCount; id++)
      id: Broadcast(
        id: id,
        audienceSelector: const AudienceSelector.allUsers(),
        payload: {
          'v': 1,
          'type': 'broadcast.text',
          'data': {'text': 'message $id'},
        },
        sentAtUtc: DateTime.utc(2026, 1, 1, 0, id),
        status: BroadcastStatus.sent,
        recipientCount: 1,
      ),
  };

  @override
  Future<Broadcast> send({
    required BroadcastScope scope,
    required AudienceSelector audience,
    required String text,
    bool email = false,
    String? emailSubject,
  }) async {
    sent.add(text);
    return state.requireValue.values.first;
  }
}

/// A desktop browser's window, in logical pixels.
const Size _wide = Size(1280, 900);

/// A phone's screen, in logical pixels.
const Size _phone = Size(390, 844);

/// The height an on-screen keyboard takes on that phone.
const double _keyboard = 300;

/// A message of six lines, enough to grow the message box to its maximum.
const String _longMessage =
    'Line one\nLine two\nLine three\nLine four\n'
    'Line five\nLine six';

Future<_Broadcasts> _pump(WidgetTester tester, {required Size size}) async {
  tester.view
    ..physicalSize = size
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final broadcasts = _Broadcasts();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authStateProvider.overrideWith(() => _StubAuth(_admin)),
        clBroadcastsMasterProvider.overrideWith(() => broadcasts),
        clBroadcastStaffProvider.overrideWith((ref, scope) async => ['c1']),
        clBroadcastMembersProvider.overrideWith((ref, scope) async => []),
      ],
      child: ShadApp(
        home: Scaffold(
          body: BroadcastScreen(
            scope: const BroadcastScope.all(),
            onClose: () {},
            onHome: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return broadcasts;
}

void main() {
  testWidgets('Issue 269: on a wide screen with no keyboard, scrolling the '
      'sent list leaves the composer where it is', (tester) async {
    await _pump(tester, size: _wide);

    final staffOnly = find.byKey(const ValueKey('broadcast-staff-only'));
    final send = find.widgetWithText(ShadButton, 'Send');
    final staffTop = tester.getTopLeft(staffOnly).dy;
    final sendTop = tester.getTopLeft(send).dy;
    final firstRow = find.text('message $_sentCount');
    final firstRowTop = tester.getTopLeft(firstRow).dy;

    await tester.drag(firstRow, const Offset(0, -400));
    await tester.pumpAndSettle();

    // The list moved under the composer ...
    expect(
      firstRow.evaluate().isEmpty ||
          tester.getTopLeft(firstRow).dy < firstRowTop,
      isTrue,
    );
    // ... and the composer did not.
    expect(staffOnly.hitTestable(), findsOneWidget);
    expect(tester.getTopLeft(staffOnly).dy, staffTop);
    expect(tester.getTopLeft(send).dy, sendTop);
    expect(send.hitTestable(), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Issue 269: on a phone with the keyboard up, the sent list is '
      'hidden, nothing overflows, and the checkbox and Send are reached by '
      'scrolling', (tester) async {
    final broadcasts = await _pump(tester, size: _phone);

    // With the keyboard closed the phone shows the sent list.
    expect(find.text('message $_sentCount'), findsOneWidget);

    await tester.tap(find.text('Send email'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Customize email subject'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, 'Ice time');
    await tester.enterText(find.byType(EditableText).last, _longMessage);
    await tester.pumpAndSettle();

    // The keyboard comes up while the message has the focus.
    tester.view.viewInsets = const FakeViewPadding(bottom: _keyboard);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    // Scrolled to its end, the page shows no sent broadcast.
    final page = tester.state<ScrollableState>(find.byType(Scrollable).first);
    page.position.jumpTo(page.position.maxScrollExtent);
    await tester.pumpAndSettle();
    expect(find.textContaining(RegExp(r'^message \d+$')), findsNothing);
    final message = tester.widget<EditableText>(
      find.byType(EditableText).last,
    );
    expect(message.controller.text, _longMessage);
    expect(message.focusNode.hasFocus, isTrue);

    final customize = find.text('Customize email subject');
    await tester.ensureVisible(customize);
    await tester.pumpAndSettle();
    expect(customize.hitTestable(), findsOneWidget);

    final send = find.widgetWithText(ShadButton, 'Send');
    await tester.ensureVisible(send);
    await tester.pumpAndSettle();
    expect(send.hitTestable(), findsOneWidget);
    await tester.tap(send);
    await tester.pumpAndSettle();

    expect(broadcasts.sent, [_longMessage]);
    expect(tester.takeException(), isNull);
  });
}
