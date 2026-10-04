import 'package:cl_club_communication/src/widgets/notification_row.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ThemedMarkdown;

AppNotification _broadcast({required bool isRead, String text = 'Hello'}) {
  return AppNotification(
    id: 1,
    username: 'u',
    type: 'broadcast.message',
    channel: NotificationChannel.inApp,
    payload: <String, dynamic>{
      'v': 1,
      'type': 'broadcast.message',
      'data': <String, dynamic>{'text': text},
    },
    isRead: isRead,
    createdAtUtc: DateTime.now().toUtc(),
  );
}

Widget _wrap(Widget child) => ShadApp(home: Scaffold(body: child));

Text _textWidget(WidgetTester tester, String data) =>
    tester.widget<Text>(find.text(data));

/// The markdown body is rendered via [ThemedMarkdown], so the unread-bold
/// weight lives on its base `textStyle`, not on a plain `Text`.
ThemedMarkdown _bodyMarkdown(WidgetTester tester) =>
    tester.widget<ThemedMarkdown>(find.byType(ThemedMarkdown));

void main() {
  testWidgets('renders message body as primary line and ~type as subtitle', (
    tester,
  ) async {
    await tester.pumpWidget(
      _wrap(
        NotificationRow(
          notification: _broadcast(
            isRead: false,
            text: 'You are invited to Party',
          ),
        ),
      ),
    );

    expect(find.text('You are invited to Party'), findsOneWidget);
    expect(find.text('~Announcement'), findsOneWidget);
  });

  testWidgets('subtitle uses muted text style', (tester) async {
    await tester.pumpWidget(
      _wrap(
        NotificationRow(
          notification: _broadcast(isRead: false, text: 'Hi there'),
        ),
      ),
    );

    // Find the BuildContext under ShadApp so we can read ShadTheme.
    final BuildContext ctx = tester.element(find.byType(NotificationRow));
    final mutedColor = ShadTheme.of(ctx).textTheme.muted.color;

    final subtitle = _textWidget(tester, '~Announcement');
    expect(subtitle.style?.color, mutedColor);
  });

  testWidgets(
    'Issue 740: unread body is not force-bolded so markdown emphasis is '
    'preserved',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          NotificationRow(
            notification: _broadcast(
              isRead: false,
              text: 'You are invited to Party',
            ),
          ),
        ),
      );

      // The body base style must not hard-set w700 — that would flatten the
      // body's own `**bold**` into "everything bold".
      expect(
        _bodyMarkdown(tester).textStyle?.fontWeight,
        isNot(FontWeight.w700),
      );
    },
  );

  testWidgets(
    'Issue 740: a body that fits shows no Show more toggle (overflow is '
    'measured, not guessed from length)',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _wrap(
          NotificationRow(
            notification: _broadcast(isRead: false, text: 'A short note.'),
          ),
        ),
      );
      // Settle the post-layout overflow measurement: a fitting body must still
      // show no toggle afterwards (regression for a spurious "Show more").
      await tester.pumpAndSettle();
      expect(find.text('A short note.'), findsOneWidget);
      expect(find.text('Show more'), findsNothing);
      expect(find.text('Show less'), findsNothing);
    },
  );

  testWidgets(
    'Issue 740: a long body collapses behind a Show more toggle that '
    'expands and flips to Show less',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        _wrap(
          NotificationRow(
            notification: _broadcast(
              isRead: false,
              text: 'a very long message ' * 30,
            ),
          ),
        ),
      );
      // Overflow is measured after layout (post-frame), so let it settle.
      await tester.pumpAndSettle();

      expect(find.text('Show more'), findsOneWidget);
      expect(find.text('Show less'), findsNothing);

      await tester.tap(find.text('Show more'));
      await tester.pumpAndSettle();

      expect(find.text('Show less'), findsOneWidget);
      expect(find.text('Show more'), findsNothing);
    },
  );

  testWidgets(
    'Issue 740: markdown body renders styled (no raw ** asterisks)',
    (tester) async {
      await tester.pumpWidget(
        _wrap(
          NotificationRow(
            notification: _broadcast(isRead: false, text: 'Say **hello** now'),
          ),
        ),
      );
      // Rendered as markdown, so the bold word appears without its syntax.
      expect(find.byType(ThemedMarkdown), findsOneWidget);
      expect(find.text('Say **hello** now'), findsNothing);
      expect(find.textContaining('hello'), findsOneWidget);
    },
  );

  testWidgets(
    'Issue 381: kind with typeLabel: null suppresses the ~Label subtitle '
    'entirely',
    (tester) async {
      final n = AppNotification(
        id: 9,
        username: 'admin',
        type: 'user.registration_pending',
        channel: NotificationChannel.inApp,
        payload: const <String, dynamic>{
          'v': 1,
          'type': 'user.registration_pending',
          'data': <String, dynamic>{
            'username': 'asha',
            'firstName': 'Asha',
            'lastName': 'Rao',
          },
        },
        isRead: false,
        createdAtUtc: DateTime.now().toUtc(),
      );

      await tester.pumpWidget(_wrap(NotificationRow(notification: n)));

      expect(
        find.text('Asha Rao (@asha) registered and is awaiting approval.'),
        findsOneWidget,
      );
      expect(find.textContaining('~'), findsNothing);
    },
  );

  testWidgets('tap still invokes the supplied onTap callback', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _wrap(
        NotificationRow(
          notification: _broadcast(isRead: false),
          onTap: () => taps++,
        ),
      ),
    );
    await tester.tap(find.byType(NotificationRow));
    await tester.pump();
    expect(taps, 1);
  });

  testWidgets('subtitle uses the type label for non-broadcast types', (
    tester,
  ) async {
    final n = AppNotification(
      id: 2,
      username: 'u',
      type: 'group.join_request',
      channel: NotificationChannel.inApp,
      payload: const <String, dynamic>{
        'v': 1,
        'type': 'group.join_request',
        'data': <String, dynamic>{
          'groupId': 1,
          'groupName': 'U-14 Boys',
          'requesterUsername': 'asha',
        },
      },
      isRead: false,
      createdAtUtc: DateTime.now().toUtc(),
    );

    await tester.pumpWidget(_wrap(NotificationRow(notification: n)));

    expect(find.text('asha asked to join U-14 Boys.'), findsOneWidget);
    expect(find.text('~Group join request'), findsOneWidget);
  });

  testWidgets('subtitle for event.cancelled is the type label', (tester) async {
    final n = AppNotification(
      id: 3,
      username: 'u',
      type: 'event.cancelled',
      channel: NotificationChannel.inApp,
      payload: const <String, dynamic>{
        'v': 1,
        'type': 'event.cancelled',
        'data': <String, dynamic>{'eventTitle': 'Friday Practice'},
      },
      isRead: false,
      createdAtUtc: DateTime.now().toUtc(),
    );

    await tester.pumpWidget(_wrap(NotificationRow(notification: n)));

    expect(find.text('Friday Practice was cancelled.'), findsOneWidget);
    expect(find.text('~Event cancelled'), findsOneWidget);
  });
}
