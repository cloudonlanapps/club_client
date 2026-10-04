import 'package:cl_remote_store/cl_remote_store.dart'
    show ClGroupsMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:ui_lib/ui_lib.dart'
    show GroupFormFields, GroupGender, GroupMode;

/// SDK adapter for the group forms — the one place that bridges the forms'
/// flat `Map<String, dynamic>` (keyed by `GroupFormFields`, with form-local
/// `GroupMode` / `GroupGender` values) to the `cl_remote_store` create/update
/// calls. The form widgets in `ui_lib` are SDK-free; this helper owns the
/// translation. Mirrors `user_form_helpers.dart` / `venue_form_helpers.dart`.

/// SDK [Gender] → form-local [GroupGender].
GroupGender? _genderToForm(Gender? g) => switch (g) {
  Gender.male => GroupGender.male,
  Gender.female => GroupGender.female,
  Gender.other => GroupGender.other,
  Gender.preferNotToSay => GroupGender.preferNotToSay,
  null => null,
};

/// Form-local [GroupGender] → SDK [Gender].
Gender? _genderToSdk(GroupGender? g) => switch (g) {
  GroupGender.male => Gender.male,
  GroupGender.female => Gender.female,
  GroupGender.other => Gender.other,
  GroupGender.preferNotToSay => Gender.preferNotToSay,
  null => null,
};

/// SDK [GroupKind] → form-local [GroupMode].
GroupMode _modeFromKind(GroupKind kind) => switch (kind) {
  GroupKind.manual => GroupMode.manual,
  GroupKind.semiAuto => GroupMode.semiAuto,
  GroupKind.auto => GroupMode.auto,
};

String? _nullIfEmpty(Object? v) {
  final s = (v as String?)?.trim();
  return (s == null || s.isEmpty) ? null : s;
}

DateTime? _floorToUtcMidnight(DateTime? d) {
  if (d == null) return null;
  return DateTime.utc(d.year, d.month, d.day);
}

/// Resolved eligibility values for a submit, derived from the form's mode.
/// In manual mode all criteria are cleared and `semiAuto` is left unset.
({DateTime? after, DateTime? before, Gender? gender, bool? semiAuto})
_resolveCriteria(Map<String, dynamic> values) {
  final mode = values[GroupFormFields.modeId] as GroupMode? ?? GroupMode.manual;
  if (mode == GroupMode.manual) {
    return (after: null, before: null, gender: null, semiAuto: null);
  }
  return (
    after: _floorToUtcMidnight(
      values[GroupFormFields.dobOnOrAfterId] as DateTime?,
    ),
    before: _floorToUtcMidnight(
      values[GroupFormFields.dobOnOrBeforeId] as DateTime?,
    ),
    gender: _genderToSdk(values[GroupFormFields.genderId] as GroupGender?),
    semiAuto: mode == GroupMode.semiAuto,
  );
}

/// Builds initial form values from an existing [Group] (null = create mode).
Map<String, dynamic> buildGroupFormInitialValues(Group? group) {
  if (group == null) {
    return {
      GroupFormFields.nameId: '',
      GroupFormFields.descriptionId: '',
      GroupFormFields.modeId: GroupMode.manual,
      GroupFormFields.addMeId: false,
    };
  }
  return {
    GroupFormFields.nameId: group.name,
    GroupFormFields.descriptionId: group.description ?? '',
    GroupFormFields.modeId: _modeFromKind(group.kind),
    GroupFormFields.dobOnOrAfterId: group.dobOnOrAfterUtc,
    GroupFormFields.dobOnOrBeforeId: group.dobOnOrBeforeUtc,
    GroupFormFields.genderId: _genderToForm(group.gender),
  };
}

/// Bridges group form values to the SDK create/update calls.
class GroupFormSubmit {
  const GroupFormSubmit._();

  /// Create a new group from the create form's values.
  static Future<Group> create({
    required Map<String, dynamic> values,
    required ClGroupsMasterNotifier notifier,
  }) {
    final c = _resolveCriteria(values);
    return notifier.createGroup(
      name: (values[GroupFormFields.nameId] as String).trim(),
      description: _nullIfEmpty(values[GroupFormFields.descriptionId]),
      dobOnOrAfterUtc: c.after,
      dobOnOrBeforeUtc: c.before,
      gender: c.gender,
      semiAuto: c.semiAuto,
    );
  }

  /// Update an existing group's mode + criteria from the eligibility editor's
  /// values. Name / description are only sent when present in [values].
  static Future<Group> updateEligibility({
    required Map<String, dynamic> values,
    required int groupId,
    required ClGroupsMasterNotifier notifier,
  }) {
    final c = _resolveCriteria(values);
    final hasName = values.containsKey(GroupFormFields.nameId);
    final hasDescription = values.containsKey(GroupFormFields.descriptionId);
    return notifier.updateGroup(
      groupId,
      name: hasName ? (values[GroupFormFields.nameId] as String).trim() : null,
      description: hasDescription
          ? () => _nullIfEmpty(values[GroupFormFields.descriptionId])
          : null,
      dobOnOrAfterUtc: () => c.after,
      dobOnOrBeforeUtc: () => c.before,
      gender: () => c.gender,
      semiAuto: c.semiAuto,
    );
  }
}
