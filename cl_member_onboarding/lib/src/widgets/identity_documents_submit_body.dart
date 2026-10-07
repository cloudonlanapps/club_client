import 'dart:async';

import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

import '../models/identity_document_upload_errors.dart';
import '../models/identity_documents_submit_sizes.dart';
import '../models/identity_documents_submit_strings.dart';
import '../models/onboarding_write_messages.dart';
import 'identity_documents_submit_actions.dart';
import 'identity_documents_upload_tips.dart';

/// The submit-documents step: the member uploads their identity documents,
/// agrees to the privacy policy and submits the application for review.
///
/// Documents are saved as they are added and removed
/// (`IdentityDocumentsUploader`). Submit is available once one is there; it
/// validates the consent (`IdentityDocumentsConsentForm`) and then moves the
/// member to review.
class IdentityDocumentsSubmitBody extends ConsumerStatefulWidget {
  const IdentityDocumentsSubmitBody({
    required this.currentUser,
    required this.initialItems,
    super.key,
  });

  /// The member submitting their documents.
  final UserPrivate currentUser;

  /// The documents already uploaded.
  final List<IdentityDocumentSlot> initialItems;

  @override
  ConsumerState<IdentityDocumentsSubmitBody> createState() =>
      IdentityDocumentsSubmitBodyState();
}

/// State of [IdentityDocumentsSubmitBody].
class IdentityDocumentsSubmitBodyState
    extends ConsumerState<IdentityDocumentsSubmitBody> {
  /// Drives the consent form.
  final GlobalKey<IdentityDocumentsConsentFormState> consentKey =
      GlobalKey<IdentityDocumentsConsentFormState>();

  /// The documents on the server.
  late List<IdentityDocumentSlot> items = widget.initialItems;

  /// Whether the application is being sent.
  bool submitting = false;

  Future<IdentityDocumentSlot> handleUpload({
    required List<int> bytes,
    required String filename,
    required String mimeType,
  }) async {
    try {
      final link = await ref
          .read(
            clIdentityDocsMasterProvider(widget.currentUser.username).notifier,
          )
          .upload(
            bytes: bytes,
            filename: filename,
            contentType: mimeType,
          );
      return IdentityDocumentSlot(
        id: link.mediaUuid,
        uri: ref.read(
          mediaDownloadUrlProvider(
            (uuid: link.mediaUuid, variant: 'original'),
          ),
        ),
        mimeType: link.media.mimeType,
        sizeBytes: bytes.length,
        fileName: filename,
      );
    } on ServerException catch (e) {
      // Surface known encryption/size failures as a specific message; let the
      // form fall back to its generic message for anything else.
      final friendly = IdentityDocumentUploadErrors.friendlyMessage(e);
      if (friendly != null) {
        throw IdentityDocsUploadException(friendly);
      }
      rethrow;
    }
  }

  Future<void> handleDiscard(IdentityDocumentSlot slot) async {
    await ref
        .read(
          clIdentityDocsMasterProvider(widget.currentUser.username).notifier,
        )
        .discard(slot.id);
  }

  /// Submits the application for review once the member has agreed to the
  /// privacy policy.
  Future<void> handleSubmit() async {
    if (consentKey.currentState?.validate() == null) return;
    setState(() => submitting = true);
    try {
      // Documents are already attached at upload time, so submit only flips
      // the user's status. The router redirect listens to authStateProvider
      // and navigates to /onboarding/welcome (pending variant).
      final updated = await ref
          .read(clUsersMasterProvider.notifier)
          .submitForReviewForSelf();

      if (!mounted) return;
      ref.read(authStateProvider.notifier).setUser(updated);
    } on Object catch (error) {
      if (!mounted) return;
      ShadToaster.of(context).show(
        ShadToast.destructive(
          description: Text(
            writeFailureMessage(error, fallback: submissionFailedMessage),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isMobileWidth(context)
                ? double.infinity
                : IdentityDocumentsSubmitSizes.maxWidth,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: IdentityDocumentsSubmitSizes.sidePadding,
              vertical: IdentityDocumentsSubmitSizes.endPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  IdentityDocumentsSubmitStrings.intro,
                  style: theme.textTheme.p,
                ),
                const SizedBox(height: IdentityDocumentsSubmitSizes.gap),
                IdentityDocumentsUploader(
                  initialItems: widget.initialItems,
                  enabled: !submitting,
                  httpHeaders:
                      ref.watch(imageAuthHeadersProvider).value ?? const {},
                  // Inject via the provider (default: the native dialog) so
                  // integration tests can stub the picker and never open a
                  // real OS file chooser — which they can't drive (#758).
                  picker: ref.watch(imagePickerProvider),
                  onUpload: handleUpload,
                  onDiscard: handleDiscard,
                  onChanged: (next) => setState(() => items = next),
                ),
                const SizedBox(
                  height: IdentityDocumentsSubmitSizes.sectionGap,
                ),
                IdentityDocumentsConsentForm(
                  key: consentKey,
                  enabled: !submitting,
                ),
                const SizedBox(height: IdentityDocumentsSubmitSizes.gap),
                IdentityDocumentsSubmitActions(
                  hasDocument: items.isNotEmpty,
                  submitting: submitting,
                  onSubmit: () => unawaited(handleSubmit()),
                  onDoLater: () => unawaited(
                    ref.read(authStateProvider.notifier).logout(),
                  ),
                ),
                const SizedBox(
                  height: IdentityDocumentsSubmitSizes.sectionGap,
                ),
                const IdentityDocumentsUploadTips(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
