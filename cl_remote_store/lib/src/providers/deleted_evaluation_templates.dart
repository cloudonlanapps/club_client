import 'package:cl_remote_store/src/providers/capabilities.dart';
import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/providers/resource_version.dart';
import 'package:cl_remote_store/src/utils/fetch_all_pages.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// The soft-deleted evaluation templates, all pages, in the server's order
/// (club_client#277), for the library's deleted view and its **Restore**.
///
/// Any staff member reads it. Refetched when `evaluationsVersion` is bumped,
/// which every template write does: a delete adds a row here, a restore
/// (`ClEvaluationTemplatesMasterNotifier.restoreTemplate`) takes it away.
/// Empty, with no server call, unless [evaluationsProvider] is `true`.
final AutoDisposeFutureProvider<List<EvaluationTemplate>>
clDeletedEvaluationTemplatesProvider =
    FutureProvider.autoDispose<List<EvaluationTemplate>>((ref) async {
      ref
        ..watch(clManualRefreshProvider)
        ..watch(clResourceVersionProvider.select((s) => s.evaluationsVersion));
      if (ref.watch(evaluationsProvider) != true) return const [];
      final client = await ref.watch(secureClientProvider.future);
      return fetchAllPages(client.evaluations.listDeletedTemplates);
    });
