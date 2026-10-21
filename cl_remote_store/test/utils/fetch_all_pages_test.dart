import 'package:cl_remote_store/src/utils/fetch_all_pages.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Issue 198: fetchAllPages stops at a page with no items, even when '
      'the server still reports more', () async {
    var calls = 0;
    // Page one holds 2 of a stated 5; every later page comes back empty, so
    // hasMore (offset + items < total) stays true.
    final items = await fetchAllPages<int>(({
      required offset,
      required limit,
    }) async {
      // Bounded, so a loop that never ends fails the test instead of
      // hanging the run.
      if (++calls > 10) throw StateError('fetched $calls pages');
      return PaginatedList<int>(
        items: offset == 0 ? const [1, 2] : const [],
        total: 5,
        offset: offset,
        limit: limit,
      );
    });

    expect(items, [1, 2]);
    expect(calls, 2);
  });
}
