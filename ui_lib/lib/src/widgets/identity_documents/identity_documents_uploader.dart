import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/identity_document_sizes.dart';
import 'identity_docs_callbacks.dart';
import 'identity_docs_upload_exception.dart';
import 'identity_document_add_card.dart';
import 'identity_document_cards_row.dart';
import 'identity_document_pending_card.dart';
import 'identity_document_pending_upload.dart';
import 'identity_document_slot.dart';
import 'identity_document_uploaded_card.dart';
import 'identity_documents_picker.dart';
import 'identity_documents_preview.dart';
import 'identity_documents_strings.dart';
import 'identity_documents_upload_config.dart';
import 'identity_documents_upload_validators.dart';

/// A member's identity documents, added and removed one at a time (pure UI:
/// no SDK, no Riverpod).
///
/// Not a form: each change is saved at once. Picking a file hands it to
/// [onUpload] and removing one calls [onDiscard]; the list as it stands
/// afterwards is reported through [onChanged]. A refused pick or a failed
/// upload shows its reason under the cards.
///
/// Most members have a single image, so the second card appears only once
/// the first file is there, labelled as the optional back side.
class IdentityDocumentsUploader extends StatefulWidget {
  const IdentityDocumentsUploader({
    required this.onUpload,
    required this.onDiscard,
    this.initialItems = const [],
    this.onChanged,
    this.enabled = true,
    this.config = IdentityDocumentsUploadConfig.defaults,
    this.picker = defaultIdentityDocumentsPicker,
    this.httpHeaders = const {},
    super.key,
  });

  /// The documents already on the server — orphans (uploaded earlier, not
  /// linked) and linked gallery items alike.
  final List<IdentityDocumentSlot> initialItems;

  /// Uploads the picked bytes to the server.
  final IdentityDocsUploadCallback onUpload;

  /// Removes a document from the server.
  final IdentityDocsDiscardCallback onDiscard;

  /// Told the documents after each upload and each removal.
  final ValueChanged<List<IdentityDocumentSlot>>? onChanged;

  /// Whether files can be added and removed.
  final bool enabled;

  /// What is accepted.
  final IdentityDocumentsUploadConfig config;

  /// Picks an image. Defaults to the native file dialog; the host injects
  /// its own so integration tests can return fixed bytes instead.
  final IdentityDocumentsPicker picker;

  /// Headers sent with the preview image requests, for hosts whose preview
  /// URIs need authentication.
  final Map<String, String> httpHeaders;

  @override
  State<IdentityDocumentsUploader> createState() =>
      IdentityDocumentsUploaderState();
}

/// State of [IdentityDocumentsUploader]: the documents, the uploads in
/// flight and the last failure.
class IdentityDocumentsUploaderState extends State<IdentityDocumentsUploader> {
  /// The documents on the server.
  late List<IdentityDocumentSlot> items = [...widget.initialItems];

  /// The uploads in flight.
  final List<IdentityDocumentPendingUpload> pending = [];

  /// Why the last pick, upload or removal failed.
  String? errorText;

  /// Numbers the uploads in flight.
  int pendingSeq = 0;

  /// Whether another file can be picked now.
  bool get canPickMore =>
      widget.enabled &&
      pending.isEmpty &&
      items.length < widget.config.maxCount;

  /// Replaces the documents and tells the host.
  void setItems(List<IdentityDocumentSlot> next) {
    setState(() {
      items = next;
      errorText = null;
    });
    widget.onChanged?.call(List.unmodifiable(next));
  }

  /// Picks a file and uploads it.
  Future<void> pickAndUpload() async {
    final picked = await widget.picker();
    if (picked == null || !mounted) return;
    final result = IdentityDocumentsUploadValidators.acceptFile(
      mimeType: picked.mimeType,
      sizeBytes: picked.bytes.length,
      config: widget.config,
    );
    if (!result.accepted) {
      setState(() => errorText = result.message);
      return;
    }
    final upload = IdentityDocumentPendingUpload(
      key: 'p${pendingSeq++}',
      filename: picked.filename,
    );
    setState(() {
      errorText = null;
      pending.add(upload);
    });
    try {
      final slot = await widget.onUpload(
        bytes: picked.bytes,
        filename: picked.filename,
        mimeType: picked.mimeType,
      );
      if (!mounted) return;
      pending.remove(upload);
      setItems([...items, slot]);
    } on IdentityDocsUploadException catch (e) {
      // The host mapped a known server failure to a message of its own.
      uploadFailed(upload, e.message);
    } on Object catch (_) {
      uploadFailed(upload, IdentityDocumentsStrings.uploadFailed);
    }
  }

  /// Drops [upload] and shows [message].
  void uploadFailed(IdentityDocumentPendingUpload upload, String message) {
    if (!mounted) return;
    setState(() {
      pending.remove(upload);
      errorText = message;
    });
  }

  /// Removes [slot] from the server.
  Future<void> discard(IdentityDocumentSlot slot) async {
    try {
      await widget.onDiscard(slot);
      if (!mounted) return;
      setItems(items.where((s) => s.id != slot.id).toList());
    } on Object catch (_) {
      if (!mounted) return;
      setState(() => errorText = IdentityDocumentsStrings.removeFailed);
    }
  }

  /// Opens the full-size preview on [slot].
  void openPreview(IdentityDocumentSlot slot) {
    showIdentityDocumentsPreview(
      context: context,
      items: items,
      initialItemId: slot.id,
      httpHeaders: widget.httpHeaders,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final hasFiles = items.isNotEmpty || pending.isNotEmpty;
    final offersAdd = canPickMore;
    final error = errorText;
    final cards = <Widget>[
      for (final slot in items)
        IdentityDocumentUploadedCard(
          slot: slot,
          onTap: widget.enabled ? () => openPreview(slot) : null,
          onRemove: widget.enabled ? () => discard(slot) : null,
          httpHeaders: widget.httpHeaders,
        ),
      for (final upload in pending)
        IdentityDocumentPendingCard(filename: upload.filename),
      if (offersAdd)
        IdentityDocumentAddCard(
          onTap: pickAndUpload,
          label: hasFiles ? IdentityDocumentsStrings.addBackSide : null,
        ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: IdentityDocumentSizes.captionGap,
      children: [
        IdentityDocumentCardsRow(
          cards: cards,
          slotCount: widget.config.maxCount,
          centred: cards.length == 1 && !hasFiles,
        ),
        // Explains the second card only while it is offered.
        if (hasFiles && offersAdd)
          Text(
            IdentityDocumentsStrings.backSideHint,
            style: theme.textTheme.muted,
          ),
        if (error != null)
          Text(
            error,
            style: theme.textTheme.small.copyWith(
              color: theme.colorScheme.destructive,
            ),
          ),
      ],
    );
  }
}
