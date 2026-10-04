import 'package:cl_remote_store/src/utils/public_read.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The extended marketing block of a public event, or `null` where there is
/// none (club_core#53).
///
/// Allowed to fail: the module can be off (a 503
/// `ModuleDisabledException`) and an event can simply have no block (404).
/// Neither is a reason to fail a page — it renders the event without the
/// sections the block would have filled — so both resolve to `null`.
final AutoDisposeFutureProviderFamily<EventMarketing?, String>
clPublicEventMarketingProvider = FutureProvider.autoDispose
    .family<EventMarketing?, String>((ref, publicId) async {
      try {
        return await readPublic(
          ref,
          (source) => source.getPublicEventMarketing(publicId),
        );
      } on Exception {
        return null;
      }
    });
