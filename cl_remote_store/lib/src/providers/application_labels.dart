import 'package:cl_remote_store/src/providers/capabilities.dart';
import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/current_user.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/utils/uncertain_write.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// No catalogue: what [applicationLabelsProvider] holds without a call.
const ApplicationLabels emptyApplicationLabels = ApplicationLabels(
  languages: [],
  labels: {},
);

/// The club's labels of application forms (club_client#321, #396): the
/// club's languages, which are the languages a template may print in (the
/// codes of Profile options), and the form's fixed wording in each, which
/// the editor pre-fills and the Labels card on Club details edits.
///
/// An admin's read alone. While applications are off or unknown
/// ([applicationsProvider]), or the signed-in user is not an admin, it holds
/// [emptyApplicationLabels] without a server call. A save of the profile
/// options reloads it, since their languages are these.
final AsyncNotifierProvider<ApplicationLabelsNotifier, ApplicationLabels>
applicationLabelsProvider =
    AsyncNotifierProvider<ApplicationLabelsNotifier, ApplicationLabels>(
      ApplicationLabelsNotifier.new,
    );

/// Notifier of [applicationLabelsProvider]: reads the labels and saves an
/// admin's edit of one.
class ApplicationLabelsNotifier extends AsyncNotifier<ApplicationLabels> {
  @override
  Future<ApplicationLabels> build() async {
    ref.watch(clManualRefreshProvider);
    final enabled = ref.watch(applicationsProvider);
    final isAdmin = ref.watch(currentUserProvider)?.isAdmin ?? false;
    if (enabled != true || !isAdmin) return emptyApplicationLabels;
    final client = await ref.watch(secureClientProvider.future);
    return client.applications.getLabels();
  }

  /// Replaces label [key]'s text with [text] and folds what the server
  /// stored in, the other labels kept. A refusal (English blank, a
  /// language the club lacks: `ApplicationLanguageNotOfferedException`, an
  /// unknown key) is rethrown and nothing changes; a failure that may have
  /// landed reloads instead ([refetchIfWriteUncertain]).
  Future<ApplicationLabel> updateLabel(String key, ApplicationText text) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final stored = await client.applications.updateLabel(key, text);
      final current = state.valueOrNull;
      if (current != null) {
        state = AsyncData(
          ApplicationLabels(
            languages: current.languages,
            labels: {...current.labels, stored.key: stored.text.texts},
          ),
        );
      }
      return stored;
    }, refetch: ref.invalidateSelf);
  }
}
