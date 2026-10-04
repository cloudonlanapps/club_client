import 'package:club_sdk_2/club_sdk_2.dart' show MediaRef, ServerException;

/// The server's code for a `site_media` slot that names media an anonymous
/// visitor could not fetch.
const String siteMediaNotPublicCode = 'SITE_MEDIA_NOT_PUBLIC';

/// Which slot of [draft] the server refused in [error], when it refused one
/// for not being public; `null` otherwise.
///
/// The refusal carries no structured details, only a message naming the slot
/// and the uuid (`site_media slot '<slot>' names <uuid>, …`), so the slot is
/// found by its quoted key first and by its uuid second.
String? refusedSiteMediaSlot(
  ServerException error,
  Map<String, MediaRef> draft,
) {
  if (error.code != siteMediaNotPublicCode) return null;
  final message = error.message;
  for (final key in draft.keys) {
    if (message.contains("'$key'")) return key;
  }
  for (final entry in draft.entries) {
    if (message.contains(entry.value.uuid)) return entry.key;
  }
  return null;
}
