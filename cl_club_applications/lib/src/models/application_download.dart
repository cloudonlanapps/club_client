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

  /// Fetches the PDF through [notifier].
  Future<Uint8List> fetch(ClApplicationsMasterNotifier notifier);
}

/// The signed-in member's own form of a published application.
final class ApplicationOwnForm extends ApplicationDownload {
  const ApplicationOwnForm(super.applicationId);

  @override
  Future<Uint8List> fetch(ClApplicationsMasterNotifier notifier) =>
      notifier.downloadOwnForm(applicationId);
}

/// [username]'s form of a published application, for an admin.
final class ApplicationMemberForm extends ApplicationDownload {
  const ApplicationMemberForm(super.applicationId, this.username);

  /// The member whose form it is.
  final String username;

  @override
  Future<Uint8List> fetch(ClApplicationsMasterNotifier notifier) =>
      notifier.downloadMemberForm(applicationId, username);
}

/// The application drawn for the server's demo member, for an admin.
final class ApplicationPreview extends ApplicationDownload {
  const ApplicationPreview(super.applicationId);

  @override
  Future<Uint8List> fetch(ClApplicationsMasterNotifier notifier) =>
      notifier.downloadPreview(applicationId);
}
