/// Centralized data source providers with cross-invalidation.
///
/// This package provides all domain resource providers (events, users,
/// venues, groups, enrollments, attendance) with proper cross-invalidation
/// between admin and member views.
library;

export 'src/models/aggregated_my_event.dart';
export 'src/models/audit_log_scope.dart';
export 'src/models/contact_info.dart';
export 'src/models/credit_statement.dart' show CreditStatement;
export 'src/models/evaluation_item_search_query.dart'
    show EvaluationItemSearchQuery;
export 'src/models/evaluation_member_media.dart' show EvaluationMemberMedia;
export 'src/models/inquiry_filter.dart' show InquiryFilter;
export 'src/models/inquiry_inbox.dart' show InquiryInbox;
export 'src/models/media_bytes_reader.dart' show MediaBytesReader;
export 'src/models/media_url_builder.dart' show MediaUrlBuilder;
export 'src/models/member_evaluation_key.dart' show MemberEvaluationKey;
export 'src/models/occurrence_key.dart';
export 'src/models/occurrences_key.dart';
export 'src/models/resource_version_state.dart';
export 'src/models/site_media_asset.dart' show SiteMediaAsset;
export 'src/models/site_media_slot.dart' show SiteMediaSlot;
export 'src/providers/attendances_master.dart';
export 'src/providers/audit_log_master.dart';
export 'src/providers/broadcasts_master.dart';
export 'src/providers/bundled_contact_info.dart'
    show bundledContactInfoProvider;
export 'src/providers/capabilities.dart'
    show
        capabilitiesProvider,
        creditSystemProvider,
        evaluationsProvider,
        identityVerificationProvider;
export 'src/providers/client.dart' show secureClientProvider;
export 'src/providers/club_event_types.dart' show clubEventTypesProvider;
export 'src/providers/club_identity_master.dart'
    show ClClubIdentityMasterNotifier, clClubIdentityMasterProvider;
export 'src/providers/contact_info.dart' show contactInfoProvider;
export 'src/providers/credit_accounts_master.dart'
    show ClCreditAccountsMasterNotifier, clCreditAccountsMasterProvider;
export 'src/providers/credit_entries_master.dart'
    show
        ClCreditEntriesMasterNotifier,
        clCreditEntriesMasterProvider,
        creditStatementPageSize;
export 'src/providers/credit_usable_for_event.dart'
    show ClCreditUsableKey, clCreditUsableForEventProvider;
export 'src/providers/current_user.dart' show currentUserProvider;
export 'src/providers/eligible_users.dart';
export 'src/providers/eligible_users_for_event.dart';
export 'src/providers/enrollment_records_master.dart';
export 'src/providers/enrollments_master.dart';
export 'src/providers/evaluation_item_search.dart'
    show clEvaluationItemSearchProvider, evaluationItemSearchLimit;
export 'src/providers/evaluation_media.dart' show clEvaluationMediaProvider;
export 'src/providers/evaluation_templates_master.dart'
    show
        ClEvaluationTemplatesMasterNotifier,
        clEvaluationTemplatesMasterProvider;
export 'src/providers/evaluations_master.dart'
    show ClEvaluationsMasterNotifier, clEvaluationsMasterProvider;
export 'src/providers/event_credit_roster.dart'
    show ClEventCreditRosterNotifier, clEventCreditRosterProvider;
export 'src/providers/event_detail.dart';
export 'src/providers/event_media.dart'
    show
        EventGalleryImage,
        EventMediaMutationNotifier,
        EventMediaMutationProvider,
        eventCoverImageProvider,
        eventGalleryProvider,
        eventMediaMutationProvider,
        kEventCoverTag,
        kEventGalleryTag;
export 'src/providers/event_schedules.dart';
export 'src/providers/events.dart';
export 'src/providers/events_master.dart';
export 'src/providers/group_media.dart'
    show
        GroupMediaMutationNotifier,
        GroupMediaMutationProvider,
        groupImageProvider,
        groupMediaMutationProvider,
        kGroupImageTag;
export 'src/providers/group_members.dart';
export 'src/providers/group_requests_master.dart';
export 'src/providers/groups.dart';
export 'src/providers/groups_master.dart';
export 'src/providers/identity_documents_master.dart'
    show
        ClIdentityDocsMasterNotifier,
        clIdentityDocsMasterProvider,
        kIdentityDocumentAccessRoles,
        kIdentityDocumentTag;
export 'src/providers/image_picker.dart' show imagePickerProvider;
export 'src/providers/inquiries_master.dart'
    show
        ClInquiriesMasterNotifier,
        clInquiriesMasterProvider,
        clUnhandledInquiryCountProvider,
        inquiryPageSize;
