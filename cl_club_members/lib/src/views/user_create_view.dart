import 'package:cl_club_forms/cl_club_forms.dart' show UserForm, UserFormState;
import 'package:cl_club_members/src/models/user_form_helpers.dart';
import 'package:cl_club_members/src/widgets/default_password_dialog.dart';
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
/// Layout: back button → "New User" header → form card → Create / Cancel.
class UserCreateView extends ConsumerStatefulWidget {
  const UserCreateView({
    required this.onCreated,
    required this.onCancel,
    super.key,
  });

  final VoidCallback onCreated;
  final VoidCallback onCancel;

  @override
  ConsumerState<UserCreateView> createState() => UserCreateViewState();
}

class UserCreateViewState extends ConsumerState<UserCreateView> {
  final createFormKey = GlobalKey<UserFormState>();
  bool isSubmitting = false;
  bool canSubmit = false;

  Future<void> handleSubmit(Map<String, dynamic> values) async {
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
      if (e.code == SdkErrorCode.duplicateUsername) {
        showError('That username is already taken.');
      } else if (e.code == SdkErrorCode.duplicateEmail) {
        showError('That email is already registered.');
      } else {
        showError(MemberWriteMessages.createUserFailed);
      }
    } on Object catch (e) {
      showError(
        writeFailureMessage(e, fallback: MemberWriteMessages.createUserFailed),
      );
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
    if (!success || !mounted) return;
    final username = (values['username'] as String).trim();
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

  void showError(String msg) {
    if (!mounted) return;
    ShadToaster.of(context).show(
      ShadToast.destructive(description: Text(msg)),
    );
  }

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
            title: 'New User',
            onBack: isSubmitting ? null : confirmCancel,
          ),
          const Divider(height: 1),
          const SizedBox(height: 8),

          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: ShadCard(
                padding: EdgeInsets.zero,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      UserForm(
                        key: createFormKey,
                        title: 'Creating new profile',
                        initialValues: buildUserFormInitialValues(null),
                        isSubmitting: isSubmitting,
                        canEditDateOfBirth: true,
                        canEditUseNamePublicly: true,
                        canAssignAdmin: isSuperAdmin,
                        canAssignCoach: isAdmin,
                        onSubmit: handleSubmit,
                        onCheckUsernameAvailable: (username) async {
                          final result = await ref.read(
                            usernameAvailabilityProvider(username).future,
                          );
                          return result == UsernameAvailability.available;
                        },
                        onShowDefaultPassword: () => showDialog<void>(
                          context: context,
                          builder: (_) => const DefaultPasswordDialog(),
                        ),
                        onCanSubmitChanged: (value) {
                          if (canSubmit == value) return;
                          setState(() => canSubmit = value);
                        },
                      ),
                      const SizedBox(height: 16),
                      buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildActionButtons() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ShadButton.outline(
          onPressed: isSubmitting ? null : confirmCancel,
          child: const Text('Cancel'),
        ),
        const SizedBox(width: 12),
        ShadButton(
          onPressed: (isSubmitting || !canSubmit)
              ? null
              : () => createFormKey.currentState?.handleSubmit(),
          child: Text(isSubmitting ? 'Creating…' : 'Create user'),
        ),
      ],
    );
  }
}
