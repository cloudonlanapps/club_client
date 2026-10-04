import 'dart:async';
import 'dart:io' show SocketException;

import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

ServerException _status(int code) =>
    ServerException(statusCode: code, code: 'X', message: 'raw text');

void main() {
  group('Issue 138: which failed writes may have landed', () {
    test('Issue 138: a 5xx, a timeout or a dropped connection may have', () {
      expect(writeMayHaveLanded(_status(500)), isTrue);
      expect(writeMayHaveLanded(_status(503)), isTrue);
      expect(writeMayHaveLanded(TimeoutException('slow')), isTrue);
      expect(writeMayHaveLanded(const SocketException('reset')), isTrue);
      expect(writeMayHaveLanded(StateError('unexpected')), isTrue);
    });

    test('Issue 138: a 4xx refusal or a client-side error has not', () {
      expect(writeMayHaveLanded(_status(400)), isFalse);
      expect(writeMayHaveLanded(_status(409)), isFalse);
      expect(writeMayHaveLanded(_status(422)), isFalse);
      expect(
        writeMayHaveLanded(const SdkError('bad', code: 'VALIDATION_ERROR')),
        isFalse,
      );
    });

    test('Issue 138: the message says the change is unconfirmed, or falls '
        'back to fixed text, never the raw error', () {
      expect(
        writeFailureMessage(TimeoutException('slow'), fallback: 'Nope.'),
        uncertainWriteMessage,
      );
      expect(writeFailureMessage(_status(422), fallback: 'Nope.'), 'Nope.');
      expect(
        writeFailureMessage(_status(500), fallback: 'Nope.'),
        isNot(contains('raw text')),
      );
    });
  });
}
