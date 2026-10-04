import 'dart:async';

import 'package:cl_club_events/src/models/event_write_messages.dart';
import 'package:cl_club_events/src/utils/event_write_error_message.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show uncertainWriteMessage;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Issue 138: event write failures show fixed text', () {
    test('Issue 138: a timeout says the change is unconfirmed', () {
      expect(
        eventWriteErrorMessage(TimeoutException('slow')),
        uncertainWriteMessage,
      );
    });

    test('Issue 138: a 500 says the change is unconfirmed', () {
      expect(
        eventWriteErrorMessage(
          const ServerException(
            statusCode: 500,
            code: 'INTERNAL_ERROR',
            message: 'raw server text',
          ),
        ),
        uncertainWriteMessage,
      );
    });

    test('Issue 138: the eligibility pre-check keeps its reason', () {
      expect(
        eventWriteErrorMessage(
          const SdkError(
            'Outside the age window for this event.',
            code: SdkErrorCode.userNotEligibleForEvent,
          ),
        ),
        'Outside the age window for this event.',
      );
    });

    test('Issue 138: a 4xx falls back to fixed text, never the raw error', () {
      final message = eventWriteErrorMessage(
        const ServerException(
          statusCode: 422,
          code: 'SOMETHING_NEW',
          message: 'raw server text',
        ),
        fallback: leaveDecisionFailedMessage,
      );
      expect(message, leaveDecisionFailedMessage);
    });
  });
}
