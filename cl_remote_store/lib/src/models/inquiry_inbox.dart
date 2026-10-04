import 'package:club_sdk_2/club_sdk_2.dart' show Inquiry, PaginatedList;
import 'package:meta/meta.dart';

import 'inquiry_filter.dart';

/// State of `clInquiriesMasterProvider` (club_core#21): the page of the
/// inbox the admin is looking at, the filter that produced it, and how many
/// inquiries are still open across the whole inbox (the sidebar badge).
@immutable
class InquiryInbox {
  const InquiryInbox({
    required this.filter,
    required this.page,
    required this.unhandledCount,
  });

  /// An inbox with nothing in it, for a viewer the server would refuse.
  InquiryInbox.empty({required this.filter, required int limit})
    : page = PaginatedList<Inquiry>(
        items: const [],
        total: 0,
        limit: limit,
        offset: 0,
      ),
      unhandledCount = 0;

  final InquiryFilter filter;
  final PaginatedList<Inquiry> page;

  /// Open inquiries across every kind, whatever [filter] shows.
  final int unhandledCount;

  InquiryInbox copyWith({
    InquiryFilter? filter,
    PaginatedList<Inquiry>? page,
    int? unhandledCount,
  }) {
    return InquiryInbox(
      filter: filter ?? this.filter,
      page: page ?? this.page,
      unhandledCount: unhandledCount ?? this.unhandledCount,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InquiryInbox &&
          other.filter == filter &&
          other.page == page &&
          other.unhandledCount == unhandledCount;

  @override
  int get hashCode => Object.hash(filter, page, unhandledCount);

  @override
  String toString() =>
      'InquiryInbox(filter: $filter, page: $page, '
      'unhandledCount: $unhandledCount)';
}
