import 'package:cl_club_members/src/utils/group_hard_delete_error_message.dart';
import 'package:cl_club_members/src/widgets/add_member_dialog.dart';
import 'package:cl_club_members/src/widgets/group_eligibility_section.dart';
import 'package:cl_club_members/src/widgets/group_info_section.dart';
import 'package:cl_club_members/src/widgets/group_management_section.dart';
import 'package:cl_club_members/src/widgets/group_member_list.dart';
import 'package:cl_club_members/src/widgets/group_message_section.dart';
import 'package:cl_club_members/src/widgets/group_pending_requests_card.dart';
import 'package:cl_club_members/src/widgets/group_rename_dialog.dart';
import 'package:cl_club_members/src/widgets/removed_group_view.dart';
import 'package:cl_member_auth/cl_member_auth.dart'
    show authStateProvider, imageAuthHeadersProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show
        clGroupsMasterProvider,
        groupImageProvider,
        groupMediaMutationProvider,
        imagePickerProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart'
    show
        ActionButton,
        ConfirmDialog,
        CredentialedNetworkImage,
        EditableMarkdown,
        ImageUploadAffordance,
        LoadingView,
        ThemedMarkdown,
        TitleRow,
        pickAndConfirmImage;

/// Admin-aware wrapper around [GroupProfileView].
///
/// Reads [authStateProvider] to determine the current user's role and
/// conditionally passes admin-only callbacks. Callers provide only
/// navigation callbacks.
class AdminGroupProfileView extends ConsumerWidget {
  const AdminGroupProfileView({
    required this.groupId,
    required this.onOpenRequests,
    required this.onOpenAllMembers,
    required this.onDeleted,
    this.sourceNotificationId,
    this.onMemberTap,
    this.onBack,
    this.onHistory,
    super.key,
  });

  final int groupId;
  final int? sourceNotificationId;

  final VoidCallback onOpenRequests;
  final VoidCallback onOpenAllMembers;

  /// Opens the group's audit history (admin-only affordance, issue #207).
  final VoidCallback? onHistory;

  /// Invoked after the group is (soft- or hard-) deleted. The host screen
  /// owns navigation away from this now-defunct profile.
  final VoidCallback onDeleted;
  final void Function(GroupMember member)? onMemberTap;
  final VoidCallback? onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authStateProvider).valueOrNull;
    final isAdmin = auth?.isAdmin ?? false;

    return GroupProfileView(
      groupId: groupId,
      sourceNotificationId: sourceNotificationId,
      onBack: onBack,
      onRemoved: onDeleted,
      onMemberTap: onMemberTap,
      onOpenRequests: onOpenRequests,
      onOpenAllMembers: onOpenAllMembers,
      onHistory: onHistory,
      onDescriptionSave: isAdmin
          ? (value) => handleDescriptionSave(ref, context, value)
          : null,
      onStatusAction: isAdmin
          ? (action) => handleStatusAction(ref, context, action)
          : null,
    );
  }

  Future<void> handleDescriptionSave(
    WidgetRef ref,
    BuildContext context,
    String value,
  ) async {
    try {
      final trimmed = value.trim();
      await ref
          .read(clGroupsMasterProvider.notifier)
          .updateGroup(
            groupId,
            description: () => trimmed.isEmpty ? null : trimmed,
          );
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        const ShadToast(description: Text('Description updated.')),
      );
    } on Object catch (_) {
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          description: Text('Could not save description.'),
        ),
      );
    }
  }

  Future<void> handleStatusAction(
    WidgetRef ref,
    BuildContext context,
    String action,
  ) async {
    switch (action) {
      case 'rename':
        await handleRename(ref, context);
        return;
      case 'delete':
        await handleDelete(ref, context);
        return;
      case 'restore':
        await handleRestore(ref, context);
        return;
      case 'hardDelete':
        await handleHardDelete(ref, context);
        return;
    }
  }

  /// Shown on the name field of the rename dialog when the save is refused.
  static const String renameFailedMessage = 'Could not rename group.';

  /// Renames the group through the rename dialog, which stays open until the
  /// name is saved; a refusal shows on its field.
  Future<void> handleRename(WidgetRef ref, BuildContext context) async {
    final group = ref.read(clGroupsMasterProvider).valueOrNull?[groupId];
    if (group == null) return;
    final toaster = ShadToaster.of(context);
    final newName = await showGroupRenameDialog(
      context,
      group.name,
      onSave: (name) => writeName(ref, name),
    );
    if (newName == null) return;
    toaster.show(const ShadToast(description: Text('Group renamed.')));
  }

  /// Writes [name]; `null` once saved, else the refusal, said for people.
  Future<String?> writeName(WidgetRef ref, String name) async {
    try {
      await ref
          .read(clGroupsMasterProvider.notifier)
          .updateGroup(groupId, name: name);
      return null;
    } on Object catch (_) {
      return renameFailedMessage;
    }
  }

  Future<void> handleRestore(WidgetRef ref, BuildContext context) async {
    try {
      await ref.read(clGroupsMasterProvider.notifier).restoreGroup(groupId);
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        const ShadToast(description: Text('Group restored.')),
      );
    } on Object catch (_) {
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          description: Text('Could not restore group.'),
        ),
      );
    }
  }

  Future<void> handleDelete(WidgetRef ref, BuildContext context) async {
    final group = ref.read(clGroupsMasterProvider).valueOrNull?[groupId];
    if (group == null) return;
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Delete group?',
      message:
          'This will soft-delete "${group.name}". It can be restored later.',
      confirmLabel: 'Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(clGroupsMasterProvider.notifier).deleteGroup(groupId);
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        const ShadToast(description: Text('Group deleted.')),
      );
      onDeleted();
    } on Object catch (_) {
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          description: Text('Could not delete group.'),
        ),
      );
    }
  }

  Future<void> handleHardDelete(WidgetRef ref, BuildContext context) async {
    final group = ref.read(clGroupsMasterProvider).valueOrNull?[groupId];
    if (group == null) return;
    final confirmed = await ConfirmDialog.show(
      context,
      title: 'Permanently delete?',
      message:
          'This will permanently delete "${group.name}" and all its data. '
          'This cannot be undone.',
      confirmLabel: 'Permanently Delete',
      destructive: true,
    );
    if (!confirmed || !context.mounted) return;

    try {
      await ref.read(clGroupsMasterProvider.notifier).hardDeleteGroup(groupId);
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        const ShadToast(description: Text('Group permanently deleted.')),
      );
      onDeleted();
    } on ServerException catch (e) {
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(groupHardDeleteErrorMessage(e)),
        ),
      );
    } on Object catch (_) {
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          description: Text('Could not delete group.'),
        ),
      );
    }
  }
}

