import 'package:cl_remote_store/src/providers/capabilities.dart';
import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/current_user.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// No library: what [applicationClausesProvider] holds without a call.
const ApplicationClauseLibrary emptyApplicationClauses =
    ApplicationClauseLibrary(languages: [], choices: {}, clauses: {});

/// The application clause library (club_client#321): the rules,
/// declarations, header items, selections and notes a template refers to,
/// and the choices a `choices` fact may name, for the editor's pickers and
/// its read-out of a template.
///
/// An admin's read alone. While applications are off or unknown
/// ([applicationsProvider]), or the signed-in user is not an admin, it holds
/// [emptyApplicationClauses] without a server call. The library ships with
/// the server, so it is read once per session.
final FutureProvider<ApplicationClauseLibrary> applicationClausesProvider =
    FutureProvider<ApplicationClauseLibrary>((ref) async {
      final enabled = ref.watch(applicationsProvider);
      final isAdmin = ref.watch(currentUserProvider)?.isAdmin ?? false;
      if (enabled != true || !isAdmin) return emptyApplicationClauses;
      final client = await ref.watch(secureClientProvider.future);
      return client.applications.getClauses();
    });
