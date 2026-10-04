import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Read-only public profile by HMAC `publicId`, via the unauthenticated
/// `/public/profile/by_id/{publicId}` endpoint.
///
/// Returns the privacy-safe [PublicProfile] (display name, bio, achievements,
/// optional avatar media uuid). Throws a `ServerException` (404) when the id
/// does not resolve to a publicly-surfaced coach.
final AutoDisposeFutureProviderFamily<PublicProfile, String>
clPublicProfileProvider = FutureProvider.autoDispose
    .family<PublicProfile, String>((
      ref,
      publicId,
    ) async {
      ref.watch(clManualRefreshProvider);
      final client = await ref.read(secureClientProvider.future);
      return client.public.getPublicProfile(publicId);
    });
