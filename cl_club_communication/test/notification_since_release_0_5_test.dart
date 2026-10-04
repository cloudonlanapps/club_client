import 'package:cl_club_communication/src/utils/notification_registry.dart';
import 'package:cl_club_communication/src/widgets/notification_row.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

AppNotification _make(String type, Map<String, dynamic> data) =>
    AppNotification(
      id: 11,
      username: 'notif_member',
      type: type,
      channel: NotificationChannel.inApp,
      payload: <String, dynamic>{'v': 1, 'type': type, 'data': data},
      isRead: false,
      createdAtUtc: DateTime.utc(2026, 9, 29),
    );

NotificationDeepLink? _link(AppNotification n) =>
    resolveDeepLink(n, currentUsername: 'notif_member');

void main() {
  // Local noon, so the dd-mm-yyyy the row shows is the same in every zone.
  final cutoff = DateTime(2026, 10, 3, 12).millisecondsSinceEpoch;
  final previous = DateTime(2026, 9, 30, 12).millisecondsSinceEpoch;

  test('Issue 32: every type the SDK knows has a registry row', () {
    final missing = NotificationType.all
        .where((t) => !kNotificationKindByType.containsKey(t))
        .toList();
    expect(missing, isEmpty);
  });

  group('Issue 32: event.terminated', () {
    Map<String, dynamic> data({String? reason}) => {
      'eventId': 9,
      'eventTitle': 'Skating',
      'eventType': 'programme',
      'reason': reason,
      'cutoffTimeUtc': cutoff,
    };

    test('Issue 32: the programme, its last day and the reason', () {
      final d = formatNotification(
        _make(NotificationType.eventTerminated, data(reason: 'rink closed')),
      );
      expect(d.title, 'Skating');
      expect(d.body, 'Skating ends on 03-10-2026: rink closed.');
      expect(d.icon, LucideIcons.calendarOff);
      expect(
        notificationTypeLabel(NotificationType.eventTerminated),
        'Programme terminated',
      );
    });

    test('Issue 32: without a reason', () {
      final d = formatNotification(
        _make(NotificationType.eventTerminated, data()),
      );
      expect(d.body, 'Skating ends on 03-10-2026.');
    });

    test('Issue 32: opens the member event', () {
      final link = _link(_make(NotificationType.eventTerminated, data()));
      expect(link, isA<NotifMyEventLink>());
      final myEvent = link! as NotifMyEventLink;
      expect(myEvent.eventId, 9);
      expect(myEvent.username, 'notif_member');
      expect(myEvent.sourceNotificationId, 11);
    });
  });

  group('Issue 32: event.extended', () {
    Map<String, dynamic> data({int? to}) => {
      'eventId': 9,
      'eventTitle': 'Skating',
      'eventType': 'programme',
      'reason': null,
      'previousCutoffUtc': previous,
      'cutoffTimeUtc': to,
    };

    test('Issue 32: the programme and its new last day', () {
      final d = formatNotification(
        _make(NotificationType.eventExtended, data(to: cutoff)),
      );
      expect(d.title, 'Skating');
      expect(d.body, 'Skating now ends on 03-10-2026.');
      expect(d.icon, LucideIcons.calendarPlus);
      expect(
        notificationTypeLabel(NotificationType.eventExtended),
        'Programme extended',
      );
    });

    test('Issue 32: a cleared cutoff means no end date', () {
      final d = formatNotification(
        _make(NotificationType.eventExtended, data()),
      );
      expect(d.body, 'Skating no longer has an end date.');
    });

    test('Issue 32: opens the member event', () {
      final link = _link(_make(NotificationType.eventExtended, data()));
      expect(link, isA<NotifMyEventLink>());
      expect((link! as NotifMyEventLink).eventId, 9);
    });
  });

  group('Issue 32: evaluations', () {
    test('Issue 174: evaluation.published names the coach', () {
      final n = _make(NotificationType.evaluationPublished, {
        'evaluationId': 5,
        'owner': 'coach_a',
        'eventId': 9,
      });
      final d = formatNotification(n);
      expect(d.title, 'Review published');
      expect(d.body, 'A new review from @coach_a is ready to read.');
      expect(d.icon, LucideIcons.fileCheck);
      expect(
        notificationTypeLabel(NotificationType.evaluationPublished),
        'Review',
      );
    });

    test('Issue 174: evaluation.published without an owner', () {
      final d = formatNotification(
        _make(NotificationType.evaluationPublished, {'evaluationId': 5}),
      );
      expect(d.body, 'A new review is ready to read.');
    });

    test('Issue 174: evaluation.withdrawn', () {
      final d = formatNotification(
        _make(NotificationType.evaluationWithdrawn, {'evaluationId': 5}),
      );
      expect(d.title, 'Review withdrawn');
      expect(d.body, 'A review of you was withdrawn.');
      expect(d.icon, LucideIcons.fileMinus);
    });

    test(
      'Issue 174: evaluation.transferred names the member and the coach',
      () {
        final d = formatNotification(
          _make(NotificationType.evaluationTransferred, {
            'evaluationId': 5,
            'createdFor': 'member_b',
            'fromOwner': 'coach_a',
          }),
        );
        expect(d.title, 'Evaluation transferred');
        expect(
          d.body,
          'The evaluation of @member_b was handed to you by @coach_a.',
        );
        expect(d.icon, LucideIcons.arrowRightLeft);
      },
    );

    test('Issue 174: evaluation.published opens the review', () {
      final link = _link(
        _make(NotificationType.evaluationPublished, {
          'evaluationId': 5,
          'owner': 'coach_a',
        }),
      );
      expect(link, isA<NotifMyReviewLink>());
      expect((link! as NotifMyReviewLink).evaluationId, 5);
      expect(link.sourceNotificationId, 11);
    });

    test("Issue 174: evaluation.withdrawn opens the member's reviews", () {
      final link = _link(
        _make(NotificationType.evaluationWithdrawn, {'evaluationId': 5}),
      );
      expect(link, isA<NotifMyReviewsLink>());
    });

    test("Issue 174: evaluation.transferred opens the coach's editor", () {
      final link = _link(
        _make(NotificationType.evaluationTransferred, {
          'evaluationId': 5,
          'createdFor': 'member_b',
          'fromOwner': 'coach_a',
        }),
      );
      expect(link, isA<NotifEvaluationLink>());
      expect((link! as NotifEvaluationLink).evaluationId, 5);
    });

    test('Issue 174: a payload without an id does not navigate', () {
      for (final type in [
        NotificationType.evaluationPublished,
        NotificationType.evaluationTransferred,
      ]) {
        expect(_link(_make(type, const {})), isNull, reason: type);
      }
    });
  });

  group('Issue 32: inquiry.received', () {
    AppNotification make(String kind) =>
        _make(NotificationType.inquiryReceived, {
          'inquiryId': 3,
          'kind': kind,
          'name': 'Asha Rao',
        });

    test('Issue 32: a contact message', () {
      final d = formatNotification(make(InquiryKind.contact.wireName));
      expect(d.title, 'New inquiry');
      expect(d.body, 'Asha Rao sent a message.');
      expect(d.icon, LucideIcons.inbox);
      expect(
        notificationTypeLabel(NotificationType.inquiryReceived),
        'Inquiry',
      );
    });

    test('Issue 32: an expression of interest', () {
      final d = formatNotification(make(InquiryKind.interest.wireName));
      expect(d.body, 'Asha Rao registered interest.');
    });

    test('Issue 32: the public name is escaped, not rendered as markdown', () {
      final d = formatNotification(
        _make(NotificationType.inquiryReceived, {
          'inquiryId': 3,
          'kind': InquiryKind.contact.wireName,
          'name': '![x](http://e.x/p.png) a_b',
        }),
      );
      expect(d.body, r'\!\[x\]\(http\:\/\/e\.x\/p\.png\) a\_b sent a message.');
    });

    testWidgets('Issue 32: the row shows the name as typed', (tester) async {
      const name = '![x](http://e.x/p.png) a_b';
      await tester.pumpWidget(
        ShadApp(
          home: Scaffold(
            body: NotificationRow(
              notification: _make(NotificationType.inquiryReceived, {
                'inquiryId': 3,
                'kind': InquiryKind.contact.wireName,
                'name': name,
              }),
            ),
          ),
        ),
      );
      expect(find.text('$name sent a message.'), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    test('Issue 32: opens the inquiries inbox', () {
      final link = _link(make(InquiryKind.contact.wireName));
      expect(link, isA<NotifInquiriesLink>());
      expect(link!.sourceNotificationId, 11);
    });
  });

  group('Issue 32: a type the client does not know', () {
    final n = _make('club.future_thing', {'x': 1});

    test('Issue 32: renders the generic line', () {
      final d = formatNotification(n);
      expect(d.title, 'Notification');
      expect(d.body, contains('club.future_thing'));
      expect(d.icon, LucideIcons.bell);
      expect(notificationTypeLabel(n.type), 'Club future thing');
    });

    test('Issue 32: does not navigate', () {
      expect(_link(n), isNull);
    });
  });
}
