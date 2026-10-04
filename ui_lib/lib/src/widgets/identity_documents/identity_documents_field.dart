import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../../constants/identity_documents.dart';
import '../credentialed_network_image.dart';
import 'identity_document_slot.dart';
import 'identity_documents_picker.dart';
import 'identity_documents_preview.dart';

/// Thrown by an [IdentityDocsUploadCallback] to surface a specific,
/// user-presentable reason an upload failed (e.g. the server has no encryption
/// key configured). The field shows [message] verbatim instead of its generic
/// "couldn't upload" fallback.
///
/// SDK-free on purpose: the host (which knows about `ServerException` codes)
/// maps server errors to a friendly [message] and throws this; the form stays
/// free of SDK concepts.
class IdentityDocsUploadException implements Exception {
  const IdentityDocsUploadException(this.message);

  /// A complete, user-facing sentence to display under the upload tile.
  final String message;

  @override
  String toString() => 'IdentityDocsUploadException: $message';
}

/// Host callback contract for uploading bytes to the server.
typedef IdentityDocsUploadCallback =
    Future<IdentityDocumentSlot> Function({
      required List<int> bytes,
      required String filename,
      required String mimeType,
    });

/// Host callback contract for removing a slot (orphan or linked).
typedef IdentityDocsDiscardCallback =
    Future<void> Function(IdentityDocumentSlot slot);

/// Custom ShadForm field that holds the current list of identity-document
/// slots and wires the file picker + upload + preview lifecycle.
///
/// Drop in with an `id` and ShadForm picks it up like any other field.
class IdentityDocumentsFormField extends StatefulWidget {
  const IdentityDocumentsFormField({
    required this.id,
    required this.onUpload,
    required this.onDiscard,
    super.key,
    this.initialValue = const [],
    this.enabled = true,
    this.label,
    this.description,
    this.config = IdentityDocumentsFormConfig.defaults,
    this.picker = defaultIdentityDocumentsPicker,
    this.validator,
    this.onChanged,
    this.autovalidateMode,
    this.httpHeaders = const {},
  });

  final String id;
  final List<IdentityDocumentSlot> initialValue;
  final bool enabled;
  final Widget? label;
  final Widget? description;
  final IdentityDocumentsFormConfig config;
  final IdentityDocumentsPicker picker;
  final IdentityDocsUploadCallback onUpload;
  final IdentityDocsDiscardCallback onDiscard;
  final FormFieldValidator<List<IdentityDocumentSlot>>? validator;
  final ValueChanged<List<IdentityDocumentSlot>?>? onChanged;
  final AutovalidateMode? autovalidateMode;

  /// HTTP headers forwarded to image requests for slot previews.
  ///
  /// Populate with `imageAuthHeadersProvider` (from `cl_member_auth`) when
  /// the preview endpoint may require authentication. Empty by default so
  /// hosts that point at public URIs keep working unchanged.
  final Map<String, String> httpHeaders;

  @override
  State<IdentityDocumentsFormField> createState() =>
      IdentityDocumentsFormFieldState();
}

class PendingUpload {
  PendingUpload({required this.key, required this.filename});
  final String key;
  final String filename;
}

