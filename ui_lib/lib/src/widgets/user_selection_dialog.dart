import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'user_selection_tile.dart';

/// Minimal user representation used by [UserSelectionDialogContent].
///
/// Decouples the picker from any specific domain model. Callers map their
/// SDK objects (UserInfo, EligibleUser, …) to a list of [PickerUser]s.
@immutable
class PickerUser {
  const PickerUser({
    required this.username,
    required this.displayName,
    this.firstName,
    this.lastName,
    this.nickname,
    this.isAdmin = false,
    this.isCoach = false,
  });

  final String username;
  final String displayName;
  final String? firstName;
  final String? lastName;
  final String? nickname;

  /// Role flags used by the picker's role filter. A user with neither flag
  /// is treated as a regular member — every user in the system is a member
  /// by default, so there is no separate `isMember` field.
  final bool isAdmin;
  final bool isCoach;

  bool get isPlainMember => !isAdmin && !isCoach;

  /// Short label shown next to the user's name in the picker tile.
  /// Admin trumps coach; plain members render no label.
  String? get roleLabel {
    if (isAdmin) return 'Admin';
    if (isCoach) return 'Coach';
    return null;
  }

  bool matches(String term) {
    if (term.isEmpty) return true;
    final lower = term.toLowerCase();
    return displayName.toLowerCase().contains(lower) ||
        username.toLowerCase().contains(lower) ||
        (firstName?.toLowerCase().contains(lower) ?? false) ||
        (lastName?.toLowerCase().contains(lower) ?? false) ||
        (nickname?.toLowerCase().contains(lower) ?? false);
  }

  String get initials {
    final parts = displayName
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.characters.first.toUpperCase();
    }
    return (parts.first.characters.first + parts.last.characters.first)
        .toUpperCase();
  }
}

/// Shows a user picker. Returns the chosen usernames, or null if the user
/// cancelled. Callers pre-filter [users] (e.g. by enrolment status,
/// eligibility, role) — the dialog only handles selection UX.
///
/// When [singleSelect] is true the picker behaves like a radio group: tapping
/// a tile replaces the selection, and the result is a single-element list.
Future<List<String>?> showUserSelectionDialog(
  BuildContext context, {
  required String title,
  required List<PickerUser> users,
  String? description,
  String confirmLabel = 'Select',
  String emptyText = 'No users available.',
  bool showRoleFilter = true,
  bool singleSelect = false,
}) {
  return showShadDialog<List<String>>(
    context: context,
    builder: (_) => UserSelectionDialogContent(
      title: title,
      users: users,
      description: description,
      confirmLabel: confirmLabel,
      emptyText: emptyText,
      showRoleFilter: showRoleFilter,
      singleSelect: singleSelect,
    ),
  );
}

class UserSelectionDialogContent extends StatefulWidget {
  const UserSelectionDialogContent({
    required this.title,
    required this.users,
    this.description,
    this.confirmLabel = 'Select',
    this.emptyText = 'No users available.',
    this.showRoleFilter = true,
    this.singleSelect = false,
    this.blockedUsernames = const {},
    this.trailingBuilder,
    super.key,
  });

  final String title;
  final List<PickerUser> users;

  /// Users shown dimmed and not selectable, e.g. a member who cannot be
  /// funded (club_core#105). The host can rebuild the content with a new
  /// set; a user it unblocks becomes selectable in place.
  final Set<String> blockedUsernames;

  /// A widget shown beside a user's tile, typically why they are blocked
  /// and how to fix it. Null, or returning null, shows nothing.
  final Widget? Function(String username)? trailingBuilder;
  final String? description;
  final String confirmLabel;
  final String emptyText;

  /// When false, the role-filter popover and its predicate are skipped.
  /// Use for pickers whose source list is already authoritative (e.g.
  /// the event picker, where the server's `listEligible` enforces both
  /// criteria and any role-based exclusions).
  final bool showRoleFilter;

  /// When true, only one user can be selected at a time (radio-like) and the
  /// confirm button omits the selected-count suffix.
  final bool singleSelect;

  @override
  State<UserSelectionDialogContent> createState() =>
      UserSelectionDialogContentState();
}

/// Role categories the picker can filter on. Each [PickerUser] is matched
/// against the active set: a row passes when at least one of its role
/// flags is currently enabled.
enum PickerRoleFilter {
  admin('Team Administrators'),
  coach('Coaches'),
  member('Members');

  const PickerRoleFilter(this.label);

  final String label;
}

