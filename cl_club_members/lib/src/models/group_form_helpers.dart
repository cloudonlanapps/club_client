import 'package:cl_club_forms/cl_club_forms.dart'
    show
        AgeEligibilityFormValues,
        GenderEligibilityFormFields,
        GenderEligibilityFormValues,
        GroupFormFields,
        GroupMode;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        ClGroupsMasterNotifier,
        ageSchemaFieldIds,
        formAgeFromSdk,
        formGendersFromSdk,
        schemaFieldErrors,
        sdkAgeFromForm,
        sdkGendersFromForm;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/foundation.dart' show setEquals;

/// SDK adapter for the group forms — the one place that bridges the forms'
/// flat `Map<String, dynamic>` (keyed by `GroupFormFields` and the shared
/// eligibility clusters' ids) to the `cl_remote_store` create/update
/// calls. The form widgets in `cl_club_forms` are SDK-free; this helper owns
/// the translation. Mirrors `user_form_helpers.dart` / `venue_form_helpers.dart`.

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

/// Resolved eligibility values for a submit, derived from the form's mode.
/// In manual mode all criteria are cleared (no genders, the age check
/// relaxed again) and `semiAuto` is left unset. No dates are sent: the
/// server works the window out from the ages.
({
  Age? minAge,
  Age? maxAge,
  bool strictAge,
  List<Gender> genders,
  bool? semiAuto,
})
_resolveCriteria(Map<String, dynamic> values) {
  final mode = values[GroupFormFields.modeId] as GroupMode? ?? GroupMode.manual;
  if (mode == GroupMode.manual) {
    return (
      minAge: null,
      maxAge: null,
      strictAge: false,
      genders: const [],
      semiAuto: null,
    );
  }
  return (
    minAge: sdkAgeFromForm(AgeEligibilityFormValues.minAge(values)),
    maxAge: sdkAgeFromForm(AgeEligibilityFormValues.maxAge(values)),
    strictAge: AgeEligibilityFormValues.strictAge(values),
    genders: sdkGendersFromForm(
      GenderEligibilityFormValues.genders(values),
    ),
    semiAuto: mode == GroupMode.semiAuto,
  );
}

/// Builds initial form values from an existing [Group] (null = create mode).
/// A group with no gender criterion holds no ticked gender.
Map<String, dynamic> buildGroupFormInitialValues(Group? group) {
  if (group == null) {
    return {
      GroupFormFields.nameId: '',
      GroupFormFields.descriptionId: '',
      GroupFormFields.modeId: GroupMode.manual,
      ...GenderEligibilityFormValues.initial(),
      GroupFormFields.addMeId: false,
      ...AgeEligibilityFormValues.initial(),
    };
  }
  return {
    GroupFormFields.nameId: group.name,
    GroupFormFields.descriptionId: group.description ?? '',
    GroupFormFields.modeId: _modeFromKind(group.kind),
    ...AgeEligibilityFormValues.initial(
      minAge: formAgeFromSdk(group.minAge),
      maxAge: formAgeFromSdk(group.maxAge),
      strictAge: group.strictAge,
    ),
    ...GenderEligibilityFormValues.initial(formGendersFromSdk(group.genders)),
  };
}

/// What a refused write says to a group form, in the shape of the form's
/// `showErrors`: a message per field id, and the form-level message.
typedef GroupFormRefusal = ({
  Map<String, String> fieldErrors,
  String? formError,
});

/// Bridges group form values to the SDK create/update calls, and the
/// server's refusals back to the forms.
class GroupFormSubmit {
  const GroupFormSubmit._();

  /// Shown inline when the server refuses a minimum age above the maximum.
  static const String invertedBandMessage =
      'Minimum age must not be greater than maximum age.';

  /// Shown on the mode when the server refuses a switch to auto while the
  /// group has members.
  static const String membersExistMessage =
      'This group still has members. Remove them before switching to auto.';

  /// The server's name for a group's name.
  static const String serverName = 'name';

  /// The server's name for a group's description.
  static const String serverDescription = 'description';

  /// The server's name for a group's gender criterion, a list of genders.
  static const String serverGenders = 'genders';

  /// The server's name for the flag that tells semi-auto from auto.
  static const String serverSemiAuto = 'semiAuto';

