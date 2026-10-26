import 'package:cl_club_forms/cl_club_forms.dart'
    show UserGuardianForm, UserGuardianFormState;
import 'package:cl_club_members/src/constants/extended_profile_strings.dart';
import 'package:cl_club_members/src/models/user_extended_profile_form_helpers.dart';
import 'package:cl_club_members/src/utils/apply_user_update.dart';
import 'package:cl_club_members/src/utils/profile_detail_rows.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show defaultCountryCodeProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show ServerException, UserPrivate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;
import 'package:ui_lib/ui_lib.dart' show EditableSectionCard;

/// The Guardian section of a member's extended profile (club_client#320):
/// the guardian's name, relation and phone, apart from the emergency
/// contact. Edits in place with [UserGuardianForm]; Save sends the guardian
/// alone, its phone in international format.
class GuardianCard extends ConsumerStatefulWidget {
  const GuardianCard({required this.user, required this.canEdit, super.key});

  /// Key of the section's card, for tests and the integration suite.
  static const Key cardKey = ValueKey('profile.section.guardian');

  /// The member whose section this is.
  final UserPrivate user;

  /// Whether the viewer may edit it.
  final bool canEdit;

  @override
  ConsumerState<GuardianCard> createState() => GuardianCardState();
}

/// State of [GuardianCard]: the key of its form.
class GuardianCardState extends ConsumerState<GuardianCard> {
  /// Drives the hosted form.
  final formKey = GlobalKey<UserGuardianFormState>();

  /// Shows what the server refuses about a field on that field. Returns
  /// whether [error] named one.
  bool showRefusedFields(ServerException error) {
    final fieldErrors = UserExtendedProfileFormSubmit.fieldErrorsFor(error);
    if (fieldErrors.isEmpty) return false;
    formKey.currentState?.showErrors(fieldErrors: fieldErrors);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final guardian = user.guardian;
    final rows = <Widget?>[
      profileDetailRow(
        context,
        LucideIcons.userRound,
        ExtendedProfileStrings.guardianName,
        guardian?.name,
      ),
      profileDetailRow(
        context,
        LucideIcons.users,
        ExtendedProfileStrings.guardianRelation,
        guardian?.relation,
      ),
      profileDetailRow(
        context,
        LucideIcons.phone,
        ExtendedProfileStrings.guardianPhone,
        guardian?.phone,
      ),
    ];
    return EditableSectionCard<Map<String, dynamic>>(
      key: GuardianCard.cardKey,
      title: ExtendedProfileStrings.guardianTitle,
      canEdit: widget.canEdit,
      isEmpty: rows.whereType<Widget>().isEmpty,
      emptyHint: ExtendedProfileStrings.guardianEmptyHint,
      editMaxWidth: 460,
      read: profileSectionRows(rows),
      editBuilder: ({required enabled}) => UserGuardianForm(
        key: formKey,
        initialValues: buildUserExtendedProfileFormInitialValues(user),
        defaultCountryCode: ref.watch(defaultCountryCodeProvider),
        enabled: enabled,
      ),
      onValidate: () => formKey.currentState?.validate(),
      isDirty: () => formKey.currentState?.isDirty ?? false,
      onSave: (values) => applyUserUpdate(
        ref,
        context,
        user.username,
        (notifier) => UserExtendedProfileFormSubmit.updateGuardian(
          values: values,
          username: user.username,
          notifier: notifier,
          defaultCountryCode: ref.read(defaultCountryCodeProvider),
        ),
        successMessage: ExtendedProfileStrings.guardianSaved,
        onRefused: showRefusedFields,
      ),
    );
  }
}
