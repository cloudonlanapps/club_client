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
  constants/  - values shared by the forms: FormSpacing (every gap), the
                breakpoint, common labels.
  models/     - form-local values a form takes or returns.
  widgets/    - one folder per form family: the form, its field cluster,
                field ids, validators and values.
                widgets/form/ holds what every form is built from:
                LabeledFormRow, FormBody and the FormContract mixin.
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

## Checking by eye

[`docs/checklist.md`](docs/checklist.md) lists every form and where it shows
in the app, for a visual pass. Add a line when a form is added, and correct
one when a form moves to another screen.

## Example

`example/` is **Club Forms**, a preview of every form of this package, for
checking looks without a server: `cd example && flutter run -d chrome`. A
sidebar lists the forms by family, each variant that looks different as its
own entry; the main view shows the chosen form bare in one card, with made-up
sample data. The top bar holds the demo's only controls: **Validate** (calls
`validate()`, so the form shows its messages), **Reset** (mounts the form
afresh) and the light / dark toggle.

An entry is data (`example/lib/models/form_demo_entry.dart`): a title, a
family, the form's type and a builder that takes the form's key. The entries
are in `example/lib/data/`, one file per family. **A new form gets an entry
there**: `example/test/form_demo_entries_test.dart` reads the barrel and
fails for a form with none, and `example/test/form_preview_test.dart` mounts
every entry at desktop and at phone width.
