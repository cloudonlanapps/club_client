import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The club's member app, or null when the site links to none.
///
/// `websiteMain` overrides it from `club.json`'s `memberAppUrl`, which a
/// `CLUB_MEMBER_APP_URL` dart-define overrides per environment
/// (club_core#179).
final memberAppUriProvider = Provider<Uri?>((ref) => null);
