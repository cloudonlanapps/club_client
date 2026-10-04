/// Venue management widgets and providers for the club app.
///
/// Provides venue CRUD screens following the cl_club_members pattern.
/// Built on `club_sdk_2`'s `SecureClient`. Authentication is provided by
/// `cl_member_auth`.
library;

// Views
export 'src/views/member_venue_detail_view.dart' show MemberVenueDetailView;
export 'src/views/venue_create_view.dart' show VenueCreateView;
export 'src/views/venue_list_view.dart' show VenueListView;
export 'src/views/venue_profile_view.dart' show VenueProfileView;
// Widgets
export 'src/widgets/cards/public_venue_card.dart' show PublicVenueCard;
export 'src/widgets/cards/venue_card.dart' show VenueCard;
export 'src/widgets/event_venue_line.dart' show EventVenueLine;
export 'src/widgets/public_venue_list.dart' show PublicVenueList;
export 'src/widgets/venue_content.dart' show VenueContent;
export 'src/widgets/venue_timestamps.dart' show VenueTimestamps;
