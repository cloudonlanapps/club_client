import 'package:flutter/material.dart' show DateUtils;

/// The calendar's selected day, as the viewer's local date.
///
/// cl_calendar seeds the selection with `DateTime.now().toUtc()`, whose date
/// is the UTC one: around local midnight that is a day off the viewer's, and
/// today's sessions would be listed under the wrong day (club_client#300).
DateTime selectedLocalDay(DateTime selected) =>
    DateUtils.dateOnly(selected.toLocal());
