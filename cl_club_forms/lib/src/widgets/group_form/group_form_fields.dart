/// Form-local field IDs and value types shared by the group forms
/// (`GroupCreateForm`, `GroupEligibilityForm`) and the internal
/// `GroupEligibilityFields` cluster.
///
/// All SDK-free: the caller's adapter (`cl_club_members` `group_form_helpers`)
/// maps these to/from the `club_sdk_2` `Group`, `Gender`, and `GroupKind`.
class GroupFormFields {
  const GroupFormFields._();

  static const String nameId = 'name';
  static const String descriptionId = 'description';
  static const String modeId = 'mode';

  /// Gender criterion, a [GroupGender]. The age band's inputs are the shared
  /// cluster's (`AgeEligibilityFormFields`).
  static const String genderId = 'gender';

  /// Create-only: "Add me into the group" switch. When true, the caller
  /// enrolls the current user after the group is created (issue #175).
  static const String addMeId = 'addMe';
}

/// Membership mode of a group — the explicit choice the user makes, mapped to
/// the SDK's `GroupKind` by the caller's adapter.
///
/// - [manual]: members are added by hand; no eligibility criteria.
/// - [semiAuto]: criteria compute membership, but manual additions are also
///   allowed on top.
/// - [auto]: membership is fully computed from criteria.
enum GroupMode {
  manual,
  semiAuto,
  auto;

  String get label => switch (this) {
    GroupMode.manual => 'Manual',
    GroupMode.semiAuto => 'Semi-auto',
    GroupMode.auto => 'Auto',
  };

  /// Whether this mode is driven by eligibility criteria (age / gender).
  bool get usesCriteria => this != GroupMode.manual;
}

/// Who an auto / semi-auto group is for, by gender: anyone, boys or girls.
/// The form's Gender always holds one of these; [any] is no gender criterion.
/// The adapter maps them to and from the SDK `Gender`.
enum GroupGender {
  /// No gender criterion.
  any,

  /// Only boys.
  boys,

  /// Only girls.
  girls;

  /// The entry's text in the Gender field.
  String get label => switch (this) {
    GroupGender.any => 'Any',
    GroupGender.boys => 'Boys',
    GroupGender.girls => 'Girls',
  };

  /// Whether this is a criterion of the group; false for [any].
  bool get isCriterion => this != GroupGender.any;

  /// The gender [values] hold under [GroupFormFields.genderId]; [any] when
  /// they hold none.
  static GroupGender of(Map<String, dynamic> values) =>
      values[GroupFormFields.genderId] as GroupGender? ?? GroupGender.any;
}
