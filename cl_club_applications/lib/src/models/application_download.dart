import 'package:cl_remote_store/cl_remote_store.dart'
    show ClApplicationsMasterNotifier;
import 'package:flutter/foundation.dart';

/// Which PDF of an application a download button fetches: the signed-in
/// member's own form, a member's form for an admin, or an admin's preview.
@immutable
sealed class ApplicationDownload {
  const ApplicationDownload(this.applicationId);

  /// The application template's id.
  final int applicationId;

  /// Fetches the PDF through [notifier], ticking age category [category]
  /// when given (club_client#337).
  Future<Uint8List> fetch(
    ClApplicationsMasterNotifier notifier, {
    int? category,
  });
}

/// The signed-in member's own form of a published application.
final class ApplicationOwnForm extends ApplicationDownload {
  const ApplicationOwnForm(super.applicationId);

  @override
  Future<Uint8List> fetch(
    ClApplicationsMasterNotifier notifier, {
    int? category,
  }) => notifier.downloadOwnForm(applicationId, category: category);
}

/// [username]'s form of a published application, for an admin.
final class ApplicationMemberForm extends ApplicationDownload {
  const ApplicationMemberForm(super.applicationId, this.username);

  /// The member whose form it is.
  final String username;

  @override
  Future<Uint8List> fetch(
    ClApplicationsMasterNotifier notifier, {
    int? category,
  }) => notifier.downloadMemberForm(
    applicationId,
    username,
    category: category,
  );
}

/// The application drawn for the server's demo member, for an admin. It
/// ticks the server's own choice, so [fetch] takes no category.
final class ApplicationPreview extends ApplicationDownload {
  const ApplicationPreview(super.applicationId);

  @override
  Future<Uint8List> fetch(
    ClApplicationsMasterNotifier notifier, {
    int? category,
  }) => notifier.downloadPreview(applicationId);
}
