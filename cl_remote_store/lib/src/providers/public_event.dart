import 'package:cl_remote_store/src/utils/public_read.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// One public, live event by its opaque public id (club_core#53).
///
/// A private, deleted or unknown id fails with the server's 404
/// `ServerException`.
final AutoDisposeFutureProviderFamily<PublicEvent, String>
clPublicEventProvider = FutureProvider.autoDispose.family<PublicEvent, String>(
  (ref, publicId) {
    return readPublic(ref, (source) => source.getPublicEvent(publicId));
  },
);
