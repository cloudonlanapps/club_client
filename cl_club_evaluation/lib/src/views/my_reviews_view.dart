import 'package:cl_remote_store/cl_remote_store.dart'
    show clMemberEvaluationsProvider, evaluationsProvider;
import 'package:club_sdk_2/club_sdk_2.dart'
    show EvaluationMemberView, UserPrivate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/evaluation_view_strings.dart';
import '../widgets/evaluation_message.dart';
import '../widgets/evaluation_page.dart';
import '../widgets/member_review_row.dart';

/// The member's published reviews, newest first (design 4.2,
/// `reviews/mine`); tapping one calls [onOpen] with its id.
///
/// Renders nothing unless the server runs evaluations.
class MyReviewsView extends ConsumerWidget {
  /// The reviews of [currentUser].
  const MyReviewsView({
    required this.currentUser,
    required this.onOpen,
    super.key,
  });

  /// The signed-in member.
  final UserPrivate currentUser;

  /// Opens the review with this id.
  final ValueChanged<int> onOpen;

  /// Orders reviews most recently published first; any without a date
  /// last.
  static int newestFirst(EvaluationMemberView a, EvaluationMemberView b) {
    final x = a.publishedAtUtc;
    final y = b.publishedAtUtc;
    if (x == null || y == null) {
      return x == y ? 0 : (x == null ? 1 : -1);
    }
    return y.compareTo(x);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (ref.watch(evaluationsProvider) != true) return const SizedBox.shrink();
    final reviews = ref.watch(
      clMemberEvaluationsProvider(currentUser.username),
    );
    return reviews.when(
      loading: () => const Center(child: ShadProgress()),
      error: (_, _) =>
          const EvaluationMessage(message: EvaluationViewStrings.loadFailed),
      data: (list) {
        if (list.isEmpty) {
          return const EvaluationMessage(
            message: EvaluationViewStrings.noReviews,
          );
        }
        final sorted = [...list]..sort(newestFirst);
        return EvaluationPage(
          children: [
            for (final review in sorted)
              MemberReviewRow(review: review, onTap: () => onOpen(review.id)),
          ],
        );
      },
    );
  }
}
