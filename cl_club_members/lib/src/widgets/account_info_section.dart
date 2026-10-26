import 'package:cl_club_forms/cl_club_forms.dart'
    show MembershipDateForm, MembershipDateFormState;
import 'package:cl_club_members/src/constants/extended_profile_strings.dart';
import 'package:cl_club_members/src/models/user_extended_profile_form_helpers.dart';
import 'package:cl_club_members/src/utils/apply_user_update.dart';
import 'package:cl_remote_store/cl_remote_store.dart'
    show extendedProfileProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show EditableSectionCard, ReadOnlyField;

/// Account info section: member since, last login and, while the extended
/// profile is on, the membership date (club_client#320).
///
/// The membership date is an admin's to correct: with
/// [canEditMembershipDate] the section edits it in place with
/// [MembershipDateForm], sending that date alone; everyone else reads it.
class AccountInfoSection extends ConsumerStatefulWidget {
  const AccountInfoSection({
    required this.user,
    this.canEditMembershipDate = false,
    super.key,
  });

  /// Key of the section's card, for tests and the integration suite.
  static const Key cardKey = ValueKey('profile.section.accountInfo');

  /// How a moment of the account (created, last login) reads.
  static const String timestampFormat = 'd MMM yyyy, HH:mm';

  /// How the membership date, a date-only value, reads.
  static const String dateFormat = 'd MMM yyyy';

  /// Gap between two rows.
  static const double rowGap = 8;

  /// The member whose account this is.
  final UserPrivate user;

  /// Whether the viewer may correct the membership date (an admin).
  final bool canEditMembershipDate;

  @override
  ConsumerState<AccountInfoSection> createState() => AccountInfoSectionState();
}

/// State of [AccountInfoSection]: the key of its form.
class AccountInfoSectionState extends ConsumerState<AccountInfoSection> {
  /// Drives the hosted form.
  final formKey = GlobalKey<MembershipDateFormState>();

  /// Shows what the server refuses about the date on it. Returns whether
  /// [error] named it.
  bool showRefusedFields(ServerException error) {
    final fieldErrors = UserExtendedProfileFormSubmit.fieldErrorsFor(error);
    if (fieldErrors.isEmpty) return false;
    formKey.currentState?.showErrors(fieldErrors: fieldErrors);
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final extended = ref.watch(extendedProfileProvider) ?? false;
    final moment = DateFormat(AccountInfoSection.timestampFormat);
    final membershipDate = user.membershipDateUtc;
    return EditableSectionCard<Map<String, dynamic>>(
      key: AccountInfoSection.cardKey,
      title: 'Account Info',
      canEdit: extended && widget.canEditMembershipDate,
      editMaxWidth: 460,
      read: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        spacing: AccountInfoSection.rowGap,
        children: [
          ReadOnlyField(
            label: 'Member since',
            value: moment.format(user.createdAtUtc.toLocal()),
          ),
          ReadOnlyField(
            label: 'Last login',
            value: user.lastLoginAtUtc != null
                ? moment.format(user.lastLoginAtUtc!.toLocal())
                : 'Never',
          ),
          if (extended)
            ReadOnlyField(
              label: ExtendedProfileStrings.membershipDate,
              // A date-only value: its UTC day is the day, everywhere.
              value: membershipDate != null
                  ? DateFormat(
                      AccountInfoSection.dateFormat,
                    ).format(membershipDate.toUtc())
                  : ExtendedProfileStrings.notSet,
            ),
        ],
      ),
      editBuilder: ({required enabled}) => MembershipDateForm(
        key: formKey,
        initialValue: membershipDate,
        enabled: enabled,
      ),
      onValidate: () => formKey.currentState?.validate(),
      isDirty: () => formKey.currentState?.isDirty ?? false,
      onSave: (values) => applyUserUpdate(
        ref,
        context,
        user.username,
        (notifier) => UserExtendedProfileFormSubmit.updateMembershipDate(
          values: values,
          username: user.username,
          notifier: notifier,
        ),
        successMessage: ExtendedProfileStrings.membershipDateSaved,
        onRefused: showRefusedFields,
      ),
    );
  }
}
