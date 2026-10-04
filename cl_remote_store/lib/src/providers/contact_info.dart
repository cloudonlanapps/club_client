import 'package:cl_remote_store/src/models/contact_info.dart';
import 'package:cl_remote_store/src/providers/bundled_contact_info.dart';
import 'package:cl_remote_store/src/providers/public_club_info.dart';
import 'package:cl_remote_store/src/utils/contact_info_from_server.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How to reach the club, for the apps and the website alike
/// (club_core#53): the server's public club identity, field by field over
/// the host's bundled block ([bundledContactInfoProvider]).
///
/// Synchronous, and never blocks: until the public club info arrives — and
/// if it never does — this is the bundled block. Once it has arrived it is
/// kept across refreshes, and a save in the club-details screen refreshes
/// it (`ClClubIdentityMasterNotifier.save`), so an edit reaches the apps
/// without a rebuild.
final Provider<ContactInfo> contactInfoProvider = Provider<ContactInfo>((ref) {
  final bundled = ref.watch(bundledContactInfoProvider);
  final info = ref.watch(clPublicClubInfoProvider).valueOrNull;
  if (info == null) return bundled;
  return contactInfoFromServer(info.identity, fallback: bundled);
});
