import 'package:cl_club_members/src/widgets/add_member_dialog.dart';
import 'package:cl_club_members/src/widgets/group_member_list.dart';
import 'package:cl_club_members/src/widgets/removed_group_view.dart';
import 'package:cl_member_auth/cl_member_auth.dart' show authStateProvider;
import 'package:cl_remote_store/cl_remote_store.dart'
    show clGroupMembersProvider, clGroupsMasterProvider;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ActionButton, LoadingView, TitleRow;

/// Full-page members list for a group. Reached via the "open full list"
/// icon next to the Members heading on the group profile view.
class GroupMembersView extends ConsumerStatefulWidget {
  const GroupMembersView({
    required this.groupId,
    required this.onRemoved,
    this.onMemberTap,
    this.onBack,
    super.key,
  });

  final int groupId;

  /// Invoked when the group no longer exists — the host navigates away.
  final VoidCallback onRemoved;
  final void Function(GroupMember member)? onMemberTap;
  final VoidCallback? onBack;

  @override
  ConsumerState<GroupMembersView> createState() => GroupMembersViewState();
}

class GroupMembersViewState extends ConsumerState<GroupMembersView> {
  String searchTerm = '';

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authStateProvider).valueOrNull;
    final isAdmin = auth?.isAdmin ?? false;
    final masterAsync = ref.watch(clGroupsMasterProvider);

    return masterAsync.when(
      loading: () => const LoadingView(),
      error: (e, _) => Center(child: Text('Could not load group: $e')),
      data: (groups) {
        final group = groups[widget.groupId];
        if (group == null) {
          return RemovedGroupView(
            groupId: widget.groupId,
            onDismissed: widget.onRemoved,
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TitleRow(
              title: group.name,
              subtitle: 'Members',
              onBack: widget.onBack,
            ),
            const Divider(height: 1),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: ShadCard(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: ShadInput(
                              initialValue: searchTerm,
                              placeholder: const Text(
                                'Search members by name or username…',
                              ),
                              keyboardType: TextInputType.text,
                              autocorrect: false,
                              enableSuggestions: false,
                              onChanged: (value) =>
                                  setState(() => searchTerm = value),
                            ),
                          ),
                          if (isAdmin &&
                              group.allowsManualMembership &&
                              group.isActive) ...[
                            const SizedBox(width: 12),
                            ActionButton(
                              label: '+ Add member',
                              onPressed: () => handleAddMember(context),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 16),
                      GroupMemberList(
                        groupId: widget.groupId,
                        kind: group.kind,
                        isAdmin: isAdmin && group.isActive,
                        onMemberTap: widget.onMemberTap,
                        searchTerm: searchTerm,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> handleAddMember(BuildContext context) async {
    final added = await AddMemberDialog.show(context, groupId: widget.groupId);
    if (added) {
      ref.invalidate(clGroupMembersProvider(widget.groupId));
    }
  }
}
