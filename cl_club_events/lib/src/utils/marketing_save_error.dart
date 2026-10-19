import 'package:club_sdk_2/club_sdk_2.dart' show StaleVersionException;

import '../models/stale_version_message.dart';
import 'event_save_error.dart';

/// The toast for a refused marketing save (club_client#1): a stale version
/// names who changed the marketing, and anything else is told as for any
/// event section ([eventSaveErrorMessage]).
String marketingSaveErrorMessage(
  Object error, {
  required String fallback,
  StackTrace? stackTrace,
}) {
  if (error is StaleVersionException) {
    return staleVersionMessage(error, subject: "This event's marketing");
  }
  return eventSaveErrorMessage(
    error,
    fallback: fallback,
    stackTrace: stackTrace,
  );
}
