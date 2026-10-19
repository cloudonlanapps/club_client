import 'package:cl_remote_store/cl_remote_store.dart'
    show SiteMediaSlot, clPublicSiteMediaProvider;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../extensions/site_media_slot_bundled_asset.dart';

/// The hero image of a page that has none of its own: the server's default
/// page hero, or the bundled one until it has loaded (or when it has none).
final pageHeroFallbackUriProvider = Provider<String>(
  (ref) =>
      ref
          .watch(clPublicSiteMediaProvider(SiteMediaSlot.pageHeroDefault))
          ?.uri ??
      SiteMediaSlot.pageHeroDefault.bundledAsset,
);
