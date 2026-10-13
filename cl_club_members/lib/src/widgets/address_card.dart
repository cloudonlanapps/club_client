import 'package:cl_club_forms/cl_club_forms.dart'
    show UserAddressForm, UserAddressFormState;
import 'package:cl_club_members/src/models/user_form_helpers.dart'
    show UserFormSubmit, buildUserFormInitialValues;
import 'package:cl_club_members/src/utils/apply_user_update.dart';
import 'package:cl_club_members/src/utils/format_user_address.dart';
import 'package:cl_club_members/src/utils/profile_detail_rows.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show EditableSectionCard;

/// Address profile section. Edits in place.
class AddressCard extends ConsumerStatefulWidget {
  const AddressCard({required this.user, required this.canEdit, super.key});

  final UserPrivate user;
  final bool canEdit;

  @override
  ConsumerState<AddressCard> createState() => AddressCardState();
}

/// State of [AddressCard]: the key of its form.
class AddressCardState extends ConsumerState<AddressCard> {
  /// Drives the hosted form.
  final formKey = GlobalKey<UserAddressFormState>();

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final addr = user.address;
    final rows = <Widget?>[
      if (addr != null && !addr.isEmpty)
        profileDetailRow(
          context,
          LucideIcons.mapPin,
          'Address',
          formatUserAddress(addr),
        ),
    ];
    return EditableSectionCard<Map<String, dynamic>>(
      title: 'Address',
      canEdit: widget.canEdit,
      isEmpty: rows.whereType<Widget>().isEmpty,
      emptyHint: 'Tap to add address',
      editMaxWidth: 460,
      read: profileSectionRows(rows),
      editBuilder: ({required enabled}) => UserAddressForm(
        key: formKey,
        initialValues: buildUserFormInitialValues(user),
        enabled: enabled,
      ),
      onValidate: () => formKey.currentState?.validate(),
      isDirty: () => formKey.currentState?.isDirty ?? false,
      onSave: (values) => applyUserUpdate(
        ref,
        context,
        user.username,
        (notifier) => UserFormSubmit.updateAddress(
          values: values,
          username: user.username,
          notifier: notifier,
        ),
        successMessage: 'Address updated.',
      ),
    );
  }
}
