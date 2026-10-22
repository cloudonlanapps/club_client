# Changelog

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
