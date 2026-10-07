import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/labeled_form_row.dart';
import 'user_form_fields.dart';
import 'user_form_strings.dart';

/// The roles a created account may be given: one tick per role the host
/// lets the viewer grant.
class UserRoleFields extends StatelessWidget {
  const UserRoleFields({
    this.enabled = true,
    this.canAssignAdmin = false,
    this.canAssignCoach = false,
    super.key,
  });

  /// Whether the ticks respond.
  final bool enabled;

  /// Whether the admin tick shows.
  final bool canAssignAdmin;

  /// Whether the coach tick shows.
  final bool canAssignCoach;

  @override
  Widget build(BuildContext context) {
    return LabeledFormRow(
      label: UserFormStrings.roles,
      field: FormBody(
        children: [
          if (canAssignAdmin)
            ShadCheckboxFormField(
              id: UserFormFields.assignAdminId,
              initialValue: false,
              inputLabel: const Text(UserFormStrings.assignAdmin),
              enabled: enabled,
            ),
          if (canAssignCoach)
            ShadCheckboxFormField(
              id: UserFormFields.assignCoachId,
              initialValue: false,
              inputLabel: const Text(UserFormStrings.assignCoach),
              enabled: enabled,
            ),
        ],
      ),
    );
  }
}
