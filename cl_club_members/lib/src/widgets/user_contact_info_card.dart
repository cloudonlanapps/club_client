import 'package:cl_club_forms/cl_club_forms.dart'
    show UserContactForm, UserContactFormState, UserFormFields;
import 'package:cl_club_members/src/models/user_form_helpers.dart'
    show UserFormSubmit, buildUserFormInitialValues;
import 'package:cl_club_members/src/utils/apply_user_update.dart';
import 'package:cl_club_members/src/utils/profile_detail_rows.dart';
import 'package:cl_club_members/src/utils/profile_save_error_message.dart';
import 'package:cl_club_members/src/widgets/contact_detail_row.dart';
import 'package:cl_club_members/src/widgets/emergency_contact_value.dart';
import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show defaultCountryCodeProvider;
import 'package:club_sdk_2/club_sdk_2.dart'
    show SdkErrorCode, ServerException, UserPrivate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart' show LucideIcons;
import 'package:ui_lib/ui_lib.dart'
    show EditableSectionCard, EmailContact, PhoneContact;

/// A member's contact section on their profile — username, email, phone,
/// emergency contact, medical info. Edits in place; the username is shown but
/// not edited here.
///
/// Read-only, the phone, the email and the emergency contact's number carry
/// the buttons that reach them (#32). A member looking at their own profile
/// gets none on their own phone and email.
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

  /// Label of the button that starts an email to the member.
  static const String emailLabel = 'Email';

  /// Shows an email the server refuses as taken on the form's email field.
  /// Returns whether [error] was that refusal.
  bool showRefusedEmail(ServerException error) {
    if (error.code != SdkErrorCode.duplicateEmail) return false;
    formKey.currentState?.showErrors(
      fieldErrors: {UserFormFields.emailId: profileSaveErrorMessage(error)},
    );
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final viewer = ref.watch(authStateProvider).valueOrNull;
    final isSelf = viewer != null && viewer.username == user.username;
    final email = user.email;
    final phone = user.phone;
    final emergencyContact = user.emergencyContact;
    final rows = <Widget?>[
      profileDetailRow(context, LucideIcons.atSign, 'Username', user.username),
      if (isSelf || email == null || email.isEmpty)
        profileDetailRow(context, LucideIcons.mail, 'Email', email)
      else
        ContactDetailRow(
          icon: LucideIcons.mail,
          label: 'Email',
          child: EmailContact(address: email, actionLabel: emailLabel),
        ),
      if (isSelf || phone == null || phone.isEmpty)
        profileDetailRow(context, LucideIcons.phone, 'Phone', phone)
      else
        ContactDetailRow(
          icon: LucideIcons.phone,
          label: 'Phone',
          child: PhoneContact(
            number: phone,
            defaultCountryCode: ref.watch(defaultCountryCodeProvider),
          ),
        ),
      if (emergencyContact != null && emergencyContact.isNotEmpty)
        ContactDetailRow(
          icon: LucideIcons.triangleAlert,
          label: 'Emergency Contact',
          child: EmergencyContactValue(value: emergencyContact),
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
          defaultCountryCode: ref.read(defaultCountryCodeProvider),
        ),
        successMessage: 'Contact updated.',
        onRefused: showRefusedEmail,
      ),
    );
  }
}
