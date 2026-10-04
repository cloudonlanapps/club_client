import 'package:cl_club_communication/src/utils/notification_deep_link.dart';
import 'package:cl_club_communication/src/utils/notification_formatter.dart';
import 'package:cl_club_communication/src/utils/notification_registry.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

AppNotification _make({
  required String type,
  Map<String, dynamic>? data,
}) {
  return AppNotification(
    id: 1,
    username: 'someone',
    type: type,
    channel: NotificationChannel.inApp,
    payload: <String, dynamic>{
      'v': 1,
      'type': type,
      'data': data ?? const <String, dynamic>{},
    },
    isRead: false,
    createdAtUtc: DateTime.utc(2026, 5, 12, 10, 0, 0),
  );
}

void main() {
  group('NotificationKind registry invariants', () {
    test('every kind has a non-empty type; typeLabel is non-empty or null', () {
      for (final k in kNotificationKinds) {
        expect(k.type, isNotEmpty, reason: 'empty type in registry');
        // typeLabel is optional (#381): null means the row's body is
        // already self-describing and the row should omit the subtitle.
        // What is *not* allowed is an empty/whitespace string — that
        // would render as a stray "~" in the row.
        if (k.typeLabel != null) {
          expect(
            k.typeLabel!.trim(),
            isNotEmpty,
            reason: 'blank typeLabel for ${k.type}',
          );
        }
      }
    });

    test(
      'Issue 381: user.registration_pending has typeLabel: null '
      '(subtitle suppressed)',
      () {
        final k = kNotificationKindByType['user.registration_pending'];
        expect(k, isNotNull);
        expect(k!.typeLabel, isNull);
      },
    );

    test('no duplicate types in registry', () {
      final seen = <String>{};
      for (final k in kNotificationKinds) {
        expect(
          seen.add(k.type),
          isTrue,
          reason: 'duplicate registry entry for ${k.type}',
        );
      }
    });

    test('kNotificationKindByType matches kNotificationKinds', () {
      expect(kNotificationKindByType.length, kNotificationKinds.length);
      for (final k in kNotificationKinds) {
        expect(
          identical(kNotificationKindByType[k.type], k),
          isTrue,
          reason: 'lookup mismatch for ${k.type}',
        );
      }
    });

    test('derived kNotificationFormatters covers every registry row', () {
      for (final k in kNotificationKinds) {
        expect(
          kNotificationFormatters.containsKey(k.type),
          isTrue,
          reason: 'formatter missing for ${k.type}',
        );
      }
      expect(kNotificationFormatters.length, kNotificationKinds.length);
    });

    test('derived kNotificationLinks covers every row with a deepLink', () {
      for (final k in kNotificationKinds) {
        if (k.deepLink == null) {
          expect(
            kNotificationLinks.containsKey(k.type),
            isFalse,
            reason: 'unexpected deepLink for ${k.type}',
          );
        } else {
          expect(
            kNotificationLinks.containsKey(k.type),
            isTrue,
            reason: 'deepLink missing for ${k.type}',
          );
        }
      }
    });

    test('kKnownUnimplementedTypes stays empty (all rows have copy)', () {
      expect(kKnownUnimplementedTypes, isEmpty);
    });
  });

  group('typeLabel lookup', () {
    test('returns the registered label for a known type', () {
      expect(notificationTypeLabel('group.join_request'), 'Group join request');
      expect(notificationTypeLabel('venue.renamed'), 'Venue renamed');
      expect(
        notificationTypeLabel('account.password_changed_by_admin'),
        'Password reset by admin',
      );
    });

    test('falls back to title-cased dotted string for unknown types', () {
      expect(
        notificationTypeLabel('something.totally_new'),
        'Something totally new',
      );
    });

    test('returns "Notification" for an empty type', () {
      expect(notificationTypeLabel(''), 'Notification');
    });

    test(
      'Issue 381: returns empty string for a kind with typeLabel: null '
      '(NotificationRow uses this to suppress the subtitle)',
      () {
        expect(notificationTypeLabel('user.registration_pending'), '');
      },
    );
  });

  group('formatNotification fallback for unknown types', () {
    test('renders the generic line with the raw type', () {
      final display = formatNotification(
        _make(type: 'unknown.new_thing', data: {}),
      );
      expect(display.title, 'Notification');
      expect(display.body, contains('unknown.new_thing'));
    });
  });

  group('resolveDeepLink for rows with no deepLink', () {
    test('broadcast.* returns null', () {
      final link = resolveDeepLink(
        _make(type: 'broadcast.message', data: {'text': 'hi'}),
        currentUsername: 'alice',
      );
      expect(link, isNull);
    });
  });
}
