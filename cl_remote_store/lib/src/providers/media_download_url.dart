import 'package:cl_server_config/cl_server_config.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Builds the full v2 media download URL from a media uuid (+ optional
/// variant), using [apiBaseUrlProvider] as the base.
///
/// Resulting shape: `${apiBaseUrl}/media/by_id/<uuid>/download?variant=<v>`.
/// Default variant is `original`, matching the server.
///
/// Prefer [mediaRefDownloadUrlProvider] wherever a [MediaRef] is at hand: it
/// puts the filename in the path, so the URL ends in a real extension and an
/// extension-sniffing renderer works. This one is for the flows that hold a
/// uuid and nothing else.
final Provider<String> Function(({String uuid, String variant}))
mediaDownloadUrlProvider =
    Provider.family<String, ({String uuid, String variant})>((ref, args) {
      final base = ref.watch(apiBaseUrlProvider);
      return '$base/media/by_id/${args.uuid}/download?variant=${args.variant}';
    });

/// Builds the full download URL for a [MediaRef] (club_server#424).
///
/// The URL shape is the SDK's — see `mediaDownloadUrl` — and this only binds
/// it to [apiBaseUrlProvider] so a widget does not have to reach for the base
/// itself.
final Provider<String> Function(({MediaRef media, String variant}))
mediaRefDownloadUrlProvider =
    Provider.family<String, ({MediaRef media, String variant})>((ref, args) {
      return mediaDownloadUrl(
        ref.watch(apiBaseUrlProvider),
        args.media,
        variant: args.variant,
      );
    });

/// The still preview for [MediaRef], or `null` when it has none.
///
/// A video's frame and a PDF's first page live at `?variant=poster`; an image
/// is its own preview, and a caller gets `null` rather than a URL that 404s.
final Provider<String?> Function(MediaRef) mediaRefPosterUrlProvider =
    Provider.family<String?, MediaRef>((ref, media) {
      return mediaPosterUrl(ref.watch(apiBaseUrlProvider), media);
    });
