# Changelog

## 1.3.0

Built against club_server 1.3.0. club_sdk_2 is pinned at cloudonlanapps/club_sdk
be5d638, the SDK's 1.3.0 commit (#343).

- Extended profile, shown while the server reports it on: Sports details,
  Background and Guardian sections on a member's profile, the membership
  date on Account info, an optional profile step in onboarding, and the
  club's positions and languages edited on Club details (#320).
- Applications, shown while the server reports them on: an admin edits a
  printable application template section by section with a preview and
  publishes it; a member downloads their filled form as a PDF from
  Applications, their profile or the waiting page (#321).

## 1.2.0

Released with club_server, club_sdk and club_cli 1.2.0. club_sdk_2 is pinned
at the SDK's 1.2.0 commit.

- Schedule clashes are shown in a dialog and saved only if the organizer
  accepts them, as club_server 1.2.0 now reports every clash (#278).
- A super-admin can reschedule, cancel and manage requests on a session that
  has already happened (#312).
- Evaluation templates: deleted templates are listed and can be restored
  (#277); a review template has a live preview beside its editor (#28).
- One Broadcast screen for every audience, admin-only, with the composer
  fixed at the top (#252, #269, #203).
- Occurrence and event-page actions follow the server's rules: by event type,
  Undo Cancel on a cancelled occurrence, one cancellation dialog (#177–#179,
  #182–#189, #191, #213, #230).
- The session is restored offline, Try Again re-runs it, and signing out stops
  every request that needs the session (#190, #257, #272); screens are gated
  by role and the sidebar routes belong to the router (#192, #203, #204).
- A deleted member stays in the admin list, shown as deleted (#236); a failed
  reload keeps the evaluation page and what was typed (#268); the calendar
  lists today's sessions after local midnight (#300).
- Phones: keyboard and focus fixes, enrollment rows that fit, icon-only
  actions with labels (#159–#166, #168, #263, #264, #296).
- The generated web page sets a Content-Security-Policy, and hls.js is gone
  from the web template (#314, #315).
- The generator adds an Android target to the app with the brand's id, name
  and icons (#280); the member app example has one too (#262).
- Review findings fixed across ui_lib, cl_remote_store and the member, venue
  and event packages (#193–#201, #205–#212, #214–#216, #219–#221, #223–#229,
  #231–#235, #237–#244, #246–#248).
- Tests: the integration suites run at a phone's size, in Chrome and on an
  Android phone, each suite on a fresh stack, with a full unattended
  regression runner (#274, #288, #291, #302, #286).

## 1.0.1

- Review templates can be exported to a JSON file and imported from one (#27).
- New Marketing page for an event, for admins and the event's organizer: edit
  the website's marketing for the event section by section, with a live
  preview of the website page (#1).
- The website's event page and its page layout moved into the shared packages,
  so the app's preview and the website draw the same widgets (#157).
- Marketing date fields no longer overflow in a narrow column (#171).
- Test fix: the archive workflow test waits for the page to redraw after
  Unarchive (#173).
- A cancelled session no longer offers Attendance. From half an hour before
  it starts, only a super-admin is offered Undo Cancel; a session cancelled
  with its series offers nothing (#177).
- A session's actions follow its event type. A programme's session offers
  End programme from here, which opens Adjust end date on the day before
  it, in place of Cancel entire series. A one-off's session offers Call off
  and Manage requests, with no series action and no Reschedule (#178).
- The review template library's Import button shows an import icon, not an
  upload one (#179).
- On a phone's browser, starting to scroll a form no longer closes the
  keyboard; only a tap outside the field does (#159).
- Sign up and Create user no longer ask you to check the username first; a
  username already taken is refused when you save, on the username field,
  with everything you typed kept (#161).
- Pages with open editors or a search box keep their content, typed text and
  scroll position while their data reloads, instead of flashing a loading
  spinner (#162).
- A dropped connection shows a banner over the page instead of replacing it,
  so what was typed is kept; the banner appears only after a second failed
  check (#163).
- Emptying an evaluation answer that has evidence no longer asks mid-typing;
  the question comes when you leave the field or finalize, and Cancel keeps
  anything newly typed (#164).
- The markdown editor dialog fits above a phone's keyboard: its text box
  scrolls inside, and on a phone held sideways the dialog scrolls instead of
  overflowing (#166).
- On a phone with the keyboard up, the Broadcast screen scrolls so the email
  options and Send stay reachable instead of overflowing (#168).
- On a phone's browser the sign-in forms no longer open the keyboard by
  themselves, and the page fills the screen again once the keyboard closes
  (#160).
- A failed reload keeps the evaluation page and what was typed; "couldn't
  load" shows only when there is no data at all (#268).
- The Broadcast screen keeps its composer fixed at the top while the sent
  list scrolls, and hides the list while the phone keyboard is open so Send
  can be reached by scrolling (#269).
- After signing out, the app no longer calls the server with the dropped
  token: open pages stop fetching and no token refresh is tried (#272).
- The review template library lists deleted templates (Show deleted
  templates), and any coach or admin can restore one. A template whose name
  another template now holds comes back renamed "<name> -- Restored #1",
  and the message says the new name (#277).
- A schedule or staff save that clashes with another event no longer just
  fails: a dialog lists the clashing events under venue, organizer and
  coach, with the clashing dates and times. Save anyway saves it; Cancel goes
  back to the form as it was. This covers creating a programme, camp or
  one-off, Adjust Schedule, editing the organizer or coaches, moving a camp
  or a one-off, reinstating a one-off and rescheduling a session (#278).

## 1.0.0

- Initial version.
