import 'package:cl_club_forms/cl_club_forms.dart'
    show UserPersonalDetailsForm, UserPersonalDetailsFormState;
import 'package:cl_club_members/src/models/user_form_helpers.dart'
    show UserFormSubmit, buildUserFormInitialValues;
import 'package:cl_club_members/src/utils/apply_user_update.dart';
import 'package:cl_club_members/src/utils/profile_detail_rows.dart';
import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:cl_server_config/cl_server_config.dart' show DateTimeFormat;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show EditableSectionCard;

// ── User-profile section editors ───────────────────────────────────────────
// Each section edits in place (see [EditableSectionCard]). Shared by the admin
// profile and the self profile. Date of birth and gender are editable only by
// a super-admin; the form gates them and the partial update omits keys it
// wasn't allowed to change.

/// Personal-details profile section — name, date of birth, gender. Edits in
/// place; date of birth / gender / public-name flag are editable only by a
/// super-admin.
class PersonalDetailsCard extends ConsumerStatefulWidget {
  const PersonalDetailsCard({
    required this.user,
    required this.canEdit,
    super.key,
  });

  final UserPrivate user;
  final bool canEdit;

  @override
  ConsumerState<PersonalDetailsCard> createState() =>
      PersonalDetailsCardState();
}

/// State of [PersonalDetailsCard]: the key of its form.
class PersonalDetailsCardState extends ConsumerState<PersonalDetailsCard> {
  /// Drives the hosted form.
  final formKey = GlobalKey<UserPersonalDetailsFormState>();

  /// Shows what the server refuses about a field on that field. Returns
  /// whether [error] named one.
  bool showRefusedFields(ServerException error) {
    final fieldErrors = UserFormSubmit.personalDetailsFieldErrors(error);
    if (fieldErrors.isEmpty) return false;
    formKey.currentState?.showErrors(fieldErrors: fieldErrors);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final viewer = ref.watch(authStateProvider).valueOrNull;
    final isSuperAdmin = viewer?.isSuperAdmin ?? false;
    // Public-profile visibility is the coach's own to set: only when the
    // viewer is this user and they hold the coach role. Admins can't override.
    final canEditPublicProfile =
        viewer != null &&
        viewer.username == user.username &&
        user.roles.isCoach;
    final rows = <Widget?>[
      profileDetailRow(context, LucideIcons.idCard, 'Name', user.displayName),
      if (user.dateOfBirthUtc != null)
        profileDetailRow(
          context,
          LucideIcons.cake,
          'Date of Birth',
          user.dateOfBirthUtc!.toLocalDateMedium(),
        ),
      if (user.gender != null)
        profileDetailRow(
          context,
          LucideIcons.user,
          'Gender',
          user.gender!.label,
        ),
    ];
    return EditableSectionCard<Map<String, dynamic>>(
      title: 'Personal details',
      canEdit: widget.canEdit,
      isEmpty: rows.whereType<Widget>().isEmpty,
      emptyHint: 'Tap to add personal details',
      editMaxWidth: 460,
      read: profileSectionRows(rows),
      editBuilder: ({required enabled}) => UserPersonalDetailsForm(
        key: formKey,
        initialValues: buildUserFormInitialValues(user),
        enabled: enabled,
        canEditDateOfBirth: isSuperAdmin,
        canEditGender: isSuperAdmin,
        canEditUseNamePublicly: isSuperAdmin,
        canEditPublicProfile: canEditPublicProfile,
      ),
      onValidate: () => formKey.currentState?.validate(),
      isDirty: () => formKey.currentState?.isDirty ?? false,
      onSave: (values) => applyUserUpdate(
        ref,
        context,
        user.username,
        (notifier) => UserFormSubmit.updatePersonalDetails(
          values: values,
          username: user.username,
          notifier: notifier,
        ),
        successMessage: 'Personal details updated.',
        onRefused: showRefusedFields,
      ),
    );
  }
}
