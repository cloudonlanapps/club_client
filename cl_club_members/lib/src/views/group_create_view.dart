import 'dart:async';

import 'package:cl_club_forms/cl_club_forms.dart'
    show GroupCreateForm, GroupCreateFormState, GroupFormFields;
import 'package:cl_club_members/src/models/group_form_helpers.dart';
import 'package:cl_club_members/src/widgets/group_create_actions.dart';
import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clGroupsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show DiscardChangesPrompt, TitleRow;

/// Admin create-group content view. No Scaffold — the host provides the shell.
///
/// Hosts [GroupCreateForm]: it owns the title and the actions, validates the
/// form from Create group, runs the create, holds the in-flight flag, and
/// puts a server refusal back on the form.
class GroupCreateView extends ConsumerStatefulWidget {
  const GroupCreateView({
    required this.onCreated,
    required this.onCancel,
    super.key,
  });

  final VoidCallback onCreated;
  final VoidCallback onCancel;

  @override
  ConsumerState<GroupCreateView> createState() => GroupCreateViewState();
}

class GroupCreateViewState extends ConsumerState<GroupCreateView> {
  final createFormKey = GlobalKey<GroupCreateFormState>();
  bool isSubmitting = false;

  /// Validates the form and, when it is valid, creates the group.
  Future<void> submit() async {
    final values = createFormKey.currentState?.validate();
    if (values == null) return;
    await handleSubmit(values);
  }

  /// Creates the group from the form's valid [values].
  Future<void> handleSubmit(Map<String, dynamic> values) async {
    setState(() => isSubmitting = true);
    final name = (values[GroupFormFields.nameId] as String).trim();
    final addMe = values[GroupFormFields.addMeId] as bool? ?? false;
    try {
      final created = await GroupFormSubmit.create(
        values: values,
        notifier: ref.read(clGroupsMasterProvider.notifier),
      );
      if (!mounted) return;

      // Issue #175: optionally enroll the current user. We only reach this
      // branch after a successful group creation. If the auto-add itself
      // fails, surface a partial-success toast — the group still exists.
      final autoJoinFailureMessage = await maybeAddMe(
        addMe: addMe,
        groupId: created.id,
      );

      if (!mounted) return;
      if (autoJoinFailureMessage == null) {
        ShadToaster.of(context).show(
          ShadToast(
            description: Text(
              addMe
                  ? 'Created "$name" and added you as a member.'
                  : 'Created "$name".',
            ),
          ),
        );
      } else {
        // Partial outcome: group created, auto-join failed.
        ShadToaster.of(context).show(
          ShadToast.destructive(
            description: Text(
              'Created "$name" but could not add you: '
              '$autoJoinFailureMessage',
            ),
          ),
        );
      }
      widget.onCreated();
    } on Object catch (e) {
      // What the server refuses about a value shows on the form; anything
      // else is a failed create.
      final refusal = GroupFormSubmit.createRefusal(e);
      if (refusal == null) {
        showError('Could not create group.');
      } else {
        createFormKey.currentState?.showErrors(
          fieldErrors: refusal.fieldErrors,
          formError: refusal.formError,
        );
      }
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  /// Attempt to auto-enroll the current user. Returns `null` on success
  /// (or when the user opted out), or a human-readable failure message
  /// when the group was created but the membership add failed.
  Future<String?> maybeAddMe({
    required bool addMe,
    required int groupId,
  }) async {
    if (!addMe) return null;
    final currentUser = ref.read(authStateProvider).valueOrNull;
    if (currentUser == null) {
      return 'you are not signed in.';
    }
    try {
      await ref
          .read(clGroupsMasterProvider.notifier)
          .addMember(
            groupId,
            currentUser.username,
          );
      // Auth Sync: the logged-in user's group membership changed.
      ref.invalidate(authStateProvider);
      return null;
    } on ServerException catch (e) {
      // Auto-group eligibility failures: server emits NOT_ELIGIBLE /
      // MEMBERS_INELIGIBLE / AUTO_GROUP_NOT_JOINABLE depending on the
      // exact path.
      if (e.code == 'NOT_ELIGIBLE' ||
          e.code == 'MEMBERS_INELIGIBLE' ||
          e.code == 'AUTO_GROUP_NOT_JOINABLE') {
        return 'you do not meet the group criteria.';
      }
      return e.message;
    } on Object catch (_) {
      return 'unexpected error while adding you to the group.';
    }
  }

  void showError(String msg) {
    if (!mounted) return;
    ShadToaster.of(context).show(
      ShadToast.destructive(description: Text(msg)),
    );
  }

  /// Leaves the view by Cancel, the back arrow or a system back. Asks first
  /// when the form holds changes, read at that moment; does nothing while
  /// the create is in flight.
  Future<void> confirmCancel() async {
    if (isSubmitting) return;
    final dirty = createFormKey.currentState?.isDirty ?? false;
    if (dirty) {
      final discard = await DiscardChangesPrompt.show(context);
      if (!discard || !mounted) return;
    }
    widget.onCancel();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // A system back never pops by itself: whether the form holds changes
      // is only known when back is pressed, so the handler decides.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) unawaited(confirmCancel());
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TitleRow(
            title: 'New Group',
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
                    spacing: 16,
                    children: [
                      Text(
                        'Creating new group',
                        style: ShadTheme.of(context).textTheme.h4,
                      ),
                      GroupCreateForm(
                        key: createFormKey,
                        initialValues: buildGroupFormInitialValues(null),
                        enabled: !isSubmitting,
                      ),
                      GroupCreateActions(
                        isSubmitting: isSubmitting,
                        onCancel: confirmCancel,
                        onCreate: submit,
                      ),
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
}