class UserSelectionDialogContentState
    extends State<UserSelectionDialogContent> {
  final Set<String> selected = <String>{};
  final popoverController = ShadPopoverController();
  String searchTerm = '';
  Set<PickerRoleFilter> roleFilter = {PickerRoleFilter.member};

  @override
  void dispose() {
    popoverController.dispose();
    super.dispose();
  }

  bool _matchesRoleFilter(PickerUser u) {
    if (roleFilter.contains(PickerRoleFilter.admin) && u.isAdmin) return true;
    if (roleFilter.contains(PickerRoleFilter.coach) && u.isCoach) return true;
    if (roleFilter.contains(PickerRoleFilter.member) && u.isPlainMember) {
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final filtered = widget.users
        .where((u) => !widget.showRoleFilter || _matchesRoleFilter(u))
        .where((u) => u.matches(searchTerm.trim()))
        .toList();

    return ShadDialog(
      title: Text(widget.title),
      description: widget.description != null
          ? Text(widget.description!)
          : null,
      actions: [
        ShadButton.outline(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ShadButton(
          onPressed: selectable.isEmpty
              ? null
              : () => Navigator.of(context).pop(selectable.toList()),
          child: Text(
            selectable.isEmpty || widget.singleSelect
                ? widget.confirmLabel
                : '${widget.confirmLabel} (${selectable.length})',
          ),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: ShadInput(
                  placeholder: const Text('Search by name…'),
                  keyboardType: TextInputType.text,
                  autocorrect: false,
                  enableSuggestions: false,
                  onChanged: (value) => setState(() => searchTerm = value),
                ),
              ),
              if (widget.showRoleFilter) ...[
                const SizedBox(width: 8),
                RoleFilterPopover(
                  controller: popoverController,
                  selected: roleFilter,
                  onChanged: (value) => setState(() => roleFilter = value),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          if (filtered.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                widget.users.isEmpty ? widget.emptyText : 'No matches.',
                style: theme.textTheme.muted,
              ),
            )
          else
            ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 300),
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: filtered.map(tileFor).toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// The selection minus anyone blocked since they were picked.
  Set<String> get selectable => selected.difference(widget.blockedUsernames);

  Widget tileFor(PickerUser u) {
    final blocked = widget.blockedUsernames.contains(u.username);
    final tile = UserSelectionTile(
      user: u,
      selected: !blocked && selected.contains(u.username),
      blocked: blocked,
      onTap: blocked ? null : () => toggle(u.username),
    );
    final trailing = widget.trailingBuilder?.call(u.username);
    if (trailing == null) return tile;
    return Row(
      mainAxisSize: MainAxisSize.min,
      spacing: 4,
      children: [tile, trailing],
    );
  }

  void toggle(String username) {
    setState(() {
      if (selected.contains(username)) {
        selected.remove(username);
      } else {
        if (widget.singleSelect) selected.clear();
        selected.add(username);
      }
    });
  }
}

class RoleFilterPopover extends StatelessWidget {
  const RoleFilterPopover({
    required this.controller,
    required this.selected,
    required this.onChanged,
    super.key,
  });

  final ShadPopoverController controller;
  final Set<PickerRoleFilter> selected;
  final ValueChanged<Set<PickerRoleFilter>> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadPopover(
      controller: controller,
      popover: (context) => Padding(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          width: 220,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Show roles', style: theme.textTheme.small),
              const SizedBox(height: 6),
              for (final role in PickerRoleFilter.values)
                RoleCheckboxRow(
                  label: role.label,
                  checked: selected.contains(role),
                  onChanged: (value) {
                    final next = {...selected};
                    if (value) {
                      next.add(role);
                    } else {
                      next.remove(role);
                    }
                    onChanged(next);
                  },
                ),
            ],
          ),
        ),
      ),
      child: ShadButton.outline(
        size: ShadButtonSize.sm,
        onPressed: controller.toggle,
        leading: const Icon(LucideIcons.listFilter, size: 14),
        child: Text('Filter (${selected.length})'),
      ),
    );
  }
}

class RoleCheckboxRow extends StatelessWidget {
  const RoleCheckboxRow({
    required this.label,
    required this.checked,
    required this.onChanged,
    super.key,
  });

  final String label;
  final bool checked;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => onChanged(!checked),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          children: [
            ShadCheckbox(value: checked, onChanged: onChanged),
            const SizedBox(width: 10),
            Expanded(child: Text(label, style: theme.textTheme.p)),
          ],
        ),
      ),
    );
  }
}
