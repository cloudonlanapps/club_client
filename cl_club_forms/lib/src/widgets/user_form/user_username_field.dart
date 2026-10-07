import 'package:flutter/widgets.dart';

import '../form/labeled_form_row.dart';
import '../signup/username_availability_field.dart';
import 'user_form_strings.dart';
import 'user_form_validators.dart';

/// The username of a new account with its availability check, shared by
/// the forms that create one. The embedding form's state mixes in
/// `UsernameConfirmation` and passes its `onAvailabilityChanged`.
class UserUsernameField extends StatelessWidget {
  const UserUsernameField({
    required this.onAvailabilityChanged,
    required this.checkAvailability,
    this.enabled = true,
    super.key,
  });

  /// Hears the username as typed and, after a successful check, the same
  /// username as confirmed.
  final void Function(String username, String? confirmedUsername)
  onAvailabilityChanged;

  /// Resolves to true when the username is free.
  final Future<bool> Function(String username) checkAvailability;

  /// Whether the field responds.
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    return LabeledFormRow(
      label: UserFormStrings.username,
      required: true,
      field: UsernameAvailabilityField(
        placeholder: const Text(UserFormStrings.usernamePlaceholder),
        autofocus: true,
        enabled: enabled,
        validator: UserFormValidators.username,
        onAvailabilityChanged: onAvailabilityChanged,
        checkAvailability: checkAvailability,
      ),
    );
  }
}