/// Group detail view — description, pending requests (semi-auto + admin),
/// member list, management actions, and group info card. No Scaffold; host
/// provides the shell.
class GroupProfileView extends ConsumerWidget {
  const GroupProfileView({
    required this.groupId,
    required this.onRemoved,
    this.sourceNotificationId,
    this.onDescriptionSave,
    this.onStatusAction,
    this.onMemberTap,
    this.onOpenRequests,
    this.onOpenAllMembers,
    this.onBack,
    this.onHistory,
    super.key,
  });

  final int groupId;
  final int? sourceNotificationId;

  /// Invoked when this group no longer exists and its stale notification is
  /// cleared — the host navigates away from the defunct profile.
  final VoidCallback onRemoved;

  /// Called with the new description markdown. If null, description is
  /// read-only.
  final ValueChanged<String>? onDescriptionSave;

  /// Called with an admin action key (`rename`, `delete`, `restore`,
  /// `hardDelete`). If null, the management section is hidden.
  final ValueChanged<String>? onStatusAction;

  final void Function(GroupMember member)? onMemberTap;

  /// Opens the full join-requests page. If null, the link icon is hidden.
  final VoidCallback? onOpenRequests;

  /// Opens the full members page. If null, the link icon is hidden.
  final VoidCallback? onOpenAllMembers;

  final VoidCallback? onBack;

  /// Opens the group's audit history. The title-row affordance is shown only
  /// to admins (issue #207).
  final VoidCallback? onHistory;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final auth = ref.watch(authStateProvider).valueOrNull;
    final isAdmin = auth?.isAdmin ?? false;
    final isSuperAdmin = auth?.isSuperAdmin ?? false;

    final masterAsync = ref.watch(clGroupsMasterProvider);

    return masterAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => Center(child: Text('Could not load group: $e')),
      data: (groups) {
        final group = groups[groupId];
        if (group == null) {
          return RemovedGroupView(
            groupId: groupId,
            sourceNotificationId: sourceNotificationId,
            onDismissed: onRemoved,
          );
        }

        final canEditDescription =
            isAdmin && group.isActive && onDescriptionSave != null;
        // Auto groups compute membership from criteria — the server rejects
        // join requests against them, so there's nothing to show or manage.
        // Manual + semi-auto groups can both accumulate requests, so we
        // surface the card (with an empty state when none are pending) for
        // those kinds.
        final showPending =
            isAdmin &&
            group.isActive &&
            group.kind != GroupKind.auto &&
            onOpenRequests != null;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitleRow(
              title: group.name,
              onBack: onBack,
              onHistory: isAdmin ? onHistory : null,
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if ((isAdmin || isSuperAdmin) && group.isActive) ...[
                      GroupMessageSection(
                        groupId: group.id,
                        groupName: group.name,
                      ),
                      const SizedBox(height: 20),
                    ],
                    GroupHeroImage(
                      groupId: group.id,
                      canEdit: isAdmin && group.isActive,
                    ),
                    const SizedBox(height: 20),
                    ShadCard(
                      padding: const EdgeInsets.all(20),
                      child: canEditDescription
                          ? EditableMarkdown(
                              data: group.description ?? '',
                              label: 'Description',
                              emptyText: 'Tap to add description',
                              onSave: onDescriptionSave!,
                            )
                          : (group.description != null &&
                                group.description!.isNotEmpty)
                          ? ThemedMarkdown(
                              data: group.description!,
                              textAlign: TextAlign.justify,
                            )
                          : Text(
                              'No description.',
                              style: theme.textTheme.muted,
                            ),
                    ),

                    const SizedBox(height: 20),
                    GroupEligibilitySection(
                      group: group,
                      canEdit: isAdmin && group.isActive,
                    ),

                    if (showPending) ...[
                      const SizedBox(height: 20),
                      GroupPendingRequestsCard(
                        groupId: groupId,
                        onOpenAll: onOpenRequests!,
                      ),
                    ],

                    const SizedBox(height: 20),

                    ShadCard(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (isAdmin &&
                              group.allowsManualMembership &&
                              group.isActive)
                            Align(
                              alignment: Alignment.centerRight,
                              child: ActionButton(
                                label: '+ Add member',
                                onPressed: () => handleAddMember(context),
                              ),
                            ),
                          GroupMemberList(
                            groupId: groupId,
                            kind: group.kind,
                            isAdmin: isAdmin && group.isActive,
                            onMemberTap: onMemberTap,
                            maxHeight: 320,
                            onOpenAll: onOpenAllMembers,
                          ),
                        ],
                      ),
                    ),

