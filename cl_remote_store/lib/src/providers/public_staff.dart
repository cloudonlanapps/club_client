import 'package:cl_remote_store/src/utils/public_read.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The coaches on the public staff page, in curated order, guests withheld
/// (club_core#53).
final AutoDisposeFutureProvider<List<PublicProfile>> clPublicStaffProvider =
    FutureProvider.autoDispose<List<PublicProfile>>((ref) {
      return readPublic(ref, (source) => source.listPublicStaff());
    });
