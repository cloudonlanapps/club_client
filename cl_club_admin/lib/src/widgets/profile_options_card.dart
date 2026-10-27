import 'package:cl_club_forms/cl_club_forms.dart'
    show ProfileOptionsForm, ProfileOptionsFormState;
import 'package:cl_remote_store/cl_remote_store.dart'
    show profileOptionsProvider;
import 'package:club_sdk_2/club_sdk_2.dart'
    show ProfileOptions, ServerException;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show EditableSectionCard;

import '../constants/profile_options_messages.dart';
import '../models/profile_options_form_helpers.dart';
import 'club_identity_section_body.dart';
import 'profile_options_read_rows.dart';

/// The Profile options section of the club details screen
/// (club_client#320): the positions members choose their preferred one
/// from, each labelled in the club's languages, and those languages, each a
/// name a member chooses and a code (club_client#396), which are also the
/// languages applications print in. Shows them; the pencil edits them in
/// place with [ProfileOptionsForm], and Save stores the whole document.
class ProfileOptionsCard extends ConsumerStatefulWidget {
  const ProfileOptionsCard({
    required this.options,
    required this.canEdit,
    super.key,
  });

  /// Key of the section's card, for tests and the integration suite.
  static const Key cardKey = ValueKey('clubIdentity.section.profileOptions');

  /// The options the server holds.
  final ProfileOptions options;

  /// Whether the viewer may edit them: only the super admin writes the
  /// club's profile options (club_server#98).
  final bool canEdit;

  @override
  ConsumerState<ProfileOptionsCard> createState() => ProfileOptionsCardState();
}

/// State of [ProfileOptionsCard]: the inline form's key.
class ProfileOptionsCardState extends ConsumerState<ProfileOptionsCard> {
  /// Key of the inline form; attached only while the card is being edited.
  final formKey = GlobalKey<ProfileOptionsFormState>();

  /// Stores [values] as the club's options. A document the server cannot
  /// use shows inline in the form, and any other failure is a toast with a
  /// fixed message.
  Future<bool> save(Map<String, dynamic> values) async {
    final toaster = ShadToaster.of(context);
    try {
      await ProfileOptionsFormSubmit.updateProfileOptions(
        values: values,
        notifier: ref.read(profileOptionsProvider.notifier),
      );
      toaster.show(
        const ShadToast(description: Text(ProfileOptionsMessages.saved)),
      );
      return true;
    } on ServerException catch (error) {
      final refusal = ProfileOptionsFormSubmit.refusal(error);
      if (refusal != null) {
        formKey.currentState?.showErrors(
          fieldErrors: refusal.fieldErrors,
          formError: refusal.formError,
        );
      } else {
        toaster.show(
          const ShadToast.destructive(
            description: Text(ProfileOptionsMessages.saveFailed),
          ),
        );
      }
      return false;
    } on Object catch (_) {
      toaster.show(
        const ShadToast.destructive(
          description: Text(ProfileOptionsMessages.saveFailed),
        ),
      );
      return false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final options = widget.options;
    return EditableSectionCard<Map<String, dynamic>>(
      key: ProfileOptionsCard.cardKey,
      title: ProfileOptionsMessages.title,
      canEdit: widget.canEdit,
      isEmpty: options.isEmpty,
      emptyHint: ProfileOptionsMessages.emptyHint,
      editMaxWidth: ClubIdentitySectionBody.formMaxWidth,
      read: ClubIdentitySectionBody(
        description: ProfileOptionsMessages.description,
        child: ProfileOptionsReadRows(options: options),
      ),
      editBuilder: ({required enabled}) => ClubIdentitySectionBody(
        description: ProfileOptionsMessages.description,
        child: ProfileOptionsForm(
          key: formKey,
          initialValues: buildProfileOptionsFormInitialValues(options),
          enabled: enabled,
        ),
      ),
      onValidate: () => formKey.currentState?.validate(),
      isDirty: () => formKey.currentState?.isDirty ?? false,
      onSave: save,
    );
  }
}