class IdentityDocumentsFormFieldState
    extends State<IdentityDocumentsFormField> {
  final GlobalKey<FormFieldState<List<IdentityDocumentSlot>>> _fieldKey =
      GlobalKey();
  final List<PendingUpload> _pending = [];
  String? _pickErrorText;
  int _pendingSeq = 0;

  List<IdentityDocumentSlot> get _committedItems =>
      _fieldKey.currentState?.value ?? widget.initialValue;

  bool get _isBusy => _pending.isNotEmpty;

  bool get _canPickMore =>
      widget.enabled &&
      !_isBusy &&
      _committedItems.length < widget.config.maxCount;

  Future<void> _pickAndUpload() async {
    final picked = await widget.picker();
    if (picked == null) return;
    final result = IdentityDocumentsFormValidators.acceptFile(
      mimeType: picked.mimeType,
      sizeBytes: picked.bytes.length,
      config: widget.config,
    );
    if (!result.accepted) {
      setState(() => _pickErrorText = result.message);
      return;
    }
    final pending = PendingUpload(
      key: 'p${_pendingSeq++}',
      filename: picked.filename,
    );
    setState(() {
      _pickErrorText = null;
      _pending.add(pending);
    });
    try {
      final slot = await widget.onUpload(
        bytes: picked.bytes,
        filename: picked.filename,
        mimeType: picked.mimeType,
      );
      if (!mounted) return;
      setState(() => _pending.remove(pending));
      _fieldKey.currentState?.didChange([..._committedItems, slot]);
    } on IdentityDocsUploadException catch (e) {
      // Host mapped a known server failure to a specific, user-facing message.
      if (!mounted) return;
      setState(() {
        _pending.remove(pending);
        _pickErrorText = e.message;
      });
    } on Object catch (_) {
      if (!mounted) return;
      setState(() {
        _pending.remove(pending);
        _pickErrorText = "Couldn't upload that file. Please try again.";
      });
    }
  }

  Future<void> _discard(IdentityDocumentSlot slot) async {
    try {
      await widget.onDiscard(slot);
      if (!mounted) return;
      _fieldKey.currentState?.didChange(
        _committedItems.where((s) => s.id != slot.id).toList(),
      );
      setState(() => _pickErrorText = null);
    } on Object catch (_) {
      if (!mounted) return;
      setState(
        () => _pickErrorText = "Couldn't remove that file. Please try again.",
      );
    }
  }

  void _openPreview(IdentityDocumentSlot tappedSlot) {
    showIdentityDocumentsPreview(
      context: context,
      items: _committedItems,
      initialItemId: tappedSlot.id,
      httpHeaders: widget.httpHeaders,
    );
  }

  @override
  Widget build(BuildContext context) {
    return InnerField(
      fieldKey: _fieldKey,
      id: widget.id,
      initialValue: widget.initialValue,
      enabled: widget.enabled,
      label: widget.label,
      description: widget.description,
      forceErrorText: _pickErrorText,
      validator: widget.validator,
      onChanged: widget.onChanged,
      autovalidateMode: widget.autovalidateMode,
      config: widget.config,
      pending: _pending,
      canPickMore: _canPickMore,
      onPickRequested: _pickAndUpload,
      onDiscardRequested: _discard,
      onPreviewRequested: _openPreview,
      httpHeaders: widget.httpHeaders,
    );
  }
}

class InnerField extends ShadFormBuilderField<List<IdentityDocumentSlot>> {
  InnerField({
    required GlobalKey<FormFieldState<List<IdentityDocumentSlot>>> fieldKey,
    required super.id,
    required List<IdentityDocumentSlot> super.initialValue,
    required super.enabled,
    required super.label,
    required super.description,
    required super.forceErrorText,
    required IdentityDocumentsFormConfig config,
    required List<PendingUpload> pending,
    required bool canPickMore,
    required VoidCallback onPickRequested,
    required void Function(IdentityDocumentSlot) onDiscardRequested,
    required void Function(IdentityDocumentSlot) onPreviewRequested,
    required Map<String, String> httpHeaders,
    super.validator,
    super.onChanged,
    super.autovalidateMode,
  }) : super(
         key: fieldKey,
         builder: (state) {
           final items = state.value ?? const <IdentityDocumentSlot>[];
           // Progressive disclosure: most users have a single image. The
           // second slot is only revealed after the first file is picked,
           // and is explicitly marked as the optional "back side".
           //
           // Card order: committed items, then any in-flight upload, then
           // the add tile (when more slots are still allowed).
           final hasItems = items.isNotEmpty || pending.isNotEmpty;
           final addCard = canPickMore
               ? AddCard(
                   onTap: onPickRequested,
                   label: hasItems ? 'Add back side' : null,
                 )
               : null;
           final cards = <Widget>[
             for (final slot in items)
               UploadedCard(
                 slot: slot,
                 enabled: state.widget.enabled,
                 onTap: () => onPreviewRequested(slot),
                 onDelete: state.widget.enabled
                     ? () => onDiscardRequested(slot)
                     : null,
                 httpHeaders: httpHeaders,
               ),
             for (final p in pending) PendingCard(filename: p.filename),
             ?addCard,
           ];

           Widget row;
           // Empty state: single centred add tile at half-row width.
           if (cards.length == 1 && !hasItems) {
             row = Row(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 const Spacer(),
                 Expanded(flex: 2, child: cards.first),
                 const Spacer(),
               ],
             );
           } else {
             // One or two cards in the standard two-up layout. When only
             // one card is present and the add slot is full (maxCount=1
             // edge case) we still pad to maxCount for stable geometry.
             final slotCount = config.maxCount;
             row = Row(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
                 for (var i = 0; i < slotCount; i++) ...[
                   if (i > 0) const SizedBox(width: 12),
                   Expanded(
                     child: i < cards.length
                         ? cards[i]
                         : const SizedBox.shrink(),
                   ),
                 ],
               ],
             );
           }

