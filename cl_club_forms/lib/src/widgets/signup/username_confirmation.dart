import 'package:flutter/widgets.dart';

import '../form/form_contract.dart';
import '../user_form/user_form_validators.dart';

/// What a form that asks for a new username keeps about its availability:
/// the form may be submitted only once the embedded
/// `UsernameAvailabilityField` has confirmed the username as typed.
///
/// The form's state mixes this in after [FormContract], passes
/// [onAvailabilityChanged] to the field, and adds [usernameProblem] to its
/// `crossFieldError`. The host hears [canSubmit] change through
/// [canSubmitListener] and gates its submit action on it.
mixin UsernameConfirmation<T extends StatefulWidget>
    on State<T>, FormContract<T> {
  /// Latest username the field reported.
  String currentUsername = '';

  /// The username the availability check confirmed; null until a check
  /// succeeds, and again once the username is edited.
  String? confirmedAvailableUsername;

  /// Whether this form asks for a username at all; a form that shows a
  /// fixed one does not.
  bool get asksForUsername;

  /// Hears [canSubmit] when it changes, and once after the first frame.
  ValueChanged<bool>? get canSubmitListener;

  /// Whether the form may be submitted: it asks for no username, or the
  /// one typed is confirmed available.
  bool get canSubmit =>
      !asksForUsername ||
      (currentUsername.isNotEmpty &&
          confirmedAvailableUsername == currentUsername);

  /// The message for a username not confirmed available, or null.
  String? usernameProblem() =>
      canSubmit ? null : UserFormValidators.availabilityCheckRequired;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) canSubmitListener?.call(canSubmit);
    });
  }

  /// Records what the availability field reports: the username as typed
  /// and, after a successful check, the same username as [confirmed].
  void onAvailabilityChanged(String username, String? confirmed) {
    if (!mounted) return;
    final before = canSubmit;
    setState(() {
      currentUsername = username;
      confirmedAvailableUsername = confirmed;
    });
    if (formError == UserFormValidators.availabilityCheckRequired) {
      setFormError(null);
    }
    if (canSubmit != before) canSubmitListener?.call(canSubmit);
  }
}
