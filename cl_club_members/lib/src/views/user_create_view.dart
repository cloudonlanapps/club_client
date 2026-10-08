import 'package:cl_club_forms/cl_club_forms.dart'
    show UserForm, UserFormFields, UserFormState;
import 'package:cl_club_members/src/models/user_form_helpers.dart';
import 'package:cl_club_members/src/widgets/default_password_dialog.dart';
import 'package:cl_club_members/src/widgets/user_create_actions.dart';
import 'package:cl_club_members/src/widgets/user_create_card.dart';
import 'package:cl_member_auth/cl_member_auth.dart'
    show UsernameAvailability, authStateProvider, usernameAvailabilityProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clUsersMasterProvider, defaultCountryCodeProvider, writeFailureMessage;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ConfirmDialog, TitleRow;

import '../utils/member_write_messages.dart';

// Blocked on #97 (club_server#25)

/// Admin create-user content view. No Scaffold — the host provides the shell.
///
/// Layout: back button → "New User" header → [UserCreateCard] with the
/// `UserForm` and the Cancel / Create user actions. The view validates the
/// form, creates the user, holds the in-flight flag, and shows a username
/// or an email the server refuses as taken on that field.
class UserCreateView extends ConsumerStatefulWidget {
  const UserCreateView({
    required this.onCreated,
    required this.onCancel,
    super.key,
  });

  /// Heading of the page.
  static const String pageTitle = 'New User';

  /// Under the page heading's divider.
  static const double headerGap = 8;

  /// Called once the user is created.
  final VoidCallback onCreated;

  /// Called when the admin leaves without creating.
  final VoidCallback onCancel;

  @override
  ConsumerState<UserCreateView> createState() => UserCreateViewState();
}

/// State of [UserCreateView]: holds the form's key, the in-flight flag and
/// whether the form may be submitted.
class UserCreateViewState extends ConsumerState<UserCreateView> {
  /// Key of the create form.
  final createFormKey = GlobalKey<UserFormState>();

  /// Whether the creation is in flight.
  bool isSubmitting = false;

  /// Whether the form may be submitted: its username is confirmed
  /// available.
  bool canSubmit = false;

  /// The Create user action: validates the form, creates the user its
  /// values describe and reports the outcome.
  Future<void> submit() async {
    final values = createFormKey.currentState?.validate();
    if (values == null) return;

    setState(() => isSubmitting = true);
    var success = false;
    var failedRoles = const <String>[];
    try {
      failedRoles = await UserFormSubmit.create(
        values: values,
        notifier: ref.read(clUsersMasterProvider.notifier),
        defaultCountryCode: ref.read(defaultCountryCodeProvider),
      );
      success = true;
    } on ServerException catch (e) {
      final fieldErrors = UserFormSubmit.fieldErrorsFor(e);
      if (fieldErrors.isEmpty) {
        showError(MemberWriteMessages.createUserFailed);
      } else {
        createFormKey.currentState?.showErrors(fieldErrors: fieldErrors);
      }
    } on Object catch (e) {
      showError(
        writeFailureMessage(e, fallback: MemberWriteMessages.createUserFailed),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
    if (!success || !mounted) return;
    final username = (values[UserFormFields.usernameId] as String).trim();
    if (failedRoles.isEmpty) {
      ShadToaster.of(context).show(
        ShadToast(description: Text('Created $username.')),
      );
    } else {
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(
            'Created $username but failed to assign role(s): '
            '${failedRoles.join(', ')}. Open the profile to retry.',
          ),
        ),
      );
    }
    widget.onCreated();
  }

  /// Shows [msg] as a failure toast.
  void showError(String msg) {
    if (!mounted) return;
    ShadToaster.of(context).show(
      ShadToast.destructive(description: Text(msg)),
    );
  }

  /// Leaves the view, asking first when the form holds changes.
  Future<void> confirmCancel() async {
    final dirty = createFormKey.currentState?.isDirty ?? false;
    if (!dirty) {
      widget.onCancel();
      return;
    }
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Discard changes?',
      message: 'You have unsaved changes. Are you sure you want to leave?',
      confirmLabel: 'Discard',
      destructive: true,
    );
    if (confirmed && mounted) {
      widget.onCancel();
    }
  }

  /// Whether [username] is free to create.
  Future<bool> checkUsernameAvailable(String username) async {
    final result = await ref.read(
      usernameAvailabilityProvider(username).future,
    );
    return result == UsernameAvailability.available;
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(authStateProvider).valueOrNull;
    final isSuperAdmin = currentUser?.isSuperAdmin ?? false;
    final isAdmin = (currentUser?.roles.isAdmin ?? false) || isSuperAdmin;

    return PopScope(
      canPop: !canSubmit && !isSubmitting,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        await confirmCancel();
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TitleRow(
            title: UserCreateView.pageTitle,
            onBack: isSubmitting ? null : confirmCancel,
          ),
          const Divider(height: 1),
          const SizedBox(height: UserCreateView.headerGap),
          Expanded(
            child: UserCreateCard(
              form: UserForm(
                key: createFormKey,
                initialValues: buildUserFormInitialValues(null),
                defaultCountryCode: ref.watch(defaultCountryCodeProvider),
                enabled: !isSubmitting,
                canAssignAdmin: isSuperAdmin,
                canAssignCoach: isAdmin,
                onCheckUsernameAvailable: checkUsernameAvailable,
                onShowDefaultPassword: () => showDialog<void>(
                  context: context,
                  builder: (_) => const DefaultPasswordDialog(),
                ),
                onCanSubmitChanged: (value) {
                  if (canSubmit == value) return;
                  setState(() => canSubmit = value);
                },
              ),
              actions: UserCreateActions(
                isSubmitting: isSubmitting,
                canSubmit: canSubmit,
                onCancel: confirmCancel,
                onSubmit: submit,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
