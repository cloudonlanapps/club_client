import 'package:cl_remote_store/src/utils/public_read.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Every live venue as its public projection (club_core#53).
final AutoDisposeFutureProvider<List<PublicVenue>> clPublicVenuesProvider =
    FutureProvider.autoDispose<List<PublicVenue>>((ref) {
      return readPublic(ref, (source) => source.listPublicVenues());
    });
