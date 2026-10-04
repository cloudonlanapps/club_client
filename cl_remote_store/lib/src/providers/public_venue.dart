import 'package:cl_remote_store/src/utils/public_read.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One live venue by its opaque public id (club_core#53). A deleted or
/// unknown id fails with the server's 404 `ServerException`.
final AutoDisposeFutureProviderFamily<PublicVenue, String>
clPublicVenueProvider = FutureProvider.autoDispose.family<PublicVenue, String>(
  (ref, publicId) {
    return readPublic(ref, (source) => source.getPublicVenue(publicId));
  },
);
