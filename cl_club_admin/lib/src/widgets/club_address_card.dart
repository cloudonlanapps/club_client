import 'package:cl_club_forms/cl_club_forms.dart'
    show ClubAddressForm, ClubAddressFormFields, ClubAddressFormState;
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

/// The Address section of the club details screen: the club's postal
/// address.
/// Shows the values that are set; the pencil edits them in place with
/// [ClubAddressForm], and Save stores this section alone.
class ClubAddressCard extends ConsumerStatefulWidget {
  const ClubAddressCard({
    required this.identity,
    required this.languages,
    super.key,
  });

  /// Key of the section's card, for tests and the integration suite.
  static const Key cardKey = ValueKey('clubIdentity.section.address');

  /// The icon of each field's row in the read view.
  static const Map<String, IconData> icons = {
    ClubAddressFormFields.addressId: LucideIcons.mapPin,
    ClubAddressFormFields.addressLine2Id: LucideIcons.mapPin,
    ClubAddressFormFields.cityId: LucideIcons.mapPin,
    ClubAddressFormFields.stateId: LucideIcons.mapPin,
    ClubAddressFormFields.postalCodeId: LucideIcons.map,
  };

  /// The identity the server holds.
  final ClubIdentity identity;

  /// The language codes the translatable fields offer a translation in.
  final List<String> languages;

  @override
  ConsumerState<ClubAddressCard> createState() => ClubAddressCardState();
}

/// State of [ClubAddressCard]: the inline form's key and the in-flight save.
class ClubAddressCardState extends ConsumerState<ClubAddressCard> {
  /// Key of the inline form; attached only while the card is being edited.
  final formKey = GlobalKey<ClubAddressFormState>();

  /// Whether a save is in flight; the form is disabled meanwhile.
  bool saving = false;

  /// Stores the section's [values] over the identity the server holds.
  Future<bool> save(Map<String, dynamic> values) async {
    setState(() => saving = true);
    final stored = await applyClubIdentityUpdate(
      ref: ref,
      context: context,
      update: (notifier) => ClubIdentityFormSubmit.updateAddress(
        values: values,
        base: widget.identity,
        notifier: notifier,
      ),
      successMessage: ClubIdentityMessages.addressSaved,
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
      key: ClubAddressCard.cardKey,
      title: ClubIdentityMessages.addressTitle,
      canEdit: true,
      isEmpty: ClubIdentityReadRows.isEmptyOf(
        values,
        ClubAddressFormFields.labels.keys,
      ),
      emptyHint: ClubIdentityMessages.addressEmptyHint,
      editMaxWidth: ClubIdentitySectionBody.formMaxWidth,
      read: ClubIdentitySectionBody(
        child: ClubIdentityReadRows(
          values: values,
          labels: ClubAddressFormFields.labels,
          icons: ClubAddressCard.icons,
        ),
      ),
      editBuilder: () => ClubIdentitySectionBody(
        child: ClubAddressForm(
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
