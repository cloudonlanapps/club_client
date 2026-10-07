import 'package:shadcn_ui/shadcn_ui.dart';

import '../../models/event_staff_member.dart';
import '../../models/event_staff_pickers.dart';
import 'event_staff_coach_list.dart';

/// `ShadForm` field for an event's coaches. Its value is the list of coaches
/// the event keeps: a coach whose row is removed leaves the value at once,
/// while the row stays, struck through, until the form closes, so **Undo**
/// can put the coach back. **Add coaches** asks [onPick] for more.
class EventStaffCoachesField
    extends ShadFormBuilderField<List<EventStaffMember>> {
  EventStaffCoachesField({
    required this.onPick,
    super.id,
    super.initialValue,
    super.validator,
    super.enabled,
    super.key,
  }) : super(
         builder: (field) {
           final state = field as EventStaffCoachesFieldState;
           return EventStaffCoachList(
             coaches: state.coaches,
             removed: state.removed,
             enabled: state.enabled,
             onRemove: state.remove,
             onUndo: state.undo,
             onAdd: state.add,
           );
         },
       );

  /// Picks the coaches to add, given the usernames already listed.
  final PickCoaches onPick;

  @override
  EventStaffCoachesFieldState createState() => EventStaffCoachesFieldState();
}

/// State of [EventStaffCoachesField]: the rows shown and which of them are
/// staged for removal. The field's value is the rows less those.
class EventStaffCoachesFieldState
    extends
        ShadFormBuilderFieldState<
          EventStaffCoachesField,
          List<EventStaffMember>
        > {
  /// Every coach with a row, in the order shown.
  List<EventStaffMember> coaches = const [];

  /// Usernames of the coaches staged for removal.
  Set<String> removed = const {};

  @override
  void initState() {
    super.initState();
    coaches = [...?value];
  }

  /// Stages the coach [username] for removal.
  void remove(String username) {
    removed = {...removed, username};
    didChange(kept);
  }

  /// Takes back the staged removal of the coach [username].
  void undo(String username) {
    removed = {...removed}..remove(username);
    didChange(kept);
  }

  /// Asks the picker for more coaches and appends those not yet listed.
  Future<void> add() async {
    final listed = {for (final coach in coaches) coach.username};
    final picked = await widget.onPick(listed);
    if (picked == null || !mounted) return;
    final added = <EventStaffMember>[];
    for (final coach in picked) {
      if (listed.add(coach.username)) added.add(coach);
    }
    coaches = [...coaches, ...added];
    didChange(kept);
  }

  /// The coaches the event keeps: the rows not staged for removal.
  List<EventStaffMember> get kept => [
    for (final coach in coaches)
      if (!removed.contains(coach.username)) coach,
  ];

  @override
  void reset() {
    coaches = [...?initialValue];
    removed = const {};
    super.reset();
  }
}
