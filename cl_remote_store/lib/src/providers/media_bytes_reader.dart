import 'dart:typed_data';

import 'package:cl_remote_store/src/models/media_bytes_reader.dart';
import 'package:cl_remote_store/src/providers/client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Reads a media file's bytes through the authenticated client
/// (club_core#173): for private media — an evaluation's evidence or its
/// stored member copy — that a plain URL cannot fetch without the bearer
/// token, so the app can open it locally.
///
/// A read; nothing is cached or held in state.
final Provider<MediaBytesReader> clMediaBytesReaderProvider =
    Provider<MediaBytesReader>(
      (ref) => (media) async {
        final client = await ref.read(secureClientProvider.future);
        final bytes = await client.media.download(
          media.uuid,
          filename: media.filename,
        );
        return Uint8List.fromList(bytes);
      },
    );
