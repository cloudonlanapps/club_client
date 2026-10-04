7 My Events 


  ┌─────┬──────────────────────────────────┬─────────────────────────────┬────────────────────────────┐
  │  #  │             Endpoint             │        SDK Function         │      Provider Method       │
  ├─────┼──────────────────────────────────┼─────────────────────────────┼────────────────────────────┤
  │ 1   │ GET /myevents/{user}             │ listMyEvents(username, ...) │ build() (on init)          │
  ├─────┼──────────────────────────────────┼─────────────────────────────┼────────────────────────────┤
  │ 2   │ GET /myevents/{user}/{id}        │ getMyEvent(username,        │ getMyEvent(eventId)        │
  │     │                                  │ eventId)                    │                            │
  ├─────┼──────────────────────────────────┼─────────────────────────────┼────────────────────────────┤
  │ 3   │ GET /myevents/{user}/{id}/chain  │ getMyEventChain(username,   │ getMyEventChain(eventId)   │
  │     │                                  │ eventId)                    │                            │
  ├─────┼──────────────────────────────────┼─────────────────────────────┼────────────────────────────┤
  │ 4   │ GET /myevents/{user}/{id}/enroll │ getMyEnrollment(username,   │ getMyEnrollment(eventId)   │
  │     │ ments                            │ eventId)                    │                            │
  ├─────┼──────────────────────────────────┼─────────────────────────────┼────────────────────────────┤
  │ 5   │ GET /myevents/{user}/occurrences │ listMyOccurrences(username, │ listMyOccurrences(...)     │
  │     │                                  │  ...)                       │                            │
  ├─────┼──────────────────────────────────┼─────────────────────────────┼────────────────────────────┤
  │ 6   │ GET /myevents/{user}/attendance  │ listMyAttendance(username,  │ listMyAttendance(...)      │
  │     │                                  │ ...)                        │                            │
  ├─────┼──────────────────────────────────┼─────────────────────────────┼────────────────────────────┤
  │ 7   │ GET                              │ getMyOccurrence(username,   │ getMyOccurrence(eventId,   │
  │     │ /myevents/{user}/{id}/occ/{occ}  │ eventId, occTimeUtc)        │ occTimeUtc)                │
  ├─────┼──────────────────────────────────┼─────────────────────────────┼────────────────────────────┤
  │     │ GET /myevents/{user}/{id}/occ/{o │ getMyOccurrenceAttendance(u │ getMyOccurrenceAttendance( │
  │ 8   │ cc}/attendance                   │ sername, eventId,           │ eventId, occTimeUtc)       │
  │     │                                  │ occTimeUtc)                 │                            │
  ├─────┼──────────────────────────────────┼─────────────────────────────┼────────────────────────────┤
  │ 9   │ POST .../enrollments/accept      │ acceptInvite(username,      │ acceptInvite(eventId)      │
  │     │                                  │ eventId)                    │                            │
  ├─────┼──────────────────────────────────┼─────────────────────────────┼────────────────────────────┤
  │ 10  │ POST .../enrollments/decline     │ declineInvite(username,     │ declineInvite(eventId)     │
  │     │                                  │ eventId)                    │                            │
  ├─────┼──────────────────────────────────┼─────────────────────────────┼────────────────────────────┤
  │ 11  │ POST .../enrollments/request     │ requestToJoin(username,     │ requestToJoin(eventId)     │
  │     │                                  │ eventId)                    │                            │
  ├─────┼──────────────────────────────────┼─────────────────────────────┼────────────────────────────┤
  │ 12  │ POST .../enrollments/withdraw    │ withdraw(username, eventId, │ withdraw(eventId, ...)     │
  │     │                                  │  ...)                       │                            │
  ├─────┼──────────────────────────────────┼─────────────────────────────┼────────────────────────────┤
  │ 13  │ POST                             │ cancelWithdrawRequest(usern │ cancelWithdrawRequest(even │
  │     │ .../enrollments/cancel-withdraw  │ ame, eventId)               │ tId)                       │
  ├─────┼──────────────────────────────────┼─────────────────────────────┼────────────────────────────┤
  │ 14  │ POST .../occ/{occ}/leave/request │ requestLeave(username,      │ requestLeave(eventId,      │
  │     │                                  │ eventId, occTimeUtc, ...)   │ occTimeUtc, ...)           │
  ├─────┼──────────────────────────────────┼─────────────────────────────┼────────────────────────────┤
  │ 15  │ POST .../occ/{occ}/leave/cancel  │ cancelLeaveRequest(username │ cancelLeaveRequest(eventId │
  │     │                                  │ , eventId, occTimeUtc)      │ , occTimeUtc)              │
  └─────┴──────────────────────────────────┴─────────────────────────────┴────────────────────────────┘
