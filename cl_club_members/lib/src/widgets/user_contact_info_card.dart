import 'package:cl_club_members/src/models/user_form_helpers.dart'
    show UserFormSubmit, buildUserFormInitialValues;
import 'package:cl_club_members/src/utils/apply_user_update.dart';
import 'package:cl_club_members/src/utils/profile_detail_rows.dart';
import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;
import 'package:ui_lib/ui_lib.dart'
    show EditableSectionCard, UserContactForm, UserContactFormState;

/// A member's contact section on their profile — username, email, phone,
/// emergency contact, medical info. Edits in place; the username is shown but
/// not edited here.
class UserContactInfoCard extends ConsumerStatefulWidget {
  const UserContactInfoCard({
    required this.user,
    required this.canEdit,
    super.key,
  });

  final UserPrivate user;
  final bool canEdit;

  @override
  ConsumerState<UserContactInfoCard> createState() =>
      UserContactInfoCardState();
}

/// State of [UserContactInfoCard]: holds the inline form's key.
class UserContactInfoCardState extends ConsumerState<UserContactInfoCard> {
  final formKey = GlobalKey<UserContactFormState>();

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final rows = <Widget?>[
      profileDetailRow(context, LucideIcons.atSign, 'Username', user.username),
      profileDetailRow(context, LucideIcons.mail, 'Email', user.email),
      profileDetailRow(context, LucideIcons.phone, 'Phone', user.phone),
      profileDetailRow(
        context,
        LucideIcons.triangleAlert,
        'Emergency Contact',
        user.emergencyContact,
      ),
      profileDetailRow(
        context,
        LucideIcons.heartPulse,
        'Medical Info',
        user.medicalInfo,
      ),
    ];
    return EditableSectionCard<Map<String, dynamic>>(
      title: 'Contact',
      canEdit: widget.canEdit,
      isEmpty: rows.whereType<Widget>().isEmpty,
      emptyHint: 'Tap to add contact details',
      editMaxWidth: 460,
      read: profileSectionRows(rows),
      editBuilder: () => UserContactForm(
        key: formKey,
        initialValues: buildUserFormInitialValues(user),
      ),
      onValidate: () => formKey.currentState?.validate(),
      isDirty: () => formKey.currentState?.isDirty ?? false,
      onSave: (values) => applyUserUpdate(
        ref,
        context,
        user.username,
        (notifier) => UserFormSubmit.updateContact(
          values: values,
          username: user.username,
          notifier: notifier,
        ),
        successMessage: 'Contact updated.',
      ),
    );
  }
}
