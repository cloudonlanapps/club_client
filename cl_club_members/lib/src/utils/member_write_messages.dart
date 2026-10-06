/// Fixed messages for member and group writes that fail with no more
/// specific explanation. A write that may have landed shows
/// `uncertainWriteMessage` (cl_remote_store) instead; the raw error is never
/// shown (club_core#138).
abstract final class MemberWriteMessages {
  /// A user or group card action (unblock, reactivate, delete, restore).
  static const actionFailed = 'Could not complete the action. Try again.';

  /// Adding one member to a group.
  static const addToGroupFailed = 'Could not add to the group. Try again.';

  /// Adding several members to a group.
  static const addMembersFailed = 'Could not add the members. Try again.';

  /// Replacing a profile photo.
  static const photoFailed = "Couldn't update the photo. Try again.";

  /// Making the current profile photo public or private.
  static const photoVisibilityFailed =
      "Couldn't change who can see the photo. Try again.";

  /// Label of the tick that makes a member's profile photo public.
  static const allowOthersToSeePhoto = 'Allow others to see my photo';

  /// Approving a group join request.
  static const approveRequestFailed = 'Could not approve the request.';

  /// Rejecting a group join request.
  static const rejectRequestFailed = 'Could not reject the request.';

  /// Sending a group join request.
  static const sendRequestFailed = 'Could not send the request. Try again.';

  /// Cancelling a group join request.
  static const cancelRequestFailed = 'Could not cancel the request.';

  /// Sending a message to a group.
  static const sendMessageFailed = 'Could not send the message. Try again.';

  /// Creating a user.
  static const createUserFailed = 'Could not create user.';

  /// Approving, sending back or blocking an application under review.
  static const reviewDecisionFailed = 'Could not record the decision.';

  /// Dismissing a notification.
  static const dismissFailed = 'Could not dismiss the notification.';
}
