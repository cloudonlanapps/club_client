import 'package:cl_remote_store/src/providers/capabilities.dart';
import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/current_user.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// No library: what [applicationClausesProvider] holds without a call.
const ApplicationClauseLibrary emptyApplicationClauses =
    ApplicationClauseLibrary(languages: [], choices: {}, clauses: []);

/// The application clauses list (club_client#321, #389): the server's
/// built-in rules, declarations, header items, selections and notes, then
/// the club's own library texts, each as written with its `{gap}`s, for the
/// editor to paste; and the choices a `choices` fact may name.
///
/// An admin's read alone. While applications are off or unknown
/// ([applicationsProvider]), or the signed-in user is not an admin, it holds
/// [emptyApplicationClauses] without a server call. The built-in clauses
/// ship with the server; the club's texts change only through
/// `clApplicationLibraryMasterProvider`, whose writes reload this list.
final FutureProvider<ApplicationClauseLibrary> applicationClausesProvider =
    FutureProvider<ApplicationClauseLibrary>((ref) async {
      final enabled = ref.watch(applicationsProvider);
      final isAdmin = ref.watch(currentUserProvider)?.isAdmin ?? false;
      if (enabled != true || !isAdmin) return emptyApplicationClauses;
      final client = await ref.watch(secureClientProvider.future);
      return client.applications.getClauses();
    });
