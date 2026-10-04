import 'package:cl_remote_store/src/models/media_url_builder.dart';
import 'package:cl_server_config/cl_server_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Download URLs for the media the public reads carry — covers, galleries,
/// avatars, venue photos, site media slots (club_core#53) — bound to the
/// configured API base.
///
/// Public media is fetched without a token, so these URLs work on the
/// website as they do in the apps.
final Provider<MediaUrlBuilder> clPublicMediaUrlProvider =
    Provider<MediaUrlBuilder>((ref) {
      return MediaUrlBuilder(ref.watch(apiBaseUrlProvider));
    });
