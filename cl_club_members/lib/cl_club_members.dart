/// User and member management widgets and providers for the club app.
///
/// Provides scaffold-free content views that plug into the host's shell
/// layout. All navigation is callback-based — no go_router dependency.
library;

// Providers
export 'src/providers/pending_users.dart' show pendingUsersProvider;
// Views
export 'src/views/admin_user_review_view.dart' show AdminUserReviewView;
export 'src/views/group_create_view.dart' show GroupCreateView;
export 'src/views/group_join_requests_view.dart' show GroupJoinRequestsView;
export 'src/views/group_list_view.dart' show GroupListView;
export 'src/views/group_members_view.dart' show GroupMembersView;
export 'src/views/group_profile_view.dart' show AdminGroupProfileView;
export 'src/views/my_group_details_view.dart' show MyGroupDetailsView;
export 'src/views/my_groups_view.dart' show MyGroupsView;
export 'src/views/profile_view.dart' show ProfileView;
export 'src/views/public_profile_view.dart' show PublicProfileView;
export 'src/views/user_create_view.dart' show UserCreateView;
export 'src/views/user_list_view.dart' show UserListView;
export 'src/views/user_profile_view.dart' show AdminUserProfileView;
// Public staff list (the website)
export 'src/widgets/coach_card.dart' show CoachCard;
export 'src/widgets/coaches_card_list.dart' show CoachesCardList;
