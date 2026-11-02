import 'selected_occurrence.dart';

/// A session's place in its day's column of the week view: `lane` counted
/// from the left, out of `lanes` side by side for the group of sessions
/// that overlap it (club_client#420).
typedef SessionLane = ({SelectedOccurrence item, int lane, int lanes});