export 'src/providers/manual_refresh.dart';
export 'src/providers/media_bytes_reader.dart' show clMediaBytesReaderProvider;
export 'src/providers/media_download_url.dart'
    show
        mediaDownloadUrlProvider,
        mediaRefDownloadUrlProvider,
        mediaRefPosterUrlProvider;
export 'src/providers/member_credit_total.dart'
    show clMemberCreditTotalProvider;
export 'src/providers/member_evaluation_media.dart'
    show clMemberEvaluationMediaProvider;
export 'src/providers/member_evaluations.dart' show clMemberEvaluationsProvider;
export 'src/providers/my_attendance_list.dart';
export 'src/providers/my_attendances_master.dart';
export 'src/providers/my_eligible_groups.dart';
export 'src/providers/my_enrollment.dart';
export 'src/providers/my_enrollments_master.dart';
export 'src/providers/my_event_detail.dart';
export 'src/providers/my_events_aggregated.dart';
export 'src/providers/my_events_master.dart';
export 'src/providers/my_groups_master.dart';
export 'src/providers/my_join_requests_master.dart';
export 'src/providers/my_occurrences.dart';
export 'src/providers/my_occurrences_list.dart';
export 'src/providers/notifications_master.dart';
export 'src/providers/occurrences.dart';
export 'src/providers/occurrences_notifier.dart';
export 'src/providers/pending_actions_master.dart';
export 'src/providers/public_club_content.dart'
    show clPublicClubContentProvider;
export 'src/providers/public_club_info.dart' show clPublicClubInfoProvider;
export 'src/providers/public_event.dart' show clPublicEventProvider;
export 'src/providers/public_event_marketing.dart'
    show clPublicEventMarketingProvider;
export 'src/providers/public_events.dart'
    show clPublicEventsProvider, publicEventsPageLimit;
export 'src/providers/public_featured_events.dart'
    show clPublicFeaturedEventsProvider;
export 'src/providers/public_inquiry.dart'
    show ClPublicInquiryNotifier, clPublicInquiryProvider;
export 'src/providers/public_media_url.dart' show clPublicMediaUrlProvider;
export 'src/providers/public_profile.dart' show clPublicProfileProvider;
export 'src/providers/public_site_media.dart' show clPublicSiteMediaProvider;
export 'src/providers/public_staff.dart' show clPublicStaffProvider;
export 'src/providers/public_venue.dart' show clPublicVenueProvider;
export 'src/providers/public_venues.dart' show clPublicVenuesProvider;
export 'src/providers/registered_users.dart' show clRegisteredUsersProvider;
export 'src/providers/resource_version.dart';
export 'src/providers/single_occurrence.dart';
export 'src/providers/site_media_master.dart'
    show
        ClMediaLibraryNotifier,
        ClSiteMediaMasterNotifier,
        clMediaLibraryProvider,
        clSiteMediaMasterProvider,
        isPublicMedia;
export 'src/providers/usable_credit_accounts.dart'
    show ClUsableCreditAccountsNotifier, clUsableCreditAccountsProvider;
export 'src/providers/user_avatar.dart'
    show
        AvatarMutationNotifier,
        AvatarMutationProvider,
        avatarImageProvider,
        avatarMutationProvider,
        avatarVisibilityProvider,
        kUserAvatarTag;
export 'src/providers/user_groups.dart';
export 'src/providers/user_info.dart' show clUserInfoProvider;
export 'src/providers/user_private.dart';
export 'src/providers/user_stats.dart';
export 'src/providers/users.dart';
export 'src/providers/users_master.dart';
export 'src/providers/venue_detail.dart';
export 'src/providers/venue_media.dart'
    show
        VenueMediaMutationNotifier,
        VenueMediaMutationProvider,
        kVenueImageTag,
        venueImageProvider,
        venueMediaMutationProvider;
export 'src/providers/venues.dart';
export 'src/providers/venues_master.dart';
export 'src/utils/club_content_from_server.dart' show defaultClubValueIconName;
export 'src/utils/contact_info_from_server.dart' show contactInfoFromServer;
export 'src/utils/credit_funding.dart' show usableCreditsFor;
export 'src/utils/enrollment_error_messages.dart'
    show enrollmentApproveErrorMessage, enrollmentRemoveErrorMessage;
export 'src/utils/evaluation_incomplete.dart' show evaluationIncompleteItemIds;
export 'src/utils/event_eligibility.dart'
    show EligibilityFailure, EligibilityFailureReason, checkEventEligibility;
export 'src/utils/uncertain_write.dart' show writeMayHaveLanded;
export 'src/utils/write_failure_message.dart'
    show uncertainWriteMessage, writeFailureMessage;
