# Master Providers

Cross-package inventory of providers that own canonical state for mutable
domain resources, plus the read-only / derived / family providers that depend
on them.

**Where the code lives.** All master providers live in `cl_remote_store`
(`cl_remote_store/lib/src/providers/`). `cl_server_config` itself ships only
configuration, the authenticated SDK client, and network-status providers.
The canonical export list is
[`cl_remote_store/lib/cl_remote_store.dart`](../../cl_remote_store/lib/cl_remote_store.dart).

**SDK-call boundary.** SDK data calls happen in `cl_remote_store` (via
`secureClientProvider` from `cl_server_config`). Auth-adjacent SDK calls
(login, logout, changePassword, getCurrentUser) happen in `cl_member_auth`.
No other module calls the SDK directly.

## Master Providers (own canonical state, expose mutations)

| Provider | File (`cl_remote_store/lib/src/providers/`) | State Shape | Key Mutations |
|----------|---------------------------------------------|-------------|---------------|
| `clUsersMasterProvider` | `users_master.dart` | `Map<String, UserInfo>` keyed by username | `createUser`, `updateUser`, `deleteUser`, `restoreUser`, `hardDeleteUser`, `approveUser`, `blockUser`, `unblockUser`, `markLeft`, `reactivateUser`, `submitForReviewForSelf`, `assignRole`, `removeRole`, `transferSuperAdmin`, `adminResetPassword` |
| `clUserGalleryMasterProvider(username)` | `user_gallery_master.dart` | `Map<String, List<GalleryItem>>` grouped by tag (family by username) | `addItem`, `updateUri`, `deleteItem`, `deleteTag`, `refresh` |
| `clMyUploadsMasterProvider` | `my_uploads_master.dart` | `Map<int, UploadedMedia>` of the caller's own `/uploaded/myfiles` | `upload`, `discardOrphan`, `refresh` |
| `clEventsMasterProvider` | `events_master.dart` | `Map<int, Event>` keyed by eventId | `createEvent`, `updateEvent`, `correctionOnEvent`, `updateEventForAllFuture`, `cancelSeries`, `deleteEvent`, `restoreEvent`, `hardDeleteEvent`, `rescheduleOccurrence`, `cancelOccurrence`, `undoCancelOccurrence` |
| `clVenuesMasterProvider` | `venues_master.dart` | `Map<int, Venue>` keyed by venueId | `createVenue`, `updateVenue`, `deleteVenue`, `restoreVenue`, `hardDeleteVenue` |
| `clGroupsMasterProvider` | `groups_master.dart` | `Map<int, Group>` keyed by groupId | `createGroup`, `updateGroup`, `deleteGroup`, `restoreGroup`, `hardDeleteGroup`, `addMember`, `removeMember`, `addMembersBulk` |
| `clEnrollmentsMasterProvider(eventId)` | `enrollments_master.dart` | Per-event `Map<String, EnrollmentStatus>` (family by `int` eventId) | `invite`, `inviteBulk`, `assign`, `assignBulk`, `assignTrial`, `approveRequest`, `approveRequestsBulk`, `rejectRequest`, `removeEnrollment`, `approveWithdraw`, `approveWithdrawBulk`, `rejectWithdraw` |
| `clAttendancesMasterProvider(key)` | `attendances_master.dart` | Per-occurrence attendance (family by `AttendanceKey` = eventId + occurrenceTimeUtc) | `markAttendance`, `approveLeave`, `approveLeaveBulk`, `rejectLeave`, `rejectLeaveBulk` |
| `clNotificationsMasterProvider` | `notifications_master.dart` | Paged list of in-app notifications | `loadMore`, `refresh`, `markRead`, `markAllRead`, `deleteNotification` |
| `clPendingActionsMasterProvider` | `pending_actions_master.dart` | Paged list of pending-action notifications | `loadMore`, `refresh`, `dismissLocally` |
| `clInquiriesMasterProvider` | `inquiries_master.dart` | `InquiryInbox`: the admin inquiry inbox page for the current `InquiryFilter` (kind, handled; server-side, paged) plus the open count across the inbox; empty with no call unless admin | `setFilter`, `nextPage`, `previousPage`, `refresh`, `setHandled`, `deleteInquiry` |
| `clSiteMediaMasterProvider` | `site_media_master.dart` | `Map<String, MediaRef>`: the public website's media slots by server key, read from the public club info; empty with no call unless super-admin | `save` (the whole `site_media` preference), `uploadPublic` |
| `clMediaLibraryProvider` | `site_media_master.dart` | `List<Media>`: live images and videos a super-admin can link to a slot (autoDispose); empty with no call unless super-admin | — |
| `clClubIdentityMasterProvider` | `club_identity_master.dart` | `ClubIdentity`: the club's name, short name, inquiry email and public contact block (the `club_info` preference), unknown keys kept in `extra`; empty with no call unless super-admin | `save` (the whole `club_info` document) |
| `clBroadcastsMasterProvider` | `broadcasts_master.dart` | `Map<int, Broadcast>` keyed by broadcastId | `refresh`, `sendText`, `revoke` |
| `clCreditAccountsMasterProvider(username)` | `credit_accounts_master.dart` | One member's `List<CreditAccount>`, closed included (family, autoDispose); empty with no call unless `creditSystemProvider` is true | `openAccount`, `extendValidity`, `reverseGrant`, `transfer` (each bumps `creditsVersion`) |
| `clCreditEntriesMasterProvider(username)` | `credit_entries_master.dart` | One member's statement, newest first, paged (family, autoDispose) | `loadMore` |
| `clEventCreditRosterProvider(eventId)` | `event_credit_roster.dart` | A programme's credit roster by membername (usable, blocked, `boundCredits`; family, autoDispose); empty with no call unless credit is on and the event is a programme | — (refetched on `creditsVersion`) |
| `clUsableCreditAccountsProvider` | `usable_credit_accounts.dart` | Every member's usable accounts by membername (staff listing, autoDispose), for the Assign pickers | — |
| `clEvaluationTemplatesMasterProvider` | `evaluation_templates_master.dart` | `Map<int, EvaluationTemplate>`: the template library, all pages (staff read, admin write); a soft-deleted template stays with `deletedAtUtc` set until reload; empty with no call unless `evaluationsProvider` is true (#173) | `createTemplate`, `renameTemplate`, `updateLayout`, `addItem`, `replaceItem`, `removeItem`, `deleteTemplate`, `restoreTemplate` (each bumps `evaluationsVersion`) |
| `clEvaluationsMasterProvider` | `evaluations_master.dart` | `Map<int, EvaluationStaffView>`: the caller's own evaluations (the effective owner's only; an admin's is empty), all pages; a soft-deleted one stays with `deletedAtUtc` set until reload; empty with no call unless `evaluationsProvider` is true (#173) | `createEvaluation`, `updateEvaluation` (a draft's event and/or period, partial: an omitted getter is unchanged), `putAnswer`, `clearAnswer`, `saveEvaluation` (422 `INCOMPLETE` rethrown; `evaluationIncompleteItemIds`), `publishEvaluation`, `unpublishEvaluation`, `revertEvaluation`, `deleteEvaluation`, `restoreEvaluation`, `transferEvaluation` (removes it locally), `uploadEvidence` (one call: the server stores the file as the member's, staff and member only, never public, and links it; replaced locally), `detachEvidence` (then refetch the evaluation), `previewPdf` (a read: PDF bytes); each write bumps `evaluationsVersion` |

### Member-scope masters

These mirror the admin masters but for the currently-logged-in member.

| Provider | File | State Shape |
|----------|------|-------------|
| `clMyEnrollmentsMasterProvider` | `my_enrollments_master.dart` | Member's enrollments across events |
| `clMyAttendancesMasterProvider(eventId)` | `my_attendances_master.dart` | Member's attendances for one event (family, autoDispose) |
| `clMyEventsMasterProvider` | `my_events_master.dart` | Member's enrolled events |
| `clMyGroupsMasterProvider` | `my_groups_master.dart` | Groups the member belongs to |
| `clMyJoinRequestsMasterProvider` | `my_join_requests_master.dart` | Member's outstanding join requests |
| `clMyIdentityDocSlotsProvider` | `cl_club_members/lib/src/providers/my_identity_doc_slots.dart` | Derived `List<IdentityDocumentSlot>` from `clUserGalleryMasterProvider(self)` (tag `identity-document`) ∪ `clMyUploadsMasterProvider` (orphans with `usageContext == 'user_identity_document'`). UI-side; no SDK calls. |
| `clGroupRequestsMasterProvider(groupId)` | `group_requests_master.dart` | Pending join requests for a group (family) |

## Read-Only / Derived Providers (no independent SDK calls)

| Provider | File | Derives From |
|----------|------|--------------|
| `clUsersProvider` | `users.dart` | `clUsersMasterProvider` |
| `clUnhandledInquiryCountProvider` | `inquiries_master.dart` | `clInquiriesMasterProvider` (the admin sidebar's Inquiries count) |
| `clUserPrivateProvider(username)` | `user_private.dart` | `clUsersMasterProvider` + `getUserPrivate()` for detail cache |
| `clUserStatsProvider` | `user_stats.dart` | `clUsersMasterProvider` |
| `clUserGroupsProvider(username)` | `user_groups.dart` | `clGroupsMasterProvider` |
| `clUserIneligibleGroupIdsProvider(username)` | `user_ineligible_group_ids.dart` | `clUserGroupsProvider` + `clGroupMembersProvider` of the semi-auto groups that count an ineligible member (staff only) |
| `clGroupsProvider` | `groups.dart` | `clGroupsMasterProvider` |
| `clGroupMembersProvider(groupId)` | `group_members.dart` | `clGroupsMasterProvider` |
| `clEligibleUsersProvider(eventId)` | `eligible_users.dart` | `clUsersMasterProvider` + event filter |
| `clMyEligibleGroupsProvider` | `my_eligible_groups.dart` | `clGroupsMasterProvider` |
| `clVenuesProvider` | `venues.dart` | `clVenuesMasterProvider` |
| `clVenueDetailProvider(id)` | `venue_detail.dart` | `clVenuesMasterProvider` |
| `clEventsProvider` | `events.dart` | `clEventsMasterProvider` |
| `clEventDetailProvider(eventId)` | `event_detail.dart` | `clEventsMasterProvider` |
| `clEventChainProvider(eventId)` | `event_chain.dart` | `clEventsMasterProvider` |
| `clMyEventDetailProvider(eventId)` | `my_event_detail.dart` | `clMyEventsMasterProvider` |
| `clMyEventsAggregatedProvider` | `my_events_aggregated.dart` | `clMyEventsMasterProvider` + `clMyEnrollmentProvider` |
| `clMyEnrollmentProvider((eventId, username))` | `my_enrollment.dart` | `clMyEnrollmentsMasterProvider` |
| `clOccurrencesProvider(args)` | `occurrences.dart` | `clEventsMasterProvider` + occurrence query |
| `clMyOccurrencesProvider(args)` | `my_occurrences.dart` | `clMyEventsMasterProvider` |
| `clMyOccurrencesListProvider` | `my_occurrences_list.dart` | `clMyOccurrencesProvider` |
| `clMyAttendanceListProvider` | `my_attendance_list.dart` | `clMyAttendancesMasterProvider` |
| `clSingleOccurrenceProvider(key)` | `single_occurrence.dart` | `clEventsMasterProvider` |
| `unreadNotificationCountProvider` | `notifications_master.dart` | `clNotificationsMasterProvider` |
| `creditSystemProvider` | `capabilities.dart` | `capabilitiesProvider` (`creditSystem`; null while unknown) |
| `clMemberCreditTotalProvider(username)` | `member_credit_total.dart` | `clCreditAccountsMasterProvider` (sum of usable balances) |
| `evaluationsProvider` | `capabilities.dart` | `capabilitiesProvider` (`evaluations`; null while unknown) |
| `defaultCountryCodeProvider` | `capabilities.dart` | `capabilitiesProvider` (`defaultCountryCode`, digits only; `fallbackCountryCode` (`91`) when the server reports none or has not answered; works on the website too, so a form that saves with it starts the read when it appears) |
| `clMemberEvaluationsProvider(username)` | `member_evaluations.dart` | `MyEvaluationsSource` (the member's published `EvaluationMemberView`s, all pages; autoDispose; empty with no call unless `evaluationsProvider` is true; refetched on `evaluationsVersion`) |
| `clMemberEvaluationMediaProvider((username, evaluationId))` | `member_evaluation_media.dart` | `MyEvaluationsSource` (`EvaluationMemberMedia`: the stored `member_copy` PDF and evidence by item id; autoDispose; null with no call unless `evaluationsProvider` is true; refetched on `evaluationsVersion`) |
| `clEvaluationMediaProvider(evaluationId)` | `evaluation_media.dart` | `EvaluationMediaSource.listGrouped` (the owner's view: `EvaluationMemberMedia` with evidence on every item, private included, and the member copy; autoDispose; null with no call unless `evaluationsProvider` is true; refetched on `evaluationsVersion`) |
| `clEvaluationItemSearchProvider(EvaluationItemSearchQuery)` | `evaluation_item_search.dart` | `EvaluationSource.searchItems` ("Existing question": the first `evaluationItemSearchLimit` hits for text + item type; autoDispose; empty with no call unless `evaluationsProvider` is true) |
| `clCreditUsableForEventProvider((username, eventId, trial))` | `credit_usable_for_event.dart` | `clCreditAccountsMasterProvider` (general or this programme, matching trial flag: the server's funding rule) |
| `occurrencesNotifierProvider(args)` | `occurrences_notifier.dart` | `clEventsMasterProvider` (autoDispose) |

## Public Providers (token-free `/public`, apps and website)

Read-only, auto-disposing providers over the token-free `PublicSource`
(`clPublicSourceProvider`, internal: built from `apiBaseUrlProvider`, not
from `secureClientProvider`, so the website — which has no session — uses
them too; club_core#53). Each read goes through `readPublic`
(`utils/public_read.dart`): it watches `networkStatusProvider` and
`clManualRefreshProvider`, calls `markOnline()` on success and `checkNow()`
on failure.

`GET /capabilities` needs no token either but is not under `/public`.
`capabilitiesProvider` serves it to both hosts: through `secureClientProvider`
in an app, and, where the host gave none (the website; the provider then
throws `SecureClientNotProvided`), through `clSessionlessClientProvider`
(`sessionless_client.dart`, internal: a logged-out SDK client built from
`apiBaseUrlProvider`, which holds no session and sends nothing until asked;
club_core#31).

| Provider | File | State Shape |
|----------|------|-------------|
| `clPublicEventsProvider(EventType)` | `public_events.dart` | `List<PublicEvent>` of one type, past included (`isPast` is the server's) |
| `clPublicFeaturedEventsProvider` | `public_featured_events.dart` | `List<PublicEvent>`, featured, every type |
| `clPublicEventProvider(publicId)` | `public_event.dart` | `PublicEvent` (404 → error) |
| `clPublicEventMarketingProvider(publicId)` | `public_event_marketing.dart` | `EventMarketing?` — null when the module is off or the event has no block |
| `clPublicStaffProvider` | `public_staff.dart` | `List<PublicProfile>`, the staff page, guests withheld |
| `clPublicVenuesProvider` | `public_venues.dart` | `List<PublicVenue>` |
| `clPublicVenueProvider(publicId)` | `public_venue.dart` | `PublicVenue` (404 → error) |
| `clPublicClubInfoProvider` | `public_club_info.dart` | `PublicClubInfo` — `clubInfo` (typed as `.identity`) and `siteMedia` |
| `clPublicClubContentProvider(fallback)` | `public_club_content.dart` | `ClubInfo` (history, values) from `clPublicClubInfoProvider`, part by part over the bundled `fallback`; sync, never blocks |
| `clPublicSiteMediaProvider(SiteMediaSlot)` | `public_site_media.dart` | `SiteMediaAsset?` — the admin's image/video for a slot, null for the caller's bundled default; sync |
| `clPublicMediaUrlProvider` | `public_media_url.dart` | `MediaUrlBuilder` — download / preview / animated URLs for a `MediaRef` |
| `clPublicInquiryProvider` | `public_inquiry.dart` | stateless; `formToken()`, `submit(...)` for the public inquiry form |

## Club Configuration

| Provider | File | Role |
|----------|------|------|
| `clubEventTypesProvider` | `club_event_types.dart` | The event types the club runs (`club.json` `eventTypes`, overridden by `clubMain()`; camps alone by default). `clEventsMasterProvider` and `clOccurrencesProvider` fetch these types only (#115). |

## Cross-Invalidation Plumbing

| Provider | File | Role |
|----------|------|------|
| `clResourceVersionProvider` | `resource_version.dart` | Bumps a version counter to invalidate derived providers across resources (e.g., when an attendance change should refresh occurrence views). `creditsVersion` is bumped by credit actions, attendance marks and clears, leave decisions and enrollment changes; every credit provider watches it. `evaluationsVersion` is bumped by every evaluation and evaluation-template write; the member-surface evaluation providers watch it. |

## What `cl_server_config` Provides (for reference)

`cl_server_config` ships the infrastructure that masters in `cl_remote_store`
build on top of:

| Provider | File (`cl_server_config/lib/src/providers/`) | Purpose |
|----------|----------------------------------------------|---------|
| `serverConfigProvider`, `apiBaseUrlProvider` | `config.dart` | API base URL (overridden by host app) |
| `secureClientProvider` | `client.dart` | Authenticated SDK client (overridden by host app with the client from `cl_member_auth`) |
| `currentUserProvider` | `current_user.dart` | Re-exports the logged-in `UserPrivate` for non-auth consumers |
| `networkStatusProvider` | `network_status.dart` | Reactive online/offline state; `/health` ping on demand |

## Adding a New Master Provider

1. Create the file under `cl_remote_store/lib/src/providers/`.
2. Add it to the export list in `cl_remote_store/lib/cl_remote_store.dart`.
3. Add a row to the appropriate table above.
4. Have the notifier read `secureClientProvider` from `cl_server_config` for
   its SDK client; do **not** import the SDK client directly.

## Boundary Audit

- All SDK data calls outside `cl_member_auth` go through `cl_remote_store`.
- `cl_server_config` itself makes no domain SDK calls; its only outbound
  call is the `/health` ping in `NetworkStatusNotifier`.
- Feature packages (`cl_club_members`, `cl_member_zone`, `app`, …) consume
  `cl_remote_store` providers and never call the SDK directly.
