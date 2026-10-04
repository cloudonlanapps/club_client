import 'dart:async';

import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:ui_lib/ui_lib.dart';

import '../providers/my_identity_doc_slots.dart';
import '../widgets/identity_documents_submit_body.dart';

/// Identity-document submission view (the second onboarding route).
///
/// Wraps `ui_lib/IdentityDocumentsForm` with master-notifier-backed
/// callbacks. Reached from `/onboarding/welcome` via Continue, or from
/// a returning user who lands here directly. After "Submit for review"
/// the server flips status `registered` → `pending`; the router
/// redirect then bounces the user back to `/onboarding/welcome`
/// where the SubmittedConfirmation variant renders.
class OnboardingSubmitDocumentsView extends ConsumerWidget {
  const OnboardingSubmitDocumentsView({
    required this.currentUser,
    required this.onHome,
    super.key,
  });

  final UserPrivate currentUser;
  final VoidCallback onHome;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    assert(
      currentUser.status == UserStatus.registered &&
          (currentUser.adminReviewNote ?? '').isEmpty,
      'OnboardingSubmitDocumentsView called with unexpected status '
      '${currentUser.status} / note ${currentUser.adminReviewNote}. '
      'OnboardingSubmitDocumentsScreen gate '
      '(OnboardingGate.registeredNoNote) failed.',
    );
    final slotsAsync = ref.watch(clMyIdentityDocSlotsProvider);

    return slotsAsync.when(
      loading: () => const LoadingView(),
      error: (error, _) => Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isMobileWidth(context) ? double.infinity : 480,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: ErrorView(
              title: 'Could not load your documents',
              subtitle: 'Please check your connection and try again.',
              errorCode: error.toString(),
              onHome: onHome,
              onRetry: () {
                ref.invalidate(clMyIdentityDocSlotsProvider);
                unawaited(
                  ref
                      .read(
                        clIdentityDocsMasterProvider(
                          currentUser.username,
                        ).notifier,
                      )
                      .refresh(),
                );
              },
            ),
          ),
        ),
      ),
      data: (slots) => IdentityDocumentsSubmitBody(
        currentUser: currentUser,
        initialItems: slots,
      ),
    );
  }
}
