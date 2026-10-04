import 'dart:typed_data';

import 'package:cl_remote_store/cl_remote_store.dart'
    show clMemberEvaluationsProvider, evaluationsProvider;
import 'package:club_sdk_2/club_sdk_2.dart' show UserPrivate;
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../constants/evaluation_view_strings.dart';
import '../widgets/evaluation_message.dart';
import '../widgets/evaluation_read_content.dart';

/// One published review, read-only, as the member sees it (design 4.2,
/// `reviews/mine/:id`): its title as the page title, the Review Period
/// section, and the answers without private items. Read by the member
/// [username] themselves, or by a coach. Evidence shows in the gallery
/// viewer, its requests carrying the session's headers; a PDF — the stored
/// member copy behind the download icon at the top right, or a PDF of
/// evidence — is private, so it is downloaded with the session and handed
/// to [onOpenPdfBytes] as bytes. A failed download shows a toast.
///
/// Renders nothing unless the server runs evaluations.
class EvaluationReadView extends ConsumerWidget {
  /// Review [evaluationId] of member [username].
  const EvaluationReadView({
    required this.currentUser,
    required this.username,
    required this.evaluationId,
    required this.onBack,
    required this.onOpenPdfBytes,
    super.key,
  });

  /// The signed-in member or coach.
  final UserPrivate currentUser;

  /// The member the review is about.
  final String username;

  /// The review.
  final int evaluationId;

  /// Leaves the view.
  final VoidCallback onBack;

  /// Shows a downloaded PDF, as bytes.
  final ValueChanged<Uint8List> onOpenPdfBytes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(
      currentUser.username == username || currentUser.roles.isCoach,
      'EvaluationReadView called for ${currentUser.username} on $username, '
      'who is neither the member nor a coach. Screen gate failed.',
    );
    if (ref.watch(evaluationsProvider) != true) return const SizedBox.shrink();
    final reviews = ref.watch(clMemberEvaluationsProvider(username));
    return reviews.when(
      loading: () => const Center(child: ShadProgress()),
      error: (_, _) => EvaluationMessage(
        message: EvaluationViewStrings.loadFailed,
        onBack: onBack,
      ),
      data: (list) {
        for (final review in list) {
          if (review.id == evaluationId) {
            return EvaluationReadContent(
              review: review,
              onOpenPdfBytes: onOpenPdfBytes,
            );
          }
        }
        return EvaluationMessage(
          message: EvaluationViewStrings.reviewMissing,
          onBack: onBack,
        );
      },
    );
  }
}
