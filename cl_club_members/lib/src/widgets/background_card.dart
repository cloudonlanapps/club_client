import 'package:cl_club_forms/cl_club_forms.dart'
    show UserBackgroundForm, UserBackgroundFormState;
import 'package:cl_club_members/src/constants/extended_profile_strings.dart';
import 'package:cl_club_members/src/models/user_extended_profile_form_helpers.dart';
import 'package:cl_club_members/src/utils/apply_user_update.dart';
import 'package:cl_club_members/src/utils/profile_detail_rows.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show profileOptionsProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show ServerException, UserPrivate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;
import 'package:ui_lib/ui_lib.dart' show EditableSectionCard;

/// The Background section of a member's extended profile
/// (club_client#320): nationality and preferred language. Edits in place
/// with [UserBackgroundForm], whose language select offers the club's
/// languages; Save sends these two fields alone.
class BackgroundCard extends ConsumerStatefulWidget {
  const BackgroundCard({required this.user, required this.canEdit, super.key});

  /// Key of the section's card, for tests and the integration suite.
  static const Key cardKey = ValueKey('profile.section.background');

  /// The member whose section this is.
  final UserPrivate user;

  /// Whether the viewer may edit it.
  final bool canEdit;

  @override
  ConsumerState<BackgroundCard> createState() => BackgroundCardState();
}

/// State of [BackgroundCard]: the key of its form.
class BackgroundCardState extends ConsumerState<BackgroundCard> {
  /// Drives the hosted form.
  final formKey = GlobalKey<UserBackgroundFormState>();

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
    final languages =
        ref.watch(profileOptionsProvider).valueOrNull?.languages ?? const [];
    final rows = <Widget?>[
      profileDetailRow(
        context,
        LucideIcons.flag,
        ExtendedProfileStrings.nationality,
        user.nationality,
      ),
      profileDetailRow(
        context,
        LucideIcons.languages,
        ExtendedProfileStrings.preferredLanguage,
        user.preferredLanguage,
      ),
    ];
    return EditableSectionCard<Map<String, dynamic>>(
      key: BackgroundCard.cardKey,
      title: ExtendedProfileStrings.backgroundTitle,
      canEdit: widget.canEdit,
      isEmpty: rows.whereType<Widget>().isEmpty,
      emptyHint: ExtendedProfileStrings.backgroundEmptyHint,
      editMaxWidth: 460,
      read: profileSectionRows(rows),
      editBuilder: ({required enabled}) => UserBackgroundForm(
        key: formKey,
        initialValues: buildUserExtendedProfileFormInitialValues(user),
        languages: languages,
        enabled: enabled,
      ),
      onValidate: () => formKey.currentState?.validate(),
      isDirty: () => formKey.currentState?.isDirty ?? false,
      onSave: (values) => applyUserUpdate(
        ref,
        context,
        user.username,
        (notifier) => UserExtendedProfileFormSubmit.updateBackground(
          values: values,
          username: user.username,
          notifier: notifier,
        ),
        successMessage: ExtendedProfileStrings.backgroundSaved,
        onRefused: showRefusedFields,
      ),
    );
  }
}
