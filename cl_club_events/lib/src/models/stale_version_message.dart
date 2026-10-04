import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show DateFormat;

/// The message for a change the server refused as stale (409
/// `STALE_VERSION`): someone else changed [subject] after the admin loaded
/// it. Names who changed it and when, when the server says, and tells the
/// admin it has been reloaded — the camp master reloads it before rethrowing.
///
/// [subject] opens the sentence, e.g. `'This session'` or `'This camp'`.
String staleVersionMessage(
  StaleVersionException e, {
  required String subject,
}) {
  final who = e.updatedBy ?? 'someone else';
  final changedAt = e.updatedAtUtc;
  final when = changedAt == null
      ? ''
      : ' on ${DateFormat('d MMM y, h:mm a').format(changedAt.toLocal())}';
  return '$subject was changed by $who$when since you opened it. '
      'It has been reloaded; check it and try again.';
}
