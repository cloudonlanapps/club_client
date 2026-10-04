import 'package:cl_remote_store/src/models/evaluation_item_search_query.dart';
import 'package:cl_remote_store/src/providers/capabilities.dart';
import 'package:cl_remote_store/src/providers/client.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// How many hits one "Existing question" search returns.
const int evaluationItemSearchLimit = 50;

/// Items of every live template matching a query, for the designer's
/// "Existing question" picker (club_core#173): each hit names its template,
/// and the item is copied into another template with its id as
/// `originItemId`.
///
/// The first [evaluationItemSearchLimit] hits; narrow the query for more.
/// Empty, with no server call, unless [evaluationsProvider] is `true`.
final AutoDisposeFutureProviderFamily<
  List<EvaluationTemplateItemHit>,
  EvaluationItemSearchQuery
>
clEvaluationItemSearchProvider = FutureProvider.autoDispose
    .family<List<EvaluationTemplateItemHit>, EvaluationItemSearchQuery>((
      ref,
      query,
    ) async {
      if (ref.watch(evaluationsProvider) != true) return const [];
      final client = await ref.watch(secureClientProvider.future);
      final search = query.search?.trim();
      final page = await client.evaluations.searchItems(
        search: search == null || search.isEmpty ? null : search,
        type: query.type,
        limit: evaluationItemSearchLimit,
      );
      return page.items;
    });
