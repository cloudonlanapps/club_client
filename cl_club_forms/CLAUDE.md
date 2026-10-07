# cl_club_forms — the club's forms

Pure-UI forms: `ShadForm` widgets with their field clusters, validators,
field-id constants and form-local values. No SDK, no Riverpod. A feature
package hosts a form — in a create view, a dialog or an `EditableSectionCard`
— drives it through a `GlobalKey`, and adapts its flat values to the SDK.

The rules for writing a form are in the root [`CLAUDE.md`](../CLAUDE.md)
(*Form Design Guidelines* and *Section-wise Editors*). Coding rules:
[`docs/coding_rules.md`](../docs/coding_rules.md).
`docs/dart-data-class.md` applies to the form-local value classes in
`lib/src/models/`.

## Public surface

`lib/cl_club_forms.dart` names everything it exports, and exports only what
another package's production code uses: the forms, their public states, their
field-id classes, the form-local types a host must construct, and the
validators a host calls. A field cluster or a building block stays in `src/`;
a test that needs one imports it from `package:cl_club_forms/src/...`.
`test/package_boundary_test.dart` checks both.

## Dependencies

| Allowed | Why |
|---|---|
| `flutter`, `shadcn_ui` | the widgets |
| `cl_calendar` | the date pickers (form rule 4) |

**Forbidden: `ui_lib`, and every `cl_*` package.** `cl_club_forms` and
`ui_lib` do not depend on each other; a feature package uses both.
`test/package_boundary_test.dart` checks it in both directions. What a form
needs from the other side it gets one of three ways:

- the host passes it in (a picker callback, an options list);
- it speaks a form-local type and the host maps (`EventStaffMember` for a
  picked user, `FormAge` for an age);
- for something tiny and stable, it keeps its own copy (`ReadOnlyField`,
  `CommonFormValidators`, the *Reset* label, the single-column breakpoint).

Evaluation's four forms are not here: they stay in `ui_lib` with the rest of
evaluation's UI, whose models they share.

## Structure

```
lib/src/
  constants/  - values shared by the forms (breakpoint, common labels).
  models/     - form-local values a form takes or returns.
  widgets/    - one folder per form family: the form, its field cluster,
                field ids, validators and values.
```

Besides the forms, the package carries two things that travel with them:
`TwoColumnGrid`, the layout the schedule forms use, and the read view of an
age band (`AgeEligibilitySummary`, `AgeEligibilityText`), which shares
`FormAge` with the age fields.

## Testing

Widget and unit tests are in `test/`, one file per form or cluster; none
needs a server. `just unit-test cl_club_forms` runs them. The flows that
host these forms are covered by the feature packages' tests and by the UI
integration suite in `cl_club_app/example/integration_test/`.

## Example

`example/` mounts `SignupForm` and `IdentityDocumentsConsentForm` bare, with
a stand-in for the host's buttons: `cd example && flutter run -d chrome`.
