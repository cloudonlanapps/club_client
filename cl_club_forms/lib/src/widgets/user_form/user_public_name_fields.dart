import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../read_only_field.dart';
import 'user_form_fields.dart';
import 'user_form_strings.dart';

/// Whether a user's name, and a coach's profile, show publicly. Sits inside
/// the embedding form's `ShadForm`, which holds the initial values.
///
/// - A coach on their own profile ([canEditPublicProfile]): a public-profile
///   tick and a public-name tick, the latter off and disabled while the
///   profile is not public.
/// - A super-admin ([canEditUseNamePublicly]): the public-name tick alone.
/// - Anyone else: the public-name flag, read-only.
class UserPublicNameFields extends StatefulWidget {
  const UserPublicNameFields({
    this.enabled = true,
    this.canEditUseNamePublicly = false,
    this.canEditPublicProfile = false,
    super.key,
  });

  /// Whether the ticks respond.
  final bool enabled;

  /// Whether the public-name flag is a field.
  final bool canEditUseNamePublicly;

  /// Whether the coach-owned pair of ticks shows.
  final bool canEditPublicProfile;

  /// The public-name flag of [values]: a name is public only on a public
  /// profile when [canEditPublicProfile] ties the two.
  static bool useNamePublicly(
    Map<String, dynamic> values, {
    required bool canEditPublicProfile,
  }) {
    final ticked = values[UserFormFields.useNamePubliclyId] as bool? ?? false;
    if (!canEditPublicProfile) return ticked;
    return ticked &&
        (values[UserFormFields.isPublicProfileId] as bool? ?? false);
  }

  @override
  State<UserPublicNameFields> createState() => UserPublicNameFieldsState();
}

/// State of [UserPublicNameFields]: follows the public-profile tick, which
/// decides whether the public-name tick responds.
class UserPublicNameFieldsState extends State<UserPublicNameFields> {
  /// Whether the profile is ticked public.
  late bool isPublicProfile =
      ShadForm.of(context).initialValue[UserFormFields.isPublicProfileId]
          as bool? ??
      false;

  @override
  Widget build(BuildContext context) {
    final initial = ShadForm.of(context).initialValue;
    final initialUseName =
        initial[UserFormFields.useNamePubliclyId] as bool? ?? false;
    final public = isPublicProfile;

    if (widget.canEditPublicProfile) {
      return FormBody(
        children: [
          ShadCheckboxFormField(
            id: UserFormFields.isPublicProfileId,
            initialValue: public,
            enabled: widget.enabled,
            onChanged: (value) => setState(() => isPublicProfile = value),
            inputLabel: const Text(UserFormStrings.isPublicProfile),
          ),
          ShadCheckboxFormField(
            // A new key per state of the tick above, so the field starts
            // again unticked (and disabled) when the profile is made
            // non-public.
            key: ValueKey('${UserFormFields.useNamePubliclyId}-$public'),
            id: UserFormFields.useNamePubliclyId,
            enabled: widget.enabled && public,
            initialValue: public && initialUseName,
            inputLabel: const Text(UserFormStrings.useMyNamePublicly),
          ),
        ],
      );
    }
    if (widget.canEditUseNamePublicly) {
      return ShadCheckboxFormField(
        id: UserFormFields.useNamePubliclyId,
        initialValue: initialUseName,
        enabled: widget.enabled,
        inputLabel: const Text(UserFormStrings.useNamePublicly),
      );
    }
    return ReadOnlyField(
      label: UserFormStrings.useNamePublicly,
      value: initialUseName ? UserFormStrings.yes : UserFormStrings.no,
    );
  }
}
