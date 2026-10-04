import 'dart:async';

import 'package:cl_club_events/src/utils/event_save_error.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' show ClientException;

const _fallback = 'Could not update. Please try again.';

void main() {
  group('Issue 110: an event save names why it was refused', () {
    test('Issue 110: a stale version says who changed the event', () {
      final message = eventSaveErrorMessage(
        StaleVersionException(
          message: 'stale',
          version: 4,
          updatedAtUtc: DateTime.utc(2026, 9, 26, 10),
          updatedBy: 'another_admin',
        ),
        fallback: _fallback,
      );
      expect(message, contains('another_admin'));
    });

    test('Issue 110: a clash says so', () {
      final message = eventSaveErrorMessage(
        const ServerException(
          statusCode: 409,
          code: SdkErrorCode.conflict,
          message: 'organizer booked',
        ),
        fallback: _fallback,
      );
      expect(message, contains('clashes'));
    });

    test('Issue 110: anything else falls back, never the raw error', () {
      final message = eventSaveErrorMessage(
        Exception('socket closed'),
        fallback: _fallback,
      );
      expect(message, _fallback);
    });
    test('Issue 110: a missing organizer or coach says so', () {
      final message = eventSaveErrorMessage(
        const ServerException(
          statusCode: 404,
          code: SdkErrorCode.userNotFound,
          message: 'Coach not found: coach_x',
        ),
        fallback: _fallback,
      );
      expect(message, contains('no longer has an account'));
    });

    test('Issue 110: a deleted event says so', () {
      final message = eventSaveErrorMessage(
        const ServerException(
          statusCode: 404,
          code: SdkErrorCode.eventNotFound,
          message: 'Event not found',
        ),
        fallback: _fallback,
      );
      expect(message, contains('no longer exists'));
    });

    test('Issue 110: a request that timed out says the server was not '
        'reached', () {
      final message = eventSaveErrorMessage(
        TimeoutException('PATCH timed out'),
        fallback: _fallback,
      );
      expect(message, contains('reach the server'));
    });

    test('Issue 110: a connection the server had closed says the server '
        'was not reached', () {
      // The shape seen on app_test_server2.conf: a request written onto a
      // keep-alive connection uvicorn had already closed.
      final message = eventSaveErrorMessage(
        ClientException(
          'SocketException: Write failed (OS Error: Broken pipe, errno = 32)',
        ),
        fallback: _fallback,
      );
      expect(message, contains('reach the server'));
    });

    test('Issue 110: the cause is logged with its stack trace', () {
      final logged = <String>[];
      final original = debugPrint;
      debugPrint = (message, {wrapWidth}) => logged.add(message ?? '');
      addTearDown(() => debugPrint = original);

      eventSaveErrorMessage(
        Exception('socket closed'),
        stackTrace: StackTrace.fromString('#0 EditableEventBody._save'),
        fallback: _fallback,
      );

      final log = logged.join('\n');
      expect(log, contains('[event save]'));
      expect(log, contains('socket closed'));
      expect(log, contains('#0 EditableEventBody._save'));
    });
  });
}
