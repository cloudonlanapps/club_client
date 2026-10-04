import 'package:cl_member_zone/src/widgets/panels/shared/broadcast_row.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ThemedMarkdown;

Broadcast _make({
  required String text,
  BroadcastStatus status = BroadcastStatus.sent,
  int recipientCount = 10,
  int? readCount = 3,
  int? unreadCount = 7,
}) {
  return Broadcast(
    id: 1,
    senderUsername: 'admin',
    audienceSelector: const AudienceSelector.allUsers(),
    payload: <String, dynamic>{
      'v': 1,
      'type': 'broadcast.text',
      'data': <String, dynamic>{'text': text},
    },
    sentAtUtc: DateTime.utc(2026, 5, 12, 10, 0, 0),
    status: status,
    recipientCount: recipientCount,
    readCount: readCount,
    unreadCount: unreadCount,
  );
}

Widget _wrap(Widget child) => ShadApp(home: Scaffold(body: child));

void main() {
  testWidgets('renders the broadcast text snippet', (tester) async {
    await tester.pumpWidget(
      _wrap(
        BroadcastRow(broadcast: _make(text: 'Practice cancelled tomorrow.')),
      ),
    );
    expect(find.text('Practice cancelled tomorrow.'), findsOneWidget);
  });

  testWidgets(
    'Issue 740: renders the broadcast text as markdown (no raw ** syntax)',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          BroadcastRow(broadcast: _make(text: 'Say **hello** team')),
        ),
      );
      expect(find.byType(ThemedMarkdown), findsOneWidget);
      expect(find.text('Say **hello** team'), findsNothing);
      expect(find.textContaining('hello'), findsOneWidget);
    },
  );

  testWidgets('shows read / unread / total counts', (tester) async {
    await tester.pumpWidget(
      _wrap(
        BroadcastRow(broadcast: _make(text: 'Hello')),
      ),
    );
    expect(find.textContaining('3 read'), findsOneWidget);
    expect(find.textContaining('7 unread'), findsOneWidget);
    expect(find.textContaining('10 total'), findsOneWidget);
  });

  testWidgets('revoked broadcast surfaces "revoked" in the meta line', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        BroadcastRow(
          broadcast: _make(text: 'Old', status: BroadcastStatus.revoked),
        ),
      ),
    );
    expect(find.textContaining('revoked'), findsOneWidget);
  });

  testWidgets('shows revoke icon for non-revoked rows when onRevoke given', (
    tester,
  ) async {
    var revoked = false;
    await tester.pumpWidget(
      _wrap(
        BroadcastRow(
          broadcast: _make(text: 'hi'),
          onRevoke: () => revoked = true,
        ),
      ),
    );
    final icon = find.byTooltip('Revoke');
    expect(icon, findsOneWidget);
    await tester.tap(icon);
    await tester.pump();
    expect(revoked, isTrue);
  });

  testWidgets('hides revoke icon when onRevoke is null', (tester) async {
    await tester.pumpWidget(
      _wrap(
        BroadcastRow(broadcast: _make(text: 'hi')),
      ),
    );
    expect(find.byTooltip('Revoke'), findsNothing);
  });

  testWidgets('hides revoke icon on already-revoked broadcasts', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        BroadcastRow(
          broadcast: _make(text: 'old', status: BroadcastStatus.revoked),
          onRevoke: () {},
        ),
      ),
    );
    expect(find.byTooltip('Revoke'), findsNothing);
  });

  testWidgets('falls back to data["title"] for legacy broadcast.message rows', (
    tester,
  ) async {
    final b = Broadcast(
      id: 3,
      senderUsername: 'sudo',
      audienceSelector: const AudienceSelector.allUsers(),
      payload: const <String, dynamic>{
        'v': 1,
        'type': 'broadcast.message',
        'data': <String, dynamic>{'title': 'legacy title row'},
      },
      sentAtUtc: DateTime.utc(2026, 5, 12),
      status: BroadcastStatus.sent,
      recipientCount: 1,
    );
    await tester.pumpWidget(_wrap(BroadcastRow(broadcast: b)));
    expect(find.text('legacy title row'), findsOneWidget);
    expect(find.text('(no text)'), findsNothing);
  });

  testWidgets('missing data falls back to "(no text)"', (tester) async {
    final b = Broadcast(
      id: 2,
      senderUsername: 'admin',
      audienceSelector: const AudienceSelector.allUsers(),
      payload: const <String, dynamic>{'v': 1, 'type': 'broadcast.text'},
      sentAtUtc: DateTime.utc(2026, 5, 12),
      status: BroadcastStatus.sent,
      recipientCount: 1,
    );
    await tester.pumpWidget(_wrap(BroadcastRow(broadcast: b)));
    expect(find.text('(no text)'), findsOneWidget);
  });
}
