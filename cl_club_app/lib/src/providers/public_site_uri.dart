import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The club's public website, or null when the club has none.
///
/// `clubMain` overrides it from `club.json`'s `websiteUrl`, which a
/// `CLUB_PUBLIC_SITE_URL` dart-define overrides per environment, as
/// `CLUB_API_BASE_URL` does the API.
final publicSiteUriProvider = Provider<Uri?>((ref) => null);
