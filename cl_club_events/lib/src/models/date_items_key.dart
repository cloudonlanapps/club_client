import 'package:cl_calendar/cl_calendar.dart';

/// Record type for date-based family keys (dateItemsProvider,
/// selectedOccurrenceDetailsProvider).
typedef DateItemsKey = ({
  DateTime date,
  CalendarViewRange range,
});
