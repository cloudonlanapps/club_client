import 'package:cl_club_events/src/models/event_management_messages.dart';
import 'package:cl_club_events/src/utils/event_management_error.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

/// The refusals of Event Management read as fixed messages, keyed on the
/// SDK's codes (club_client#90).
void main() {
  const fallback = 'Could not unarchive the event.';

  test('Issue 90: a restore refused with SdkErrorCode.venueIsDeleted reads '
      'the venue-is-deleted message', () {
    const refused = ServerException(
      statusCode: 400,
      code: SdkErrorCode.venueIsDeleted,
      message: 'Cannot restore event: venue is deleted',
    );

    expect(
      eventManagementErrorMessage(refused, fallback: fallback),
      EventManagementMessages.venueIsDeleted,
    );
  });

  test('Issue 90: the code is the one the server sends', () {
    expect(SdkErrorCode.venueIsDeleted, 'VENUE_IS_DELETED');
  });
}
