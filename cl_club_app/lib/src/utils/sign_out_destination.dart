/// Where a member lands after choosing to sign out (club_core#179): the
/// club's public website on the web, when the club has one; null means stay
/// in the app, at its login page.
///
/// Mobile and desktop builds never leave the app.
Uri? signOutDestination(Uri? publicSite, {required bool isWeb}) =>
    isWeb ? publicSite : null;
