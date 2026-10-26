import 'package:cl_remote_store/src/providers/capabilities.dart';
import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/current_user.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// No catalogue: what [applicationLabelsProvider] holds without a call.
const ApplicationLabels emptyApplicationLabels = ApplicationLabels(
  languages: [],
  labels: {},
);

/// The label catalogue of application forms (club_client#321): the
/// languages a template may print in and the form's fixed wording in each,
/// which the editor pre-fills.
///
/// An admin's read alone. While applications are off or unknown
/// ([applicationsProvider]), or the signed-in user is not an admin, it holds
/// [emptyApplicationLabels] without a server call. The catalogue ships with
/// the server, so it is read once per session.
final FutureProvider<ApplicationLabels> applicationLabelsProvider =
    FutureProvider<ApplicationLabels>((ref) async {
      final enabled = ref.watch(applicationsProvider);
      final isAdmin = ref.watch(currentUserProvider)?.isAdmin ?? false;
      if (enabled != true || !isAdmin) return emptyApplicationLabels;
      final client = await ref.watch(secureClientProvider.future);
      return client.applications.getLabels();
    });
