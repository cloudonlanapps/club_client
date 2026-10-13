import 'package:club_sdk_2/club_sdk_2.dart';

/// HTTP status of a file that does not exist or the caller may not read.
const int kMediaNotFoundStatus = 404;

/// The media record with [mediaUuid], or null when no file has that uuid or
/// the caller may not read it (the server answers both 404).
///
/// A media link carries the uuid; the calls that change a file take the id
/// this record holds. The record is read by its uuid, whoever uploaded the
/// file and however many files the caller has (club_client#86,
/// club_client#105).
Future<Media?> findMediaByUuid(SecureClient client, String mediaUuid) async {
  try {
    return await client.media.getByUuid(mediaUuid);
  } on ServerException catch (e) {
    if (e.statusCode == kMediaNotFoundStatus) return null;
    rethrow;
  }
}

/// Soft-delete the file with [mediaUuid], once its link is gone: the server
/// refuses to delete a file that is still linked (409 `MEDIA_IN_USE`).
///
/// A file [findMediaByUuid] does not resolve is left as it is. A delete the
/// server refuses throws; the callers log it and carry on, since the link
/// they removed is what the user asked for.
Future<void> softDeleteMediaByUuid(
  SecureClient client,
  String mediaUuid,
) async {
  final media = await findMediaByUuid(client, mediaUuid);
  if (media == null) return;
  await client.media.softDelete(media.id);
}
