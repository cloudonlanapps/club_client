import 'dart:async' show TimeoutException;

import 'package:club_sdk_2/club_sdk_2.dart'
    show SdkErrorCode, ServerException, StaleVersionException;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:http/http.dart' show ClientException;

import '../models/stale_version_message.dart';

/// The toast for a refused event section save (club_core#110): a stale
/// version names who changed the event, a clash, a missing organizer or
/// coach, a deleted event and an unreachable server each say so, anything
/// else falls back to [fallback]. The raw error never reaches the toast, but
/// it is logged with [stackTrace], so a failure names its cause.
String eventSaveErrorMessage(
  Object error, {
  required String fallback,
  StackTrace? stackTrace,
}) {
  debugPrint('[event save] $error${stackTrace == null ? '' : '\n$stackTrace'}');
  if (error is StaleVersionException) {
    return staleVersionMessage(error, subject: 'This event');
  }
  // A timeout, or a connection that failed before any response (e.g. one the
  // server had already closed): the server never answered.
  if (error is TimeoutException || error is ClientException) {
    return 'Could not reach the server. Check the connection and try again.';
  }
  if (error is ServerException) {
    return switch (error.code) {
      SdkErrorCode.conflict || SdkErrorCode.timeConflict =>
        'That clashes with another booking of the organizer, a coach or '
            'the venue.',
      SdkErrorCode.insufficientPermission =>
        'You do not have permission to do this.',
      SdkErrorCode.userNotFound =>
        'The organizer or a coach no longer has an account. Pick again.',
      SdkErrorCode.eventNotFound => 'This event no longer exists.',
      _ => fallback,
    };
  }
  return fallback;
}
