import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../user_selection_dialog.dart' show PickerUser;
import 'event_form_fields.dart';

/// Picks a new organizer. Returns the chosen user, or `null` on cancel.
typedef PickOrganizer = Future<PickerUser?> Function();

/// Picks additional coaches, given the set of usernames to exclude (those
/// already staged). Returns the chosen users, or `null` on cancel.
typedef PickCoaches = Future<List<PickerUser>?> Function(Set<String> exclude);

/// Pure-UI editor for an event's organizer and coaches, driven entirely by
/// pickers (no free-text entry).
///
/// * Organizer is always present and changed via a **Transfer** action.
/// * Coaches are a list with per-row removal shown as a strikethrough + Undo
///   (so a removal can be reverted before saving), plus an **Add coaches**
///   action.
///
/// All edits are staged locally; the host's Save reads the editor state. The
/// host
/// supplies the candidate pickers (`onPickOrganizer` / `onPickCoaches`) so this
/// widget stays SDK- and Riverpod-free.
class OrganizerCoachesEditor extends StatefulWidget {
  const OrganizerCoachesEditor({
    required this.initialOrganizer,
    required this.initialCoaches,
    required this.onPickOrganizer,
    required this.onPickCoaches,
    super.key,
  });

  final PickerUser initialOrganizer;
  final List<PickerUser> initialCoaches;
  final PickOrganizer onPickOrganizer;
  final PickCoaches onPickCoaches;

  @override
  State<OrganizerCoachesEditor> createState() => OrganizerCoachesEditorState();
}

class OrganizerCoachesEditorState extends State<OrganizerCoachesEditor> {
  late PickerUser _organizer = widget.initialOrganizer;
  late final List<PickerUser> _coaches = [...widget.initialCoaches];
  final Set<String> _removed = <String>{};

  List<String> get _finalCoachUsernames => _coaches
      .where((c) => !_removed.contains(c.username))
      .map((c) => c.username)
      .toList();

  /// Returns the staged organizer + coach usernames keyed by [EventFormFields].
  Map<String, dynamic> validate() => {
    EventFormFields.organizerNameId: _organizer.username,
    EventFormFields.coachNamesId: _finalCoachUsernames,
  };

  /// Whether the staged organizer or final coach set differs from the seed.
  bool get isDirty {
    if (_organizer.username != widget.initialOrganizer.username) return true;
    final initial = widget.initialCoaches.map((c) => c.username).toList();
    final current = _finalCoachUsernames;
    if (current.length != initial.length) return true;
    return !current.toSet().containsAll(initial);
  }

  Future<void> _transfer() async {
    final picked = await widget.onPickOrganizer();
    if (picked != null && mounted) setState(() => _organizer = picked);
  }

  Future<void> _addCoaches() async {
    final exclude = _coaches.map((c) => c.username).toSet();
    final picked = await widget.onPickCoaches(exclude);
    if (picked == null || !mounted) return;
    setState(() {
      for (final u in picked) {
        if (_coaches.every((c) => c.username != u.username)) _coaches.add(u);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('Organizer', style: theme.textTheme.small),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _UserLine(user: _organizer)),
            const SizedBox(width: 8),
            ShadButton.outline(
              onPressed: _transfer,
              leading: const Icon(LucideIcons.userCog, size: 16),
              child: const Text('Transfer'),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Text('Coaches', style: theme.textTheme.small),
        const SizedBox(height: 8),
        if (_coaches.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Text('No coaches assigned.', style: theme.textTheme.muted),
          )
        else
          for (final coach in _coaches) ...[
            _CoachRow(
              user: coach,
              removed: _removed.contains(coach.username),
              onRemove: () => setState(() => _removed.add(coach.username)),
              onUndo: () => setState(() => _removed.remove(coach.username)),
            ),
            const SizedBox(height: 8),
          ],
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerLeft,
          child: ShadButton.outline(
            onPressed: _addCoaches,
            leading: const Icon(LucideIcons.plus, size: 16),
            child: const Text('Add coaches'),
          ),
        ),
      ],
    );
  }
}

/// An avatar + name + @username line for a picked user.
class _UserLine extends StatelessWidget {
  const _UserLine({required this.user, this.strikethrough = false});

  final PickerUser user;
  final bool strikethrough;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final decoration = strikethrough ? TextDecoration.lineThrough : null;
    final color = strikethrough ? theme.colorScheme.mutedForeground : null;
    return Row(
      children: [
        CircleAvatar(
          radius: 14,
          backgroundColor: theme.colorScheme.muted,
          child: Text(
            user.initials,
            style: TextStyle(
              color: theme.colorScheme.mutedForeground,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                user.displayName,
                style: theme.textTheme.p.copyWith(
                  decoration: decoration,
                  color: color,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                '@${user.username}',
                style: theme.textTheme.muted.copyWith(
                  fontSize: 11,
                  decoration: decoration,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// A coach row with a remove (✕) affordance, or — when staged for removal — a
/// strikethrough with an Undo action.
class _CoachRow extends StatelessWidget {
  const _CoachRow({
    required this.user,
    required this.removed,
    required this.onRemove,
    required this.onUndo,
  });

  final PickerUser user;
  final bool removed;
  final VoidCallback onRemove;
  final VoidCallback onUndo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _UserLine(user: user, strikethrough: removed),
        ),
        const SizedBox(width: 8),
        if (removed)
          ShadButton.ghost(
            onPressed: onUndo,
            leading: const Icon(LucideIcons.undo2, size: 16),
            child: const Text('Undo'),
          )
        else
          ShadButton.ghost(
            onPressed: onRemove,
            child: const Icon(LucideIcons.x, size: 16),
          ),
      ],
    );
  }
}
