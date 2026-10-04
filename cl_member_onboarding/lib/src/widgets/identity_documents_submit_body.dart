import 'dart:async';

import 'package:cl_member_auth/cl_member_auth.dart';
import 'package:cl_remote_store/cl_remote_store.dart';
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart';

import '../models/identity_document_upload_errors.dart';
import '../models/onboarding_write_messages.dart';

class IdentityDocumentsSubmitBody extends ConsumerStatefulWidget {
  const IdentityDocumentsSubmitBody({
    required this.currentUser,
    required this.initialItems,
    super.key,
  });

  final UserPrivate currentUser;
  final List<IdentityDocumentSlot> initialItems;

  @override
  ConsumerState<IdentityDocumentsSubmitBody> createState() =>
      IdentityDocumentsSubmitBodyState();
}

class IdentityDocumentsSubmitBodyState
    extends ConsumerState<IdentityDocumentsSubmitBody> {
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

  Future<void> handleSubmit(Map<String, dynamic> formValue) async {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = isMobileWidth(context);
    return SingleChildScrollView(
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isMobile ? double.infinity : 480,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: IdentityDocumentsForm(
              initialItems: widget.initialItems,
              httpHeaders:
                  ref.watch(imageAuthHeadersProvider).value ?? const {},
              // Inject via the provider (default: the native dialog) so
              // integration tests can stub the picker and never open a real OS
              // file chooser — which they can't drive (#758).
              picker: ref.watch(imagePickerProvider),
              onUpload: handleUpload,
              onDiscard: handleDiscard,
              onSubmit: handleSubmit,
              onDoLater: () => unawaited(
                ref.read(authStateProvider.notifier).logout(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
