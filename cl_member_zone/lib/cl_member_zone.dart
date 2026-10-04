/// Authenticated member-zone screens for the club app.
///
/// Each screen mounts at a `/memberzone/...` route (see `app/lib/router.dart`),
/// owns its permission gate via `cl_member_auth` helpers, and forwards
/// `currentUser` to the underlying view in the relevant feature package
/// (`cl_club_events`, `cl_club_members`, `cl_club_venues`).
///
/// Internally the package builds on `club_sdk_2`'s `SecureClient` and the
/// remote-store providers; the host app must override `serverConfigProvider`
/// in its `ProviderScope` with the API base URL.
library;

// Screens
export 'src/screens/admin_group_profile_screen.dart'
    show AdminGroupProfileScreen;
export 'src/screens/admin_user_profile_screen.dart' show AdminUserProfileScreen;
export 'src/screens/admin_user_review_screen.dart' show AdminUserReviewScreen;
export 'src/screens/audit_log_screen.dart' show AuditLogScreen;
export 'src/screens/broadcast.dart' show BroadcastScreen;
export 'src/screens/club_identity_screen.dart' show ClubIdentityScreen;
export 'src/screens/credit_screen.dart' show CreditScreen;
export 'src/screens/dashboard.dart' show DashboardScreen;
export 'src/screens/event_details_screen.dart' show EventDetailsScreen;
export 'src/screens/event_enrolments_screen.dart' show EventEnrolmentsScreen;
export 'src/screens/event_occurences_attendance_screen.dart'
    show EventOccurencesAttendanceScreen;
export 'src/screens/events_calendar_screen.dart' show EventsCalendarScreen;
export 'src/screens/events_camps_new_screen.dart' show EventsCampsNewScreen;
export 'src/screens/events_camps_screen.dart' show EventsCampsScreen;
export 'src/screens/events_one_off_new_screen.dart' show EventsOneOffNewScreen;
export 'src/screens/events_one_off_screen.dart' show EventsOneOffScreen;
export 'src/screens/events_programmes_new_screen.dart'
    show EventsProgrammesNewScreen;
export 'src/screens/events_programmes_screen.dart' show EventsProgrammesScreen;
export 'src/screens/group_create_screen.dart' show GroupCreateScreen;
export 'src/screens/group_join_requests_screen.dart'
    show GroupJoinRequestsScreen;
export 'src/screens/group_members_screen.dart' show GroupMembersScreen;
export 'src/screens/groups_screen.dart' show GroupsScreen;
export 'src/screens/inquiries_screen.dart' show InquiriesScreen;
export 'src/screens/my_event_details_screen.dart' show MyEventDetailsScreen;
export 'src/screens/my_events_all_screen.dart' show MyEventsAllScreen;
export 'src/screens/my_events_attendance_screen.dart'
    show MyEventsAttendanceScreen;
export 'src/screens/my_events_calendar_screen.dart' show MyEventsCalendarScreen;
export 'src/screens/my_group_details_screen.dart' show MyGroupDetailsScreen;
export 'src/screens/my_groups_screen.dart' show MyGroupsScreen;
export 'src/screens/my_review_screen.dart' show MyReviewScreen;
export 'src/screens/my_reviews_screen.dart' show MyReviewsScreen;
export 'src/screens/my_venue_detail.dart' show MyVenueDetailScreen;
export 'src/screens/notifications_list_screen.dart'
    show NotificationsListScreen;
export 'src/screens/pending_actions_list_screen.dart'
    show PendingActionsListScreen;
export 'src/screens/placeholder.dart' show PlaceholderScreen;
export 'src/screens/profile_screen.dart' show ProfileScreen;
export 'src/screens/public_profile_screen.dart' show PublicProfileScreen;
export 'src/screens/review_edit_screen.dart' show ReviewEditScreen;
export 'src/screens/reviews_screen.dart' show ReviewsScreen;
export 'src/screens/site_media_screen.dart' show SiteMediaScreen;
export 'src/screens/template_create_screen.dart' show TemplateCreateScreen;
export 'src/screens/template_detail_screen.dart' show TemplateDetailScreen;
export 'src/screens/template_library_screen.dart' show TemplateLibraryScreen;
export 'src/screens/user_create_screen.dart' show UserCreateScreen;
export 'src/screens/users.dart' show UsersScreen;
export 'src/screens/venue_create_screen.dart' show VenueCreateScreen;
export 'src/screens/venue_profile_screen.dart' show VenueProfileScreen;
export 'src/screens/venues_screen.dart' show VenuesScreen;
// Shell
export 'src/widgets/member_zone_shell.dart' show MemberZoneShell;