                    if (onStatusAction != null) ...[
                      const SizedBox(height: 20),
                      GroupManagementSection(
                        group: group,
                        isSuperAdmin: isSuperAdmin,
                        onStatusAction: onStatusAction,
                      ),
                    ],

                    const SizedBox(height: 20),
                    GroupInfoSection(group: group),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> handleAddMember(BuildContext context) async {
    // AddMemberDialog.show already invalidates clGroupMembersProvider and
    // clEligibleUsersProvider on its success path, so there is nothing more
    // to do here. The previous explicit ref.invalidate ran *after* the
    // dialog's async gap and threw "Cannot use ref after the widget was
    // disposed" when the view had been disposed mid-flow (#616).
    await AddMemberDialog.show(context, groupId: groupId);
  }
}

/// Cover-style hero for a group, rendering the `group_image` media from the v2
/// media link table via [groupImageProvider] + [CredentialedNetworkImage].
/// Falls back to a centered `users` icon on a muted background when no image is
/// set or it fails to load. Admins see the [GroupImageUploadAffordance]
/// overlaid top-right to replace / remove it.
class GroupHeroImage extends ConsumerWidget {
  const GroupHeroImage({
    required this.groupId,
    required this.canEdit,
    super.key,
  });

  final int groupId;
  final bool canEdit;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final placeholder = ColoredBox(
      color: theme.colorScheme.muted,
      child: Center(
        child: Icon(
          LucideIcons.users,
          size: 56,
          color: theme.colorScheme.mutedForeground,
        ),
      ),
    );
    final url = ref.watch(groupImageProvider(groupId)).valueOrNull;
    final headers = ref.watch(imageAuthHeadersProvider).valueOrNull ?? const {};
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        height: 200,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (url == null)
              placeholder
            else
              ColoredBox(
                color: theme.colorScheme.muted,
                child: CredentialedNetworkImage(
                  imageUrl: url,
                  httpHeaders: headers,
                  fit: BoxFit.cover,
                  errorBuilder: (_) => placeholder,
                ),
              ),
            if (canEdit)
              Positioned(
                top: 12,
                right: 12,
                child: GroupImageUploadAffordance(groupId: groupId),
              ),
          ],
        ),
      ),
    );
  }
}

/// Connected affordance wrapping the shared [ImageUploadAffordance]: wires the
/// group media provider, owns the pick→confirm→upload call and its error
/// toast. The re-entrancy guard and disable/spinner split live in the shared
/// widget.
class GroupImageUploadAffordance extends ConsumerWidget {
  const GroupImageUploadAffordance({required this.groupId, super.key});

  final int groupId;

  Future<void> _replace(BuildContext context, WidgetRef ref) async {
    final picked = await pickAndConfirmImage(
      context,
      picker: ref.read(imagePickerProvider),
    );
    if (picked == null || !context.mounted) return;
    try {
      await ref
          .read(groupMediaMutationProvider(groupId).notifier)
          .uploadImage(
            bytes: picked.bytes,
            filename: picked.filename,
            contentType: picked.mimeType,
          );
    } on Object catch (_) {
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          description: Text('Could not update image. Please try again.'),
        ),
      );
    }
  }

  Future<void> _remove(BuildContext context, WidgetRef ref) async {
    try {
      await ref.read(groupMediaMutationProvider(groupId).notifier).clearImage();
    } on Object catch (_) {
      if (!context.mounted) return;
      ShadToaster.of(context).show(
        const ShadToast.destructive(
          description: Text('Could not remove image. Please try again.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uploading = ref.watch(groupMediaMutationProvider(groupId)).isLoading;
    final hasImage = ref.watch(groupImageProvider(groupId)).valueOrNull != null;
    return ImageUploadAffordance(
      uploading: uploading,
      onReplace: () => _replace(context, ref),
      onRemove: hasImage ? () => _remove(context, ref) : null,
    );
  }
}
