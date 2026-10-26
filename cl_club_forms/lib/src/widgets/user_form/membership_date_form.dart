import 'package:cl_calendar/cl_calendar.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/form_contract.dart';
import '../form/labeled_form_row.dart';
import 'user_form_assembly.dart';
import 'user_form_fields.dart';
import 'user_form_strings.dart';
import 'user_form_validators.dart';

/// Pure-UI editor for the day a member joined the club, which an admin
/// corrects in the account section of the profile (the extended profile's
/// membership date). One date field, required.
///
/// The form owns no title or buttons: the host drives it through a
/// `GlobalKey<MembershipDateFormState>` ([FormContract]).
class MembershipDateForm extends StatefulWidget {
  const MembershipDateForm({
    required this.initialValue,
    this.enabled = true,
    super.key,
  });

  /// The date the field starts with, or null when none is set.
  final DateTime? initialValue;

  /// Whether the field responds; the host turns it off while it saves.
  final bool enabled;

  @override
  State<MembershipDateForm> createState() => MembershipDateFormState();
}

/// State of [MembershipDateForm]. Its value is
/// `{UserFormFields.membershipDateUtcId: DateTime}`, the picked day at UTC
/// midnight (a date-only value).
class MembershipDateFormState extends State<MembershipDateForm>
    with FormContract<MembershipDateForm> {
  @override
  Map<String, dynamic> assemble(Map<String, dynamic> values) => {
    UserFormFields.membershipDateUtcId: UserFormAssembly.floorToUtcMidnight(
      values[UserFormFields.membershipDateUtcId] as DateTime?,
    ),
  };

  @override
  Widget build(BuildContext context) {
    final initial = widget.initialValue;
    return ShadForm(
      key: formKey,
      initialValue: {UserFormFields.membershipDateUtcId: initial},
      child: FormBody(
        error: formError,
        children: [
          LabeledFormRow(
            label: UserFormStrings.membershipDate,
            required: true,
            field: CLDatePickerFormField(
              id: UserFormFields.membershipDateUtcId,
              initialValue: initial,
              placeholder: const Text(
                UserFormStrings.membershipDatePlaceholder,
              ),
              enabled: widget.enabled,
              formatDate: DateFormat(UserFormStrings.dateFormat).format,
              validator: UserFormValidators.membershipDate,
            ),
          ),
        ],
      ),
    );
  }
}