  /// The fields of a group, as the server names them in a schema rejection
  /// (club_client#114), each with the id of the form field that holds it.
  static const Map<String, String> schemaFieldIds = {
    serverName: GroupFormFields.nameId,
    serverDescription: GroupFormFields.descriptionId,
    serverGenders: GenderEligibilityFormFields.gendersId,
    serverSemiAuto: GroupFormFields.modeId,
    ...ageSchemaFieldIds,
  };

  /// What a group form shows for a schema rejection: each refused field it
  /// holds, or `null` when [error] names none.
  static GroupFormRefusal? schemaRefusal(Object error) {
    final fieldErrors = schemaFieldErrors(error, schemaFieldIds);
    return fieldErrors.isEmpty
        ? null
        : (fieldErrors: fieldErrors, formError: null);
  }

  /// What the rename dialog shows on the name for a rename that failed with
  /// [error]: the server's reason when its schema rejects the name, else
  /// [fallback].
  static String renameRefusal(Object error, {required String fallback}) =>
      schemaFieldErrors(error, const {serverName: serverName})[serverName] ??
      fallback;

  /// What the create form shows for [error], or `null` when the refusal
  /// names nothing the form holds (the host then reports a failed create).
  static GroupFormRefusal? createRefusal(Object error) {
    if (error is! ServerException) return null;
    return switch (error.code) {
      SdkErrorCode.invalidState => (
        fieldErrors: const {},
        formError: invertedBandMessage,
      ),
      _ => schemaRefusal(error),
    };
  }

  /// What the eligibility editor shows for [error], or `null` when the
  /// refusal names nothing the form holds (the host then reports a failed
  /// save).
  static GroupFormRefusal? eligibilityRefusal(Object error) {
    if (error is! ServerException) return null;
    return switch (error.code) {
      SdkErrorCode.membersExist => (
        fieldErrors: const {GroupFormFields.modeId: membersExistMessage},
        formError: null,
      ),
      SdkErrorCode.membersIneligible => (
        fieldErrors: const {},
        formError: membersIneligibleMessage(error),
      ),
      SdkErrorCode.invalidState => (
        fieldErrors: const {},
        formError: invertedBandMessage,
      ),
      _ => schemaRefusal(error),
    };
  }

  /// Names the members the new criteria would leave out, from the refusal's
  /// `membernames`.
  static String membersIneligibleMessage(ServerException error) {
    final names =
        (error.details?['membernames'] as List?)
            ?.map((n) => n.toString())
            .toList() ??
        const <String>[];
    final namesText = names.isEmpty ? 'some members' : names.join(', ');
    return "These members don't meet the new criteria: $namesText. "
        'Remove or update them, then retry.';
  }

  /// Create a new group from the create form's values.
  static Future<Group> create({
    required Map<String, dynamic> values,
    required ClGroupsMasterNotifier notifier,
  }) {
    final c = _resolveCriteria(values);
    return notifier.createGroup(
      name: (values[GroupFormFields.nameId] as String).trim(),
      description: _nullIfEmpty(values[GroupFormFields.descriptionId]),
      minAge: c.minAge,
      maxAge: c.maxAge,
      strictAge: c.strictAge,
      genders: c.genders.isEmpty ? null : c.genders,
      semiAuto: c.semiAuto,
    );
  }

  /// Update [group]'s mode + criteria from the eligibility editor's values.
  /// Name / description are only sent when present in [values].
  ///
  /// The genders are sent only when they differ from [group]'s: a save that
  /// leaves the boxes alone does not send them. None ticked, or a Manual
  /// group, is sent as an empty list, which clears the criterion.
  static Future<Group> updateEligibility({
    required Map<String, dynamic> values,
    required Group group,
    required ClGroupsMasterNotifier notifier,
  }) {
    final c = _resolveCriteria(values);
    final keepsGenders = setEquals(c.genders.toSet(), group.genders.toSet());
    final hasName = values.containsKey(GroupFormFields.nameId);
    final hasDescription = values.containsKey(GroupFormFields.descriptionId);
    return notifier.updateGroup(
      group.id,
      name: hasName ? (values[GroupFormFields.nameId] as String).trim() : null,
      description: hasDescription
          ? () => _nullIfEmpty(values[GroupFormFields.descriptionId])
          : null,
      minAge: () => c.minAge,
      maxAge: () => c.maxAge,
      strictAge: c.strictAge,
      genders: keepsGenders ? null : () => c.genders,
      semiAuto: c.semiAuto,
    );
  }
}
