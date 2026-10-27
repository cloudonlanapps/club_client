import 'package:cl_remote_store/cl_remote_store.dart'
    show ClApplicationsMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart' show ApplicationStatus;

/// A move of an application template through its states, as on an
/// evaluation (design §2.1.1), and Delete.
enum ApplicationStep {
  /// Draft → saved (shown as Finalize), checked complete and its layout
  /// decided.
  save('Finalize', 'Application finalized.'),

  /// Saved → published: members see it.
  publish('Publish', 'Application published.'),

  /// Published → saved: members no longer see it.
  unpublish('Unpublish', 'Application unpublished.'),

  /// Saved → draft: editable again.
  revert('Revert to draft', 'Application reverted to a draft.'),

  /// Soft-deletes a draft or saved template.
  delete('Delete', 'Application deleted.');

  const ApplicationStep(this.label, this.doneMessage);

  /// The action's label.
  final String label;

  /// The toast once it is done.
  final String doneMessage;

  /// Whether the step is offered on a template in [status]: only the
  /// moves that state allows are shown (club_client#398). A draft is
  /// finalized or deleted, a saved one published, reverted or deleted, a
  /// published one unpublished.
  bool offeredIn(ApplicationStatus status) => switch ((this, status)) {
    (save, ApplicationStatus.draft) => true,
    (publish || revert, ApplicationStatus.saved) => true,
    (unpublish, ApplicationStatus.published) => true,
    (delete, ApplicationStatus.draft || ApplicationStatus.saved) => true,
    _ => false,
  };

  /// Runs the step on template [id].
  Future<void> run(ClApplicationsMasterNotifier notifier, int id) =>
      switch (this) {
        save => notifier.saveApplication(id),
        publish => notifier.publishApplication(id),
        unpublish => notifier.unpublishApplication(id),
        revert => notifier.revertApplication(id),
        delete => notifier.deleteApplication(id),
      };
}
