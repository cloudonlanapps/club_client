import 'package:cl_remote_store/src/models/site_media_asset.dart';
import 'package:cl_remote_store/src/models/site_media_slot.dart';
import 'package:cl_remote_store/src/providers/public_club_info.dart';
import 'package:cl_remote_store/src/providers/public_media_url.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The admin's upload for a website media slot, or `null` where the site
/// shows its own default (club_core#53).
///
/// `null` is not only failure. A deployment that has configured nothing
/// publishes an empty `siteMedia` map, and that is a normal state: the site
/// is expected to look like itself out of the box, so the caller keeps a
/// bundled default for every slot.
///
/// Resolves synchronously and never blocks: `null` until the club info has
/// arrived, and for good if it never does. A slot holding neither an image
/// nor a video (a PDF is not a hero) is treated as unset.
final AutoDisposeProviderFamily<SiteMediaAsset?, SiteMediaSlot>
clPublicSiteMediaProvider = Provider.autoDispose
    .family<SiteMediaAsset?, SiteMediaSlot>((ref, slot) {
      final media = ref
          .watch(clPublicClubInfoProvider)
          .valueOrNull
          ?.siteMedia[slot.serverKey];
      if (media == null || (!media.isImage && !media.isVideo)) return null;

      final urls = ref.watch(clPublicMediaUrlProvider);
      return SiteMediaAsset(
        uri: urls(media)!,
        isVideo: media.isVideo,
        // The animated preview where the server made one — a hero that
        // cannot play inline still moves — and the still frame otherwise.
        previewUri: urls.animated(media) ?? urls.preview(media),
      );
    });
