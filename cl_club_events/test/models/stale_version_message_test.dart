import 'package:cl_club_events/src/models/stale_version_message.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show DateFormat;

void main() {
  group('Issue 69: staleVersionMessage', () {
    test(
      'Issue 69: says who changed it and when, and that it was reloaded',
      () {
        final changedAt = DateTime.utc(2026, 9, 1, 10, 30);
        final message = staleVersionMessage(
          StaleVersionException(
            message: 'raw server text',
            version: 4,
            updatedAtUtc: changedAt,
            updatedBy: 'coach_a',
          ),
          subject: 'This session',
        );

        expect(message, startsWith('This session was changed by coach_a'));
        expect(
          message,
          contains(DateFormat('d MMM y, h:mm a').format(changedAt.toLocal())),
        );
        expect(message, contains('reloaded'));
        expect(message, isNot(contains('raw server text')));
      },
    );

    test('Issue 69: falls back when the writer and time are unknown', () {
      final message = staleVersionMessage(
        const StaleVersionException(message: 'raw', version: 2),
        subject: 'This camp',
      );

      expect(
        message,
        'This camp was changed by someone else since you opened it. '
        'It has been reloaded; check it and try again.',
      );
    });
  });
}
