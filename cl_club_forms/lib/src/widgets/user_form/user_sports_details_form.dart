import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/profile_position_option.dart';
import '../form/form_body.dart';
import '../form/form_contract.dart';
import 'user_form_assembly.dart';
import 'user_form_fields.dart';
import 'user_sports_details_fields.dart';

/// Pure-UI editor for a member's sports details — club or district,
/// preferred positions and past experience (the "Sports details" section
/// of the extended profile). Every field may be left blank.
///
/// The form owns no title or buttons: the host drives it through a
/// `GlobalKey<UserSportsDetailsFormState>` ([FormContract]).
class UserSportsDetailsForm extends StatefulWidget {
  const UserSportsDetailsForm({
    required this.initialValues,
    required this.positions,
    this.enabled = true,
    super.key,
  });

  /// Initial values; reads the ids of [UserFormFields.sportsDetailsIds].
  final Map<String, dynamic> initialValues;

  /// The club's positions, offered as the preferred-positions checkboxes.
  /// A member's position that is not among them shows ticked and is kept.
  final List<ProfilePositionOption> positions;

  /// Whether the fields respond; the host turns it off while it saves.
  final bool enabled;

  @override
  State<UserSportsDetailsForm> createState() => UserSportsDetailsFormState();
}

/// State of [UserSportsDetailsForm]. Its values are the fields of
/// [UserFormFields.sportsDetailsIds], each text a `String` (`''` when
/// blank) and the preferred positions a `List<String>` (empty for none),
/// for a partial update.
class UserSportsDetailsFormState extends State<UserSportsDetailsForm>
    with FormContract<UserSportsDetailsForm> {
  /// Compares its list field as a set of the ticked values
  /// (`UserFormAssembly.differ`): `ShadForm.value` hands back a copy of a
  /// list, which `mapEquals` would always count as changed.
  @override
  bool get isDirty {
    final form = formKey.currentState;
    return form != null &&
        UserFormAssembly.differ(form.initialValue, form.value);
  }

  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) =>
      UserFormAssembly.pick(UserFormFields.sportsDetailsIds, values);

  @override
  Widget build(BuildContext context) {
    return ShadForm(
      key: formKey,
      initialValue: UserFormAssembly.seed(
        UserFormFields.sportsDetailsIds,
        widget.initialValues,
      ),
      child: FormBody(
        error: formError,
        children: [
          UserSportsDetailsFields(
            positions: widget.positions,
            enabled: widget.enabled,
          ),
        ],
      ),
    );
  }
}
