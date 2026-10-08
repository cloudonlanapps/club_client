import 'package:cl_club_forms/cl_club_forms.dart'
    show ClubContactForm, ClubContactFormFields, ClubContactFormState;
import 'package:club_sdk_2/club_sdk_2.dart' show ClubIdentity;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;
import 'package:ui_lib/ui_lib.dart' show EditableSectionCard;

import '../constants/club_identity_messages.dart';
import '../models/club_identity_form_helpers.dart';
import '../utils/apply_club_identity_update.dart';
import 'club_identity_read_rows.dart';
import 'club_identity_section_body.dart';

/// The Contact section of the club details screen: how the website
/// tells visitors to reach the club.
/// Shows the values that are set; the pencil edits them in place with
/// [ClubContactForm], and Save stores this section alone.
class ClubContactCard extends ConsumerStatefulWidget {
  const ClubContactCard({
    required this.identity,
    required this.languages,
    super.key,
  });

  /// Key of the section's card, for tests and the integration suite.
  static const Key cardKey = ValueKey('clubIdentity.section.contact');

  /// The icon of each field's row in the read view.
  static const Map<String, IconData> icons = {
    ClubContactFormFields.phoneNumberId: LucideIcons.phone,
    ClubContactFormFields.whatsappNumberId: LucideIcons.messageCircle,
    ClubContactFormFields.whatsappMessageId: LucideIcons.messageCircle,
    ClubContactFormFields.emailId: LucideIcons.mail,
    ClubContactFormFields.emailSubjectId: LucideIcons.mail,
    ClubContactFormFields.instagramUrlId: LucideIcons.link,
  };

  /// The identity the server holds.
  final ClubIdentity identity;

  /// The language codes the translatable fields offer a translation in.
  final List<String> languages;

  @override
  ConsumerState<ClubContactCard> createState() => ClubContactCardState();
}

/// State of [ClubContactCard]: the inline form's key and the in-flight save.
class ClubContactCardState extends ConsumerState<ClubContactCard> {
  /// Key of the inline form; attached only while the card is being edited.
  final formKey = GlobalKey<ClubContactFormState>();

  /// Stores the section's [values] over the identity the server holds.
  Future<bool> save(Map<String, dynamic> values) async {
    return applyClubIdentityUpdate(
      ref: ref,
      context: context,
      update: (notifier) => ClubIdentityFormSubmit.updateContact(
        values: values,
        base: widget.identity,
        notifier: notifier,
      ),
      successMessage: ClubIdentityMessages.contactSaved,
      onRefused: (message) =>
          formKey.currentState?.showErrors(formError: message),
    );
  }

  @override
  Widget build(BuildContext context) {
    final values = buildClubIdentityFormInitialValues(widget.identity);
    return EditableSectionCard<Map<String, dynamic>>(
      key: ClubContactCard.cardKey,
      title: ClubIdentityMessages.contactTitle,
      canEdit: true,
      isEmpty: ClubIdentityReadRows.isEmptyOf(
        values,
        ClubContactFormFields.labels.keys,
      ),
      emptyHint: ClubIdentityMessages.contactEmptyHint,
      editMaxWidth: ClubIdentitySectionBody.formMaxWidth,
      read: ClubIdentitySectionBody(
        description: ClubIdentityMessages.contactDescription,
        child: ClubIdentityReadRows(
          values: values,
          labels: ClubContactFormFields.labels,
          icons: ClubContactCard.icons,
        ),
      ),
      editBuilder: ({required enabled}) => ClubIdentitySectionBody(
        description: ClubIdentityMessages.contactDescription,
        child: ClubContactForm(
          key: formKey,
          initialValues: values,
          languages: widget.languages,
          enabled: enabled,
        ),
      ),
      onValidate: () => formKey.currentState?.validate(),
      isDirty: () => formKey.currentState?.isDirty ?? false,
      onSave: save,
    );
  }
}
