import 'package:cl_club_forms/cl_club_forms.dart'
    show ClubDetailsForm, ClubDetailsFormFields, ClubDetailsFormState;
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

/// The Club section of the club details screen: the club's name,
/// short name, tagline and the address its website inquiries go to.
/// Shows the values that are set; the pencil edits them in place with
/// [ClubDetailsForm], and Save stores this section alone.
class ClubDetailsCard extends ConsumerStatefulWidget {
  const ClubDetailsCard({
    required this.identity,
    required this.languages,
    super.key,
  });

  /// Key of the section's card, for tests and the integration suite.
  static const Key cardKey = ValueKey('clubIdentity.section.club');

  /// The icon of each field's row in the read view.
  static const Map<String, IconData> icons = {
    ClubDetailsFormFields.nameId: LucideIcons.users,
    ClubDetailsFormFields.shortNameId: LucideIcons.idCard,
    ClubDetailsFormFields.taglineId: LucideIcons.megaphone,
    ClubDetailsFormFields.inquiryEmailId: LucideIcons.mail,
  };

  /// The identity the server holds.
  final ClubIdentity identity;

  /// The language codes the translatable fields offer a translation in.
  final List<String> languages;

  @override
  ConsumerState<ClubDetailsCard> createState() => ClubDetailsCardState();
}

/// State of [ClubDetailsCard]: the inline form's key and the in-flight save.
class ClubDetailsCardState extends ConsumerState<ClubDetailsCard> {
  /// Key of the inline form; attached only while the card is being edited.
  final formKey = GlobalKey<ClubDetailsFormState>();

  /// Whether a save is in flight; the form is disabled meanwhile.
  bool saving = false;

  /// Stores the section's [values] over the identity the server holds.
  Future<bool> save(Map<String, dynamic> values) async {
    setState(() => saving = true);
    final stored = await applyClubIdentityUpdate(
      ref: ref,
      context: context,
      update: (notifier) => ClubIdentityFormSubmit.updateClub(
        values: values,
        base: widget.identity,
        notifier: notifier,
      ),
      successMessage: ClubIdentityMessages.clubSaved,
      onRefused: (message) =>
          formKey.currentState?.showErrors(formError: message),
    );
    if (mounted) setState(() => saving = false);
    return stored;
  }

  @override
  Widget build(BuildContext context) {
    final values = buildClubIdentityFormInitialValues(widget.identity);
    return EditableSectionCard<Map<String, dynamic>>(
      key: ClubDetailsCard.cardKey,
      title: ClubIdentityMessages.clubTitle,
      canEdit: true,
      isEmpty: ClubIdentityReadRows.isEmptyOf(
        values,
        ClubDetailsFormFields.labels.keys,
      ),
      emptyHint: ClubIdentityMessages.clubEmptyHint,
      editMaxWidth: ClubIdentitySectionBody.formMaxWidth,
      read: ClubIdentitySectionBody(
        description: ClubIdentityMessages.clubDescription,
        child: ClubIdentityReadRows(
          values: values,
          labels: ClubDetailsFormFields.labels,
          icons: ClubDetailsCard.icons,
        ),
      ),
      editBuilder: () => ClubIdentitySectionBody(
        description: ClubIdentityMessages.clubDescription,
        child: ClubDetailsForm(
          key: formKey,
          initialValues: values,
          languages: widget.languages,
          enabled: !saving,
        ),
      ),
      onValidate: () => formKey.currentState?.validate(),
      isDirty: () => formKey.currentState?.isDirty ?? false,
      onSave: save,
    );
  }
}
