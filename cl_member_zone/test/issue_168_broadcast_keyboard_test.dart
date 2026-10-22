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

/// Lists a few sent broadcasts and records every send.
class _Broadcasts extends ClBroadcastsMasterNotifier {
  final List<String> sent = [];

  @override
  Future<Map<int, Broadcast>> build() async => {
    for (var id = 1; id <= 5; id++)
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

/// A phone's screen, in logical pixels.
const Size _phone = Size(390, 844);

/// The height an on-screen keyboard takes on that phone.
const double _keyboard = 300;

/// A message of six lines, enough to grow the message box to its maximum.
const String _longMessage =
    'Line one\nLine two\nLine three\nLine four\n'
    'Line five\nLine six';

Future<_Broadcasts> _pumpOnPhoneWithKeyboard(WidgetTester tester) async {
  tester.view
    ..physicalSize = _phone
    ..devicePixelRatio = 1
    ..viewInsets = const FakeViewPadding(bottom: _keyboard);
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
  testWidgets('Issue 168: with the keyboard up on a phone, a long message '
      'and a custom subject do not overflow, and Send is reachable', (
    tester,
  ) async {
    final broadcasts = await _pumpOnPhoneWithKeyboard(tester);

    await tester.tap(find.text('Send email'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Customize email subject'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(EditableText).first, 'Ice time');
    await tester.enterText(find.byType(EditableText).last, _longMessage);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);

    // The screen scrolls to the checkbox and to Send.
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
  });
}
