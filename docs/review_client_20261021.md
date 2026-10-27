# club_client whole-codebase review log (2026-10-21)

Scope: every package in `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client` (18 packages, ~112k lib lines), read-only; no tests were run. Nine package reviewers each ran eight angles (line-by-line bugs, removed invariants, cross-file tracing, reuse, simplification, efficiency, altitude, CLAUDE.md conventions); the 152 raw findings were merged into the 104 below. Each entry says what is wrong in plain words, when it bites, and a red test to write first where one is possible.

Totals: 7 high, 40 medium, 57 low at review time. Still open here: 36 (0 high, 11 medium, 25 low); 68 removed on 2026-10-21 as fixed (PR #218), filed as an issue (#192, #202-#204, #209-#217, #219, #220, #208, #221, #223-#248, club_server#62, club_server#63, club_sdk#53), or dropped. Findings 9 and 53 wait on a decision.

Severity: high = wrong data or a user locked out/misled in normal use; medium = a real bug on a plausible path, or a stale/unsafe state; low = cleanup, convention, or an edge case.

Repo-wide checks that came back clean: every package pins club_sdk at the same SHA and cl_calendar/cl_gallery_viewer at one SHA each; no `version:` line in any pubspec; all direct dependencies pinned exactly; no ShadForm outside cl_club_forms/ui_lib; no Riverpod or club_sdk_2 import in cl_club_forms/ui_lib; no SDK client reads outside cl_remote_store/cl_member_auth; clubMain() supplies every required provider override; every deep link resolves to a route.

## HIGH

None left.

## MEDIUM

### 9. [cl_club_app] Thirteen routes decide whether to show a Back arrow with context.canPop() at pageBuilder time, which the file's own comments (lines 582-584, 631-633, 691-693) say is always false inside the shell builder; the other routes use popOrGo. Pushed list pages therefore lose their back arrow.

- **Needs decision: should top-level list pages always show Back (to the dashboard), or only when pushed? (canPop() is false at pageBuilder time even for a pushed shell route.)**

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/cl_club_app/lib/src/router.dart:563`
- When it breaks: Dashboard 'See more' notifications (line 541, a push) -> pageBuilder for /memberzone/notifications runs before the Navigator holds the page, canPop() is false, NotificationsListScreen gets onBack: null. Same at lines 600, 616, 651, 664, 720, 795, 835, 919, 934, 960, 986, 1225.
- Red test: cl_club_app/test/routes/back_affordance_test.dart - testWidgets('cl_club_app router: a pushed list route gets a back callback'): router.go('/'), router.push('/memberzone/notifications'), pumpAndSettle; expect tester.widget<NotificationsListScreen>(...).onBack isNotNull.

### 19. [cl_club_forms] Moving a camp's start date keeps rest days that are no longer inside the camp window, so they inflate the camp length and are sent to the server as rest days outside the camp.

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/cl_club_forms/lib/src/widgets/event_schedule/camp_schedule_fields.dart:198`
- When it breaks: Camp start 2 Nov, 5 training days, rest day 4 Nov; admin moves the start to 16 Nov: excludedDates still holds 4 Nov, durationDays (line 87) = 6, the calendar highlights 16-21 Nov with no rest day in range, and emit() ships the stale date, which cl_club_events passes through as restDays (event_create_form_helpers.dart:103, camp_schedule_form_helpers.dart:126).
- Red test: cl_club_forms/test/event_schedule/camp_schedule_fields_test.dart - testWidgets('cl_club_forms camp-rest-days-outside-window-dropped'): startDate 2026-11-02, trainingDays 5, excludedDates {2026-11-04}; change the start to 2026-11-16; expect value.excludedDates empty and durationDays == 5.

### 27. [cl_club_website] The website ignores club.json's eventTypes (SiteConfig never reads it) and always advertises Camps, Programmes and One-off, while the generator's sitemap and the member app only list the types the club runs.

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/cl_club_website/lib/src/site/widgets/public_navbar.dart:64`
- When it breaks: Camps-only club (no eventTypes key): sitemap.xml omits /public/programs and /public/one-off, but the navbar (lines 64-88), the mobile drawer, the landing page sections (home.dart:177-230) and the carousel texts (section_carousel_indicator.dart:57-61) all show Programmes and One-off as permanently empty pages.
- Red test: cl_club_website/test/site_config_test.dart - test('cl_club_website eventTypes-read-from-club-json'): SiteConfig.fromJson({..., 'eventTypes': ['camp']}).eventTypes == {EventType.camp}; and public_navbar_test.dart - testWidgets('cl_club_website navbar-hides-listings-the-club-does-not-run'): camps-only SiteConfig; expect find.text(strings.navPrograms) findsNothing.

### 28. [club_project_generator] The path-dependency rewriter matches ANY indented 'path:' line, so a dependency on the pub package named 'path' would be rewritten into a filesystem path and break every club build.

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/club_project_generator/lib/src/pubspec_paths.dart:13`
- When it breaks: Either example adds 'path: 1.9.1' to its dependencies (the generator itself depends on it) -> generated pubspec reads 'path: /.../example/1.9.1' -> flutter pub get fails. Latent today.
- Red test: club_project_generator/test/parts_test.dart - test('club_project_generator path-package-dependency-is-not-rewritten'): absolutizePathDependencies('dependencies:\n  path: 1.9.1\n  ui_lib:\n    path: ../../ui_lib\n', '/core/x/example') contains 'path: 1.9.1\n' and 'path: /core/ui_lib'.

### 29. [club_project_generator] Every generated club app and website loads hls.js from a CDN at the floating @latest tag, so a third-party release can change or break every club's page without any change in this repo.

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/club_project_generator/templates/web/index.html:89`
- When it breaks: jsdelivr serves a new major hls.js with a breaking API, or the CDN is blocked on a visitor's network -> Safari/iOS hero video stops for all clubs; also an unpinned supply-chain surface on the member app, which does not even play HLS.
- Red test: club_project_generator/test/parts_test.dart - test('club_project_generator index-template-has-no-floating-cdn-version'): read templates/web/index.html, expect it not to contain '@latest'.

### 30. [cl_club_evaluation] The Transfer step's preparation (loading the users list for the coach picker) runs outside the try/catch, so a failed users fetch is an unhandled error with no toast and no dialog.

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/cl_club_evaluation/lib/src/widgets/evaluation_management_card.dart:316`
- When it breaks: Coach taps Transfer while clUsersMasterProvider is in error -> prepare(step) throws into an unawaited future; running was never set, so the UI just does nothing.
- Red test: cl_club_evaluation/test/widgets/evaluation_transfer_failure_test.dart - testWidgets('cl_club_evaluation transfer-users-fetch-fails shows a toast'): clUsersMasterProvider overridden to throw; tap Transfer; expect a destructive toast and tester.takeException() isNull.

### 31. [cl_club_evaluation] The evaluation editor is replaced by a spinner whenever the evaluations or templates master is merely refreshing (isLoading is true during a refresh that still holds data), which unmounts the fill form and the autosave mid-edit.

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/cl_club_evaluation/lib/src/views/evaluation_edit_view.dart:75`
- When it breaks: Coach typing in a draft; a manual refresh or refetchAfterUncertainWrite fires -> AsyncLoading(previous) -> ShadProgress -> EvaluationEditBody disposes: focus and scroll lost, an open 'Clear answer?' prompt orphaned, and the form re-seeds from whatever the refetch returns, possibly older than what was just typed.
- Red test: cl_club_evaluation/test/views/evaluation_edit_refresh_test.dart - testWidgets('cl_club_evaluation refresh-keeps-editor-mounted'): draft open, stub master whose refetch completes after a Completer; bump clManualRefreshProvider and pump once; expect find.byType(EvaluationEditBody) still present.

### 32. [cl_club_evaluation] Clearing an answer that has evidence is silently dropped when the editor closes before the 700 ms autosave delay, because the confirmation can no longer be asked.

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/cl_club_evaluation/lib/src/widgets/evaluation_clear_answer_prompt.dart:34`
- When it breaks: Coach empties a rated answer with an attached photo and taps Back within autosaveDelay -> dispose() flushes -> confirmClearAnswer with context null returns false -> no clearAnswer, no toast; the old answer and evidence remain while the coach believes it was cleared.
- Red test: cl_club_evaluation/test/utils/evaluation_autosave_dispose_test.dart - testWidgets('cl_club_evaluation clear-with-evidence-on-back is written or reported'): item with evidence, set the answer empty, tap Back immediately; expect clearAnswer called once or a toast shown (today neither).

### 33. [cl_club_evaluation] Duplicating a template that is not in the loaded map (deleted elsewhere, or the master in error) silently opens a blank 'New template' designer instead of saying the source is missing.

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/cl_club_evaluation/lib/src/views/template_create_view.dart:168`
- When it breaks: reviews/templates/new?copy=42 after template 42 was deleted -> source null -> initialValues fall back to null -> empty designer titled 'New template'; the admin may create an empty template believing it is the copy.
- Red test: cl_club_evaluation/test/views/template_create_missing_copy_test.dart - testWidgets('cl_club_evaluation duplicate-of-missing-template says so'): templates {1}, pump TemplateCreateView(copyOfTemplateId: 99); expect a 'template missing' message and no EvaluationTemplateCreateForm.

### 34. [cl_club_evaluation] Every draft evaluation subscribes to the roster of every event the coach coaches (one network fetch each) on every build, even in read mode where the list is only needed once the pencil is tapped.

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/cl_club_evaluation/lib/src/widgets/evaluation_period_card.dart:91`
- When it breaks: Coach with 12 active events opens any draft -> StartReviewChoices.eventsFor watches clEnrollmentsMasterProvider for all 12 -> 12 roster requests per draft, repeated whenever those masters invalidate, although editBuilder is not built.
- Red test: cl_club_evaluation/test/widgets/evaluation_period_card_lazy_test.dart - testWidgets('cl_club_evaluation period-card-does-not-load-rosters-in-read-mode'): draft with three coached events and a counting stub for clEnrollmentsMasterProvider; pump without tapping the pencil; expect count 0 (today 3).

### 35. [cl_club_credits] The credit statement's loadMore is fired unawaited from the list builder; a failed page fetch is an unhandled error, the spinner row stays, and every rebuild near the end re-fires the request (a retry storm while offline).

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/cl_club_credits/lib/src/views/credit_view.dart:180`
- When it breaks: More pages exist and the server is briefly down -> fetchPage throws -> unawaited future rejects with no toast -> hasMore stays true, the spinner keeps spinning, each scroll schedules another request.
- Red test: cl_club_credits/test/credit_view_load_more_failure_test.dart - testWidgets('cl_club_credits load-more-failure shows a message and stops'): statement of 30 entries hasMore true, listMyEntries(offset: 30) throws; scroll to the bottom; expect tester.takeException() isNull and a 'Could not load more' message.

## LOW

### 53. [cl_club_forms] The Extend form only checks that the new end is after the current end; unlike Grant and Transfer it never checks the new end is not already in the past.

- **Needs decision: the server's extend_validity only requires the new end to be later than the current one; it does not refuse a past end. A 'not in the past' rule in the form would be stricter than the server (R62). Drop, or ask the server to refuse it too?**

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/cl_club_forms/lib/src/widgets/credit/credit_extend_form.dart:72`
- When it breaks: Account expired 31 Jan; admin picks 1 Mar (also past): validates, the host sends it and the server's refusal arrives as a toast instead of the inline rule the sibling forms show via CreditFormValidators.window.
- Red test: cl_club_forms/test/widgets/credit/credit_extend_form_test.dart - testWidgets('cl_club_forms credit-extend-refuses-past-end'): CreditExtendForm(currentValidUntil: DateTime(2026,1,31)); pick 2026-03-01 and a reason; expect validate() == null and an inline message (needs a 'today' parameter like CreditGrantForm).

### 54. [cl_club_forms] The camp schedule validator trusts that the session split sums to the daily duration, while the one-off and timetable forms check it with EventTimetableFormValidators.sessionsTotal.

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/cl_club_forms/lib/src/widgets/event_schedule/camp_schedule_fields.dart:53`
- When it breaks: A host seeds durationMinutes 120 with sessions summing to 90: the split editor shows '30m unassigned' but aggregateValidator passes and Save sends the pair; the server refuses INVALID_SESSIONS_TOTAL, which the form cannot place on a field.
- Red test: cl_club_forms/test/event_schedule/camp_schedule_form_test.dart - test('cl_club_forms camp-validator-refuses-split-not-summing-to-duration'): CampScheduleData(durationMinutes: 120, sessions: [09:00-10:30]); expect aggregateValidator(...) isNotNull.

### 55. [cl_club_forms] A pre-filled username in initialValues is never shown: the input has its own controller, and ShadInputFormField takes the controller's empty text over the form's initial value.

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/cl_club_forms/lib/src/widgets/signup/username_availability_field.dart:348`
- When it breaks: UserForm(initialValues: {usernameId: 'ravi'}) opens with an empty username; isDirty/validate() see ''. shadcn input.dart:260: initialValue: controller != null ? controller.text : initialValue.
- Red test: cl_club_forms/test/widgets/user_form/user_form_test.dart - testWidgets('cl_club_forms user-form-prefilled-username-shown'): initialValues {usernameId: 'ravi'}; expect find.widgetWithText(ShadInput, 'ravi') findsOneWidget.

### 56. [cl_club_forms] The one-off schedule form clears its form-level message itself from onChanged (formError = null) instead of leaving it to FormContract, as rule 20 says; the spacing rule (14) is also broken in a few places and the venue validator is re-implemented four times with two different messages.

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/cl_club_forms/lib/src/widgets/event_schedule/one_off_schedule_form.dart:314`
- When it breaks: valuesAtFormError stays set while formError is cleared (stale state for any future reader). Bare spacing: session_split_field.dart:272/286, username_availability_field.dart:362/370, camp_date_exclusion_calendar.dart:128, two_column_grid.dart:17-18. Venue validator: occurrence_reschedule_form_validators.dart:8 says 'Venue is required' while event_create/one_off/programme_schedule_adjust say 'Please select a venue'.
- Red test: not testable (convention); drop the formError = null line, one shared venue validator beside EventVenueSelectField.

### 57. [cl_club_forms] GroupCreateForm (and cl_club_members group_eligibility_section.dart:83) rebuild the whole form on every keystroke (onChanged: () => setState(() {})) only so the eligibility block can re-evaluate whether to show Clear; programme_schedule_fields.dart:71 and camp_schedule_fields.dart:163-172 also carry duplicated pass-through delegators.

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/cl_club_forms/lib/src/widgets/group_form/group_create_form.dart:806`
- When it breaks: Typing a group name deep-copies the whole value map per character; jank on slow web builds and phones.
- Red test: not testable (efficiency); let the eligibility block own a small ValueListenable.

### 66. [cl_club_website] The shared event detail route passes notFoundKey 'event', which maps to the Camp copy, so a dead programme or one-off link says 'Camp Not Found / View All Camps'; the programme/one-off not-found copy in the ARB is unreachable. The detail page's error branch (pages.dart:339) also renders NotFoundPage for a network failure, so an outage reads as 'does not exist'.

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/cl_club_website/lib/src/site/router.dart:265`
- When it breaks: Stale /public/events/<programme-id> link -> 'Camp Not Found' with a button to the camps listing.
- Red test: Not cleanly testable until the type is known before the 404; SiteCopy(strings).notFound('program')!.buttonRoute == '/public/programs' passes today - the gap is that no caller reaches it.

### 67. [cl_club_website] TheClubPage keys an autoDispose provider family with a brand-new ClubInfo on every build, and the SDK's ClubInfo.hashCode is built from List identity, so each rebuild creates a fresh family member instead of hitting the cache.

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/cl_club_website/lib/src/screens/pages.dart:248`
- When it breaks: Every rebuild (theme toggle, resize, scroll) allocates and disposes a provider. Root cause: club_sdk ClubInfo.hashCode (club_info.dart:68) breaks the ==/hashCode contract.
- Red test: cl_club_website/test/pages_test.dart - test('cl_club_website clubinfo-family-key-stable'): a = SiteCopy(strings).clubInfo; b = SiteCopy(strings).clubInfo; expect a == b and a.hashCode == b.hashCode (fails today; SDK fix or cache the ClubInfo).

### 68. [cl_club_website] The breadcrumb skips the parent segment of every two-segment route assuming it has no page, but /public/events/<id>'s parent /public/events is a real listing, so event pages lose their link back to the listing.

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/cl_club_website/lib/src/widgets/public_page_shell.dart:254`
- When it breaks: On /public/events/abc the breadcrumb is 'Home > <event title>' with no 'Camps' link; the comment only justifies the skip for /public/rink/<id>.
- Red test: cl_club_website/test/breadcrumb_test.dart - testWidgets('cl_club_website breadcrumb-links-event-listing'): Breadcrumb under a GoRouter at /public/events/abc; expect a ShadBreadcrumbLink with strings.navEvents.

### 69. [cl_club_website] Template-wide copy bypasses the ARB: 'Back', 'Home', 'All rights reserved.', 'Loading...', 'Learn to Play', 'Ice Masters', 'The Rinks', 'No Information', 'Contact Us', 'The site could not load.'; ContactFab's 'WhatsApp'/'Call Us'/'Email' (cl_club_branding contact_fab.dart:120-140) likewise cannot be localised. 'Ice Masters' and 'The Rinks' (pages.dart) are also sport-specific in a neutral template.

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/cl_club_website/lib/src/widgets/public_page_shell.dart:180`
- When it breaks: A club whose website/app_en.arb is in another language still ships these English fragments, and a non-ice-hockey club gets rink wording.
- Red test: not testable as a unit; move the strings to SiteStrings keys (brand_files_test then enforces them) and give ContactFab a labels parameter.

### 70. [cl_club_website] A malformed CLUB_MEMBER_APP_URL dart-define (or memberAppUrl in club.json) is Uri.parse'd before runApp with no fallback, so a typo in the deploy blanks the whole site.

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/cl_club_website/lib/src/site/website_main.dart:61`
- When it breaks: --dart-define=CLUB_MEMBER_APP_URL='http://[bad' -> FormatException before the first frame -> white page for every visitor.
- Red test: cl_club_website/test/site_config_test.dart - test('cl_club_website member-app-url-malformed-is-ignored'): SiteConfig.fromJson({..., 'memberAppUrl': 'http://[bad'}).memberAppUrl isNull after moving the parse into SiteConfig with Uri.tryParse.

### 71. [cl_club_website] metaDescriptionFrom is a line-for-line copy of the generator's searchDescription (160 limit, '**' strip, cut at word), and PublicFooter re-implements AppFooter's copyright line; cl_club_website/CLAUDE.md:12 documents 'cd example && flutter run -d chrome' but no example ships a web/ folder.

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/cl_club_website/lib/src/utils/meta_description.dart:7`
- When it breaks: A rule change applied to one copy leaves the built-in description and the per-page description formatted differently; a contributor following the doc gets 'not configured to build on the web'.
- Red test: not testable (cleanup/doc).

### 72. [club_project_generator] checkUrl accepts a website URL with a query string or fragment, and pageUrl just appends the route, so sitemap/robots URLs come out malformed; the existing test asserts only the escaping of such a URL.

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/club_project_generator/lib/src/search_files.dart:64`
- When it breaks: --website-url 'https://example.org/site?a=1' -> <loc>https://example.org/site?a=1/public/coaches</loc>, which crawlers reject.
- Red test: club_project_generator/test/parts_test.dart - test('club_project_generator website-url-with-query-is-refused'): expect checkUrl('--website-url', 'https://example.org/site?a=1') throws GeneratorException; same for '#frag'.

### 73. [club_project_generator] The icon, club.json and ARB story are validated only after the template has been copied, so a bad brand leaves a half-written output folder that the next run refuses as 'exists and is not empty'; and a URL that does not apply to the target (--app-url for the app) is silently dropped rather than refused (club_json.dart:21).

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/club_project_generator/lib/src/generator.dart:162`
- When it breaks: Brand ships a 300x300 icon -> template copied, then renderIcons throws; the retry fails until someone deletes the folder. 'generate app ... --app-url X' meant as --website-url -> club.json has no websiteUrl and nobody is told.
- Red test: club_project_generator/test/generate_test.dart - test('club_project_generator bad-icon-leaves-no-output'): brand with a 256x256 icon; expect GeneratorException and the out dir absent/empty. parts_test.dart - test('club_project_generator app-url-for-app-target-is-refused'): GenerateOptions(target: app, appUrl: ...) throws.

### 74. [cl_club_branding] AppLogo imports dart:io and handles a file: URI with Image.file, which is unreachable on the web-only website and throws UnsupportedError if a web host ever overrides appLogoUriProvider with a file URI.

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/cl_club_branding/lib/src/widgets/app_logo.dart:1`
- When it breaks: Latent today (both hosts use asset:); the import is the one thing tying cl_club_branding to dart:io.
- Red test: not practically testable in flutter_test; drop the file: scheme or guard with kIsWeb.

### 76. [cl_club_evaluation] An event title is read through the member's own event-detail provider, so a coach's list fetches one event detail per row and shows an empty caption segment forever when the member can no longer see that event.

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/cl_club_evaluation/lib/src/utils/evaluation_names.dart:20`
- When it breaks: Coach view with 30 evaluations -> 30 clMyEventDetailProvider subscriptions; a withdrawn member's event is refused -> '' -> caption 'Template ·  · 1 May 2026 - 31 May 2026' (CoachEvaluationRow:42-46 joins unconditionally).
- Red test: cl_club_evaluation/test/widgets/coach_evaluation_row_caption_test.dart - testWidgets('cl_club_evaluation row-caption-has-no-empty-segment'): clMyEventDetailProvider overridden to AsyncError; expect no Text containing ' ·  · '.

### 77. [cl_club_evaluation] A non-section layout entry with zero or several item ids throws StateError (.single) instead of being dropped like an unknown id, so one malformed server layout entry crashes every view of that template.

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/cl_club_evaluation/lib/src/models/evaluation_layout_adapter.dart:30`
- When it breaks: Server returns an entry with items [] or [3, 4] -> entry.items.single throws -> TemplateDetailView, EvaluationEditView and EvaluationReadContent all render the error widget. Same in EvaluationTemplateFile.encode:34.
- Red test: cl_club_evaluation/test/models/evaluation_layout_adapter_malformed_test.dart - test('cl_club_evaluation layout-item-with-two-ids is dropped'): layout entry with items [1, 2]; expect fromTemplate returns normally.

### 78. [cl_club_evaluation] keepOrigin remaps the coach-note rule through a map keyed by the derived choice value, so two relabelled choices whose labels derive the same value collapse and the rule lands on the wrong choice.

- **Note:** Also from finding 58 (dropped otherwise: the server freezes a template's items once any evaluation uses it, R27): relabelling a choice in the item designer silently drops a requireCommentFor rule set on the old label's value (evaluation_item_form.dart:876-879). Handle with this finding.

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/cl_club_evaluation/lib/src/models/evaluation_item_adapter.dart:246`
- When it breaks: Origin values [a, b]; labels 'Yes!' and 'Yes?' both derive 'yes' -> renamed = {'yes': 'b'} (last wins) -> a note required for the first choice is mapped to 'b'.
- Red test: cl_club_evaluation/test/models/evaluation_item_adapter_test.dart - test('cl_club_evaluation keepOrigin-maps-rule-by-position when labels collide'): expect result.requireCommentFor == ['a'].

### 79. [cl_club_evaluation] After adding items the layout sync returns early and never sends updateLayout, so any reorder or section retitle in the same change as an add is silently lost; correctness depends on the editor emitting exactly one operation per change.

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/cl_club_evaluation/lib/src/utils/evaluation_layout_sync.dart:56`
- When it breaks: A layout with a new item appended and an existing item moved: the item is added, the move is dropped, preview and server disagree until the next edit.
- Red test: cl_club_evaluation/test/utils/evaluation_layout_sync_test.dart - test('cl_club_evaluation add-and-move in one change sends both'): before [A, B], after [B, A, newC]; expect addItem then updateLayout recorded.

### 80. [cl_club_evaluation] The private toast helper is duplicated verbatim in EvaluationManagementCardState and TemplateDetailBodyState next to the package's own showEvaluationErrorToast, and they already drift; CreditActionPanel/CreditActionDialog duplicate the Cancel/Save row and 'Saving…' labels (cl_club_credits credit_action_panel.dart:20).

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/cl_club_evaluation/lib/src/widgets/evaluation_management_card.dart:66`
- When it breaks: One passes EvaluationErrorMessage.of, the other the raw step message.
- Red test: not testable (cleanup).

### 81. [cl_club_credits] Reverse and Transfer are hidden when the package cannot take them, instead of greyed out with a reason as the Credit UI contract requires; and the credit header shows the member's status as the raw enum name (credit_header.dart:44, 'pendingApproval').

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/cl_club_credits/lib/src/widgets/credit_account_menu.dart:66`
- When it breaks: Admin opens the row menu of a usable general package with balance 0: only Extend is listed, with no hint why Reverse/Transfer are absent; the sheet header reads 'jane · pendingApproval'.
- Red test: cl_club_credits/test/credit_account_menu_disabled_test.dart - testWidgets('cl_club_credits menu-greys-forbidden-actions'): account balance 0, general, usable; open the menu; expect find.text('Reverse') exists and is disabled. credit_header_status_label_test.dart: expect no Text with the raw enum name.

### 82. [cl_club_credits] Add credit lists only active programmes, but a '+' chip can pre-fill a programme that is inactive, so the pre-fill may match no option and silently become a general grant or a blank field.

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/cl_club_credits/lib/src/widgets/credit_action_form.dart:203`
- When it breaks: Admin assigns a member to a programme whose event isActive is false -> CreditChip.add pre-fills programmeId -> the select has no option for it.
- Red test: cl_club_credits/test/credit_grant_prefill_inactive_test.dart - testWidgets('cl_club_credits prefilled-programme-is-offered-even-if-inactive'): programme 5 isActive false; showCreditGrantDialog(programmeId: 5); expect programme 5 selected.

### 90. [cl_server_config] Offline detection relies on dart:io SocketException, which never occurs on the web target the club projects are built for, so a web app with no connectivity always says 'Server Unavailable' instead of 'No Internet Connection'.

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/cl_server_config/lib/src/providers/network_status.dart:113`
- When it breaks: Flutter web, Wi-Fi off, Try Again -> serverUnavailable and 'our servers are temporarily unavailable'. The notifier has no http-client injection point, which is also why cl_server_config_test.dart covers only ServerConfig.
- Red test: cl_server_config/test/network_status_test.dart - test('cl_server_config client-exception-is-offline'): inject an http.Client that throws http.ClientException('Failed to fetch'); checkNow(); expect NetworkStatus.offline.

### 97. [cl_member_onboarding] The submit-documents screen gate ignores identityVerification, relying on the router redirect for a rule the screen is supposed to own.

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/cl_member_onboarding/lib/src/screens/onboarding_submit_documents_screen.dart:31`
- When it breaks: Any host mounting OnboardingSubmitDocumentsScreen without the cl_club_app redirect (the package's own example app) shows the upload step on a server with identityVerification=false; submit then fails server-side.
- Red test: cl_member_onboarding/test/screens/onboarding_submit_documents_screen_test.dart (extend) - testWidgets('cl_member_onboarding submit documents refused when verification is off'): identityVerification false; expect ErrorView 'Not available'.

### 100. [cl_club_communication] Most event-family notification formatters fall the title back to a label but still interpolate the empty title into the body, producing bodies like ' was cancelled.'; trialDates(data) is also computed twice in one expression (line 575).

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/cl_club_communication/lib/src/utils/notification_registry.dart:338`
- When it breaks: Payload without eventTitle (older server row, deleted event) -> title 'Event cancelled', body ' was cancelled.' (also lines 354, 367, 402, 415, 428, 485, 497, 512, 529, 543, 559 and notification_kinds_programme.dart:62/77).
- Red test: cl_club_communication/test/notification_registry_empty_title_test.dart - test('cl_club_communication formatNotification: event.cancelled without eventTitle has a full sentence'): expect body isNot(startsWith(' ')).

### 104. [repo] The issue templates' module dropdowns predate the republish: they list 'app', 'club_website', 'club_sdk_2', 'cl_gallery_viewer', 'cl_calendar' (not carried here) and miss cl_club_events, cl_club_forms, cl_remote_store, cl_club_credits, cl_club_evaluation, cl_club_admin, cl_club_communication, cl_club_branding, cl_club_venues, cl_member_onboarding, cl_club_app, cl_club_website and club_project_generator; the same staleness that the last commit fixed for the labels. CONTRIBUTING.md:32 also points at app/docs/QUICK_START_TEST.md and 'just app-test-<target>', neither of which exists.

- Where: `/media/anandas/disk1TB/Work/cloudonlanapps/club/club_client/.github/ISSUE_TEMPLATE/bug_report.yml:49`
- When it breaks: A reporter cannot name the affected package for most bugs and picks 'Other / unsure'; nothing checks the templates' labels or options against the repo, so the label regression could recur unnoticed (GitHub silently ignores a label a repo does not have).
- Red test: scripts/check_issue_templates.sh (run in CI): parse each template's 'labels:' line and assert every label is in 'gh label list'; parse the dropdown 'options:' and assert each (except the Other/unsure/New/Multiple entries) is a directory with a pubspec.yaml at the repo root. Fails today on the five stale options.
