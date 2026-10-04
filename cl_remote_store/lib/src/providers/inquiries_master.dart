import 'package:cl_remote_store/src/models/inquiry_filter.dart';
import 'package:cl_remote_store/src/models/inquiry_inbox.dart';
import 'package:cl_remote_store/src/providers/client.dart';
import 'package:cl_remote_store/src/providers/current_user.dart';
import 'package:cl_remote_store/src/providers/manual_refresh.dart';
import 'package:cl_remote_store/src/utils/uncertain_write.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Rows per page of the inquiry inbox.
const int inquiryPageSize = 20;

/// Master provider for the admin inquiry inbox (club_core#21): contact and
/// interest submissions from the public website.
///
/// One inbox, one filter: the state is the page the admin is looking at,
/// the [InquiryFilter] that produced it, and the count of open inquiries
/// across the whole inbox, which the sidebar badge reads through
/// [clUnhandledInquiryCountProvider]. Filtering and paging are server-side,
/// so changing either refetches.
///
/// Admin only, like the endpoint: anyone else gets an empty inbox without a
/// server call. Mutations call the server first, then fold its answer into
/// local state: a row that no longer matches the filter leaves the page, and
/// the open count moves with it. Manual refresh model — no polling.
final AsyncNotifierProvider<ClInquiriesMasterNotifier, InquiryInbox>
clInquiriesMasterProvider =
    AsyncNotifierProvider<ClInquiriesMasterNotifier, InquiryInbox>(
      ClInquiriesMasterNotifier.new,
    );

class ClInquiriesMasterNotifier extends AsyncNotifier<InquiryInbox> {
  InquiryFilter _filter = InquiryFilter.open;
  int _offset = 0;

  @override
  Future<InquiryInbox> build() async {
    ref.watch(clManualRefreshProvider);
    final currentUser = ref.watch(currentUserProvider);
    if (currentUser == null || !currentUser.isAdmin) {
      return InquiryInbox.empty(filter: _filter, limit: inquiryPageSize);
    }
    final client = await ref.watch(secureClientProvider.future);
    return fetchInbox(client.inquiries, _filter, _offset);
  }

  /// Show [filter] from its first page.
  Future<void> setFilter(InquiryFilter filter) async {
    _filter = filter;
    _offset = 0;
    await refresh();
  }

  /// Re-fetch the current page and the open count.
  Future<void> refresh() async {
    state = const AsyncLoading<InquiryInbox>().copyWithPrevious(state);
    state = await AsyncValue.guard(build);
  }

  /// Advance one page if more rows exist.
  Future<void> nextPage() async {
    final page = state.valueOrNull?.page;
    if (page == null || !page.hasMore) return;
    _offset = page.offset + page.limit;
    await refresh();
  }

  /// Go back one page if not already at the start.
  Future<void> previousPage() async {
    if (_offset == 0) return;
    _offset = (_offset - inquiryPageSize).clamp(0, _offset);
    await refresh();
  }

  /// Mark [id] handled by the caller, or reopen it; returns the server's
  /// row.
  Future<Inquiry> setHandled(int id, {required bool handled}) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      final updated = await client.inquiries.setInquiryHandled(
        id,
        handled: handled,
      );
      final inbox = state.valueOrNull;
      if (inbox != null) state = AsyncData(replaceInInbox(inbox, updated));
      return updated;
    }, refetch: ref.invalidateSelf);
  }

  /// Remove [id] permanently (it is PII; there is no soft delete).
  Future<void> deleteInquiry(int id) {
    return refetchIfWriteUncertain(() async {
      final client = await ref.read(secureClientProvider.future);
      await client.inquiries.deleteInquiry(id);
      final inbox = state.valueOrNull;
      if (inbox != null) state = AsyncData(removeFromInbox(inbox, id));
    }, refetch: ref.invalidateSelf);
  }
}

/// The page for [filter] at [offset], and the open count across the inbox —
/// read off the page itself when the page is exactly the open inbox.
Future<InquiryInbox> fetchInbox(
  InquirySource source,
  InquiryFilter filter,
  int offset,
) async {
  final page = await source.listInquiries(
    kind: filter.kind,
    handled: filter.handled,
    offset: offset,
    // Pin the page size here rather than leaning on the SDK default.
    // ignore: avoid_redundant_argument_values
    limit: inquiryPageSize,
  );
  final unhandled = filter == InquiryFilter.open
      ? page.total
      : (await source.listInquiries(handled: false, limit: 1)).total;
  return InquiryInbox(filter: filter, page: page, unhandledCount: unhandled);
}

/// [inbox] with [updated] folded in: replaced in place while it still
/// matches the filter, dropped otherwise, and the open count adjusted when
/// its handled state changed.
InquiryInbox replaceInInbox(InquiryInbox inbox, Inquiry updated) {
  final items = inbox.page.items;
  final index = items.indexWhere((i) => i.id == updated.id);
  if (index < 0) return inbox;
  final before = items[index];
  final keep = inbox.filter.matches(updated);
  final nextItems = [
    for (final i in items)
      if (i.id != updated.id) i else if (keep) updated,
  ];
  final delta = before.isHandled == updated.isHandled
      ? 0
      : (updated.isHandled ? -1 : 1);
  return inbox.copyWith(
    page: inbox.page.copyWith(
      items: nextItems,
      total: keep ? inbox.page.total : inbox.page.total - 1,
    ),
    unhandledCount: inbox.unhandledCount + delta,
  );
}

/// [inbox] without row [id], its total and open count lowered to match.
InquiryInbox removeFromInbox(InquiryInbox inbox, int id) {
  final items = inbox.page.items;
  final index = items.indexWhere((i) => i.id == id);
  if (index < 0) return inbox;
  final removed = items[index];
  return inbox.copyWith(
    page: inbox.page.copyWith(
      items: [
        for (final i in items)
          if (i.id != id) i,
      ],
      total: inbox.page.total - 1,
    ),
    unhandledCount: removed.isHandled
        ? inbox.unhandledCount
        : inbox.unhandledCount - 1,
  );
}

/// Open inquiries across the inbox — the admin sidebar badge. Derived from
/// [clInquiriesMasterProvider]; `0` while it loads and for a non-admin.
final Provider<int> clUnhandledInquiryCountProvider = Provider<int>(
  (ref) =>
      ref.watch(clInquiriesMasterProvider).valueOrNull?.unhandledCount ?? 0,
);
