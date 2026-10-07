import 'package:flutter/widgets.dart';

import '../../constants/form_spacing.dart';
import '../form/form_body.dart';
import '../form/labeled_form_row.dart';
import 'user_address_fields.dart';
import 'user_contact_fields.dart';
import 'user_emergency_fields.dart';
import 'user_form_strings.dart';

/// What `UserForm` adds below its main rows while editing: the address
/// under its heading, then phone, email, the emergency contact and the
/// medical notes.
class UserEditOnlyFields extends StatelessWidget {
  const UserEditOnlyFields({this.enabled = true, super.key});

  /// Whether the fields respond.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: FormSpacing.sectionGap,
      children: [
        LabeledFormRow(
          label: UserFormStrings.address,
          field: UserAddressFields(enabled: enabled),
        ),
        FormBody(
          children: [
            UserContactFields(enabled: enabled, emailFirst: false),
            UserEmergencyFields(enabled: enabled),
          ],
        ),
      ],
    );
  }
}
