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

## 1.0.0

- Initial version.