           // Caption that explains the second tile only when it's visible
           // and the user might still need it. Suppressed in the empty
           // state and once the second slot has been filled.
           final showHint = hasItems && addCard != null;
           if (!showHint) return row;
           final theme = ShadTheme.of(state.context);
           return Column(
             crossAxisAlignment: CrossAxisAlignment.start,
             children: [
               row,
               const SizedBox(height: 8),
               Text(
                 'Only add a second image if your Aadhaar front and back '
                 'are separate photos.',
                 style: theme.textTheme.muted,
               ),
             ],
           );
         },
       );
}

class CardFrame extends StatelessWidget {
  const CardFrame({required this.child, this.onTap, super.key});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final content = AspectRatio(
      aspectRatio: kIdentityDocCardAspect,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.card,
          border: Border.all(color: theme.colorScheme.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: child,
        ),
      ),
    );
    return onTap == null
        ? content
        : MouseRegion(
            cursor: SystemMouseCursors.click,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onTap,
              child: content,
            ),
          );
  }
}

class AddCard extends StatelessWidget {
  const AddCard({required this.onTap, this.label, super.key});

  final VoidCallback onTap;

  /// Optional label rendered under the plus icon. When the card is the
  /// secondary "back side" affordance it's labelled so the user
  /// understands the second slot is not a second required document.
  final String? label;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return CardFrame(
      onTap: onTap,
      child: ColoredBox(
        color: theme.colorScheme.muted.withValues(alpha: 0.4),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.add,
                size: label == null ? 32 : 24,
                color: theme.colorScheme.mutedForeground,
              ),
              if (label != null) ...[
                const SizedBox(height: 4),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Text(
                    label!,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.small.copyWith(
                      color: theme.colorScheme.mutedForeground,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class PendingCard extends StatelessWidget {
  const PendingCard({required this.filename, super.key});

  final String filename;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return CardFrame(
      child: ColoredBox(
        color: theme.colorScheme.muted.withValues(alpha: 0.6),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  filename,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.muted.copyWith(fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class UploadedCard extends StatelessWidget {
  const UploadedCard({
    required this.slot,
    required this.enabled,
    required this.onTap,
    required this.onDelete,
    required this.httpHeaders,
    super.key,
  });

  final IdentityDocumentSlot slot;
  final bool enabled;
  final VoidCallback onTap;
  final VoidCallback? onDelete;
  final Map<String, String> httpHeaders;

  @override
  Widget build(BuildContext context) {
    return CardFrame(
      onTap: enabled ? onTap : null,
      child: Stack(
        fit: StackFit.expand,
        children: [
          SlotPreviewSurface(slot: slot, httpHeaders: httpHeaders),
          if (onDelete != null)
            Positioned(
              top: 4,
              right: 4,
              child: DeleteIconButton(onPressed: onDelete!),
            ),
        ],
      ),
    );
  }
}

class DeleteIconButton extends StatelessWidget {
  const DeleteIconButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onPressed,
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.background.withValues(alpha: 0.85),
          ),
          padding: const EdgeInsets.all(4),
          child: Icon(
            Icons.close,
            size: 14,
            color: theme.colorScheme.foreground,
          ),
        ),
      ),
    );
  }
}

class SlotPreviewSurface extends StatelessWidget {
  const SlotPreviewSurface({
    required this.slot,
    required this.httpHeaders,
    super.key,
  });

  final IdentityDocumentSlot slot;
  final Map<String, String> httpHeaders;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return CredentialedNetworkImage(
      imageUrl: slot.uri,
      httpHeaders: httpHeaders,
      fit: BoxFit.cover,
      errorBuilder: (_) => imagePlaceholder(theme, slot.fileName),
    );
  }
}

Widget imagePlaceholder(ShadThemeData theme, String? filename) {
  return Container(
    color: theme.colorScheme.muted,
    alignment: Alignment.center,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.image_outlined, size: 28),
          const SizedBox(height: 4),
          Text(
            filename ?? 'Image',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.small.copyWith(fontSize: 11),
          ),
        ],
      ),
    ),
  );
}
