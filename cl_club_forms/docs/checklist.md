# Forms checklist — where each form shows in the app

For checking the forms by eye in the running app. Each line names a form and
where it appears. Taken from where the forms are mounted in the code and from
the app's routes (2026-10-07).

## Seeing a form without the app

`example/` is **Club Forms**, a preview of every form in this list, for
checking looks without a server or a login:

```bash
cd cl_club_forms/example && flutter run -d chrome
```

Pick a form in the sidebar (variants such as the three event types or signing
up and reapplying are separate entries); it shows bare in one card, with
made-up sample data. The top bar has **Validate**, which shows the form's
messages, **Reset**, which mounts it afresh, and the light / dark toggle.

## On every form

- [ ] Labels sit above their fields, and required fields end in " *".
- [ ] The gap between rows looks the same from form to form.
- [ ] The form itself has no title and no Save/Cancel; those belong to the page, card or dialog around it.
- [ ] Pressing Save on an invalid form puts messages on the fields, or one message under the fields for a rule across them.
- [ ] A value the server refuses (duplicate username or email, wrong current password, venue not found) shows on its field, not as a toast.

## Account (signed out)

- [ ] Login form: shown on the sign-in page (`/auth/login`), with the Sign in button, "Forgot password?" and "Sign up" drawn by the page.
- [ ] Forgot password form: shown on `/auth/forgot-password`, reached from "Forgot password?" on the sign-in page.
- [ ] Signup form: shown on `/auth/signup`, reached from "Sign up" on the sign-in page.

## Onboarding (signed in, not yet approved)

- [ ] Signup form, reapply mode: shown on `/onboarding/welcome` when an admin has sent the application back with a note (username fixed, the note shown above the form).
- [ ] Identity documents uploader (not a form, lives in `ui_lib`): shown on `/onboarding/submit-documents`; each file saves as it is added or removed.
- [ ] Identity documents consent form: shown on the same page, under the uploader ("I agree to the Privacy Policy"); Submit is disabled until a document is there, and asks for the tick when pressed without it.

## Own profile

- [ ] Change password form: shown on the member's own profile page (`/memberzone/profile`) when "Change password" is opened.

## Members (admin)

- [ ] User form: shown on `/memberzone/users/new`, reached from the Members list with "Create user".
- [ ] User personal details form: shown on a member's profile (`/memberzone/users/:username`) when the pencil on the Personal details card is pressed.
- [ ] User contact form: shown on a member's profile when the pencil on the Contact card is pressed.
- [ ] User address form: shown on a member's profile when the pencil on the Address card is pressed.

## Groups (admin)

- [ ] Group create form: shown on `/memberzone/groups/new`, reached from the Groups list.
- [ ] Group eligibility form: shown on a group's page (`/memberzone/groups/:id`) when the pencil on the Membership / Eligibility section is pressed.
- [ ] Rename form (group): shown in a dialog when Rename is pressed on a group's page.

## Venues (admin)

- [ ] Venue create form: shown on `/memberzone/venues/new`, reached from the Venues list.
- [ ] Location edit form: shown on a venue's page (`/memberzone/venues/:id`) when the pencil on the Location card is pressed.
- [ ] Rename form (venue): shown in a dialog when Rename is pressed on a venue's page.

## Events (admin or organizer)

- [ ] Event create form, camp: shown on `/memberzone/events/camps/new`.
- [ ] Event create form, programme: shown on `/memberzone/events/programmes/new`.
- [ ] Event create form, one-off: shown on `/memberzone/events/one-off/new`.
- [ ] Event eligibility form: shown on an event's page (`/memberzone/events/:eventId`) when the pencil on the Eligibility card is pressed.
- [ ] Event staff form: shown on an event's page when the pencil on "Organizer & Coaches" is pressed (Transfer, Add coaches, Undo).
- [ ] Camp schedule form: shown on a camp's page when the pencil on its Schedule section is pressed.
- [ ] One-off schedule form: shown on a one-off's page when the pencil on its Schedule section is pressed.
- [ ] Event timetable form: shown on an event's page when the pencil on the Timetable (sessions) section is pressed.
- [ ] Programme schedule adjust form: shown in a dialog from "Adjust schedule" in a programme's Schedule block.
- [ ] Programme end date form: shown in a dialog from the end date action in a programme's Schedule block.
- [ ] Occurrence reschedule form: shown in a dialog from "Reschedule" on a single occurrence (a camp day) in the occurrence list.
- [ ] Event cancellation form: shown in a dialog from "Cancel camp" or "Call off" in Event Management on an event's page.
- [ ] Rename form (event): shown in a dialog from Rename in Event Management on an event's page.

## Credit (admin, credit system on)

- [ ] Credit grant form: shown inside the credit sheet (opened from a member's credit chip) under "Add credit"; and alone in a dialog from the "+" chip in Assign Users or Assign Trial.
- [ ] Credit extend form: shown inside the credit sheet when Extend is pressed on a credit package.
- [ ] Credit reverse form: shown inside the credit sheet when Reverse is pressed on a credit package.
- [ ] Credit transfer form: shown inside the credit sheet when Transfer is pressed on a programme's credit package.

## Club details (admin)

- [ ] Club details form: shown on `/memberzone/club-details` when the pencil on the Club card is pressed.
- [ ] Club contact form: shown on the same page when the pencil on the Contact card is pressed.
- [ ] Club address form: shown on the same page when the pencil on the Address card is pressed.
- [ ] Club language form: always shown in the Translations card at the bottom of the same page, with the "Add language" button; a language added there appears as an extra input in the three forms above.

## Evaluations (these stay in `ui_lib`)

- [ ] Evaluation start form: shown in a dialog from the Reviews page (`/memberzone/reviews`), from Evaluate on an event's enrolment list, and from the review section of a member's profile.
- [ ] Evaluation template create form: shown on the new-template page under `/memberzone/reviews/templates`.
- [ ] Evaluation item form: shown in a dialog when a question is added or edited in a template.
- [ ] Rename form (template name, section title): shown in a dialog from a template's page.
- [ ] Evaluation period form: shown on a review's page (`/memberzone/reviews/:id`) when the pencil on the Review Period card is pressed.
- [ ] Evaluation fill body (not a form): the questions on a draft review's page; each answer saves as it changes.
