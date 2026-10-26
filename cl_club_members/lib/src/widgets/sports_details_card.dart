import 'package:cl_club_forms/cl_club_forms.dart'
    show UserSportsDetailsForm, UserSportsDetailsFormState;
import 'package:cl_club_members/src/constants/extended_profile_strings.dart';
import 'package:cl_club_members/src/models/user_extended_profile_form_helpers.dart';
import 'package:cl_club_members/src/utils/apply_user_update.dart';
import 'package:cl_club_members/src/utils/profile_detail_rows.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show profileOptionsProvider;
import 'package:club_sdk_2/club_sdk_2.dart'
    show ProfileOptions, ServerException, UserPrivate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;
import 'package:ui_lib/ui_lib.dart' show EditableSectionCard;

/// The Sports details section of a member's extended profile
/// (club_client#320): club or district, preferred position and past
/// experience. Edits in place with [UserSportsDetailsForm]; Save sends these
/// three fields alone. The position reads as the club's English label.
class SportsDetailsCard extends ConsumerStatefulWidget {
  const SportsDetailsCard({
    required this.user,
    required this.canEdit,
    super.key,
  });

  /// Key of the section's card, for tests and the integration suite.
  static const Key cardKey = ValueKey('profile.section.sportsDetails');

  /// The member whose section this is.
  final UserPrivate user;

  /// Whether the viewer may edit it.
  final bool canEdit;

  @override
  ConsumerState<SportsDetailsCard> createState() => SportsDetailsCardState();
}

/// State of [SportsDetailsCard]: the key of its form.
class SportsDetailsCardState extends ConsumerState<SportsDetailsCard> {
  /// Drives the hosted form.
  final formKey = GlobalKey<UserSportsDetailsFormState>();

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
    final options =
        ref.watch(profileOptionsProvider).valueOrNull ?? const ProfileOptions();
    final position = user.preferredPosition;
    final rows = <Widget?>[
      profileDetailRow(
        context,
        LucideIcons.mapPin,
        ExtendedProfileStrings.clubDistrict,
        user.clubDistrict,
      ),
      profileDetailRow(
        context,
        LucideIcons.shield,
        ExtendedProfileStrings.preferredPosition,
        position == null ? null : profilePositionLabel(options, position),
      ),
      profileDetailRow(
        context,
        LucideIcons.history,
        ExtendedProfileStrings.pastExperience,
        user.pastExperience,
      ),
    ];
    return EditableSectionCard<Map<String, dynamic>>(
      key: SportsDetailsCard.cardKey,
      title: ExtendedProfileStrings.sportsDetailsTitle,
      canEdit: widget.canEdit,
      isEmpty: rows.whereType<Widget>().isEmpty,
      emptyHint: ExtendedProfileStrings.sportsDetailsEmptyHint,
      editMaxWidth: 460,
      read: profileSectionRows(rows),
      editBuilder: ({required enabled}) => UserSportsDetailsForm(
        key: formKey,
        initialValues: buildUserExtendedProfileFormInitialValues(user),
        positions: profilePositionOptions(options),
        enabled: enabled,
      ),
      onValidate: () => formKey.currentState?.validate(),
      isDirty: () => formKey.currentState?.isDirty ?? false,
      onSave: (values) => applyUserUpdate(
        ref,
        context,
        user.username,
        (notifier) => UserExtendedProfileFormSubmit.updateSportsDetails(
          values: values,
          username: user.username,
          notifier: notifier,
        ),
        successMessage: ExtendedProfileStrings.sportsDetailsSaved,
        onRefused: showRefusedFields,
      ),
    );
  }
}
