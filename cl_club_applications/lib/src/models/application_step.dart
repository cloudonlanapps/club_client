import 'package:cl_remote_store/cl_remote_store.dart'
    show ClApplicationsMasterNotifier;
import 'package:club_sdk_2/club_sdk_2.dart' show ApplicationStatus;

/// A move of an application template through its states, as on an
/// evaluation (design §2.1.1), and Delete.
enum ApplicationStep {
  /// Draft → saved, checked complete and its layout decided.
  save('Save', 'Application saved.'),

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

  /// Why the step cannot run on a template in [status], or null when it
  /// can.
  String? blockedBy(ApplicationStatus status) => switch ((this, status)) {
    (save, ApplicationStatus.draft) => null,
    (save, ApplicationStatus.saved) => 'Already saved',
    (save || publish, ApplicationStatus.published) => 'Already published',
    (publish, ApplicationStatus.saved) => null,
    (publish, ApplicationStatus.draft) => 'Save it first',
    (unpublish, ApplicationStatus.published) => null,
    (unpublish, _) => 'Not published',
    (revert, ApplicationStatus.saved) => null,
    (revert, ApplicationStatus.draft) => 'Already a draft',
    (revert || delete, ApplicationStatus.published) => 'Unpublish it first',
    (delete, _) => null,
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
