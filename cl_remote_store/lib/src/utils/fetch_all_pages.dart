import 'package:club_sdk_2/club_sdk_2.dart';

/// Fetches all pages from a paginated API endpoint.
///
/// Calls [fetcher] repeatedly with increasing offsets until all items
/// are loaded (`hasMore` returns false).
///
/// Returns the combined list of all items across all pages.
Future<List<T>> fetchAllPages<T>(
  Future<PaginatedList<T>> Function({
    required int offset,
    required int limit,
  })
  fetcher, {
  int pageSize = 100,
}) async {
  final allItems = <T>[];
  var offset = 0;

  while (true) {
    final page = await fetcher(offset: offset, limit: pageSize);
    allItems.addAll(page.items);

    if (!page.hasMore) break;
    offset += page.items.length;
  }

  return allItems;
}
