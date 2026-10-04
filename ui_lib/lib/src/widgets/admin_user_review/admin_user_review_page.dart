import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/admin_user_review/admin_user_review_form.dart'
    show AdminUserReviewForm;
import 'package:ui_lib/ui_lib.dart' show AdminUserReviewForm;

import '../../constants/admin_user_review.dart';
import '../../constants/identity_documents.dart';
import '../credentialed_network_image.dart';
import '../identity_documents/identity_document_slot.dart';
import '../identity_documents/identity_documents_preview.dart';
import 'admin_user_review_form_data.dart';
import 'admin_user_review_validators.dart';

/// One page of the [AdminUserReviewForm] — a single pending user's review
/// surface. Lifted to its own widget so the PageView can dispose state on
/// swipe (each page is its own form; see issue #385 acceptance criteria).
class AdminUserReviewPage extends StatefulWidget {
  const AdminUserReviewPage({
    required this.data,
    required this.onApprove,
    required this.onReject,
    required this.onBlock,
    super.key,
    this.httpHeaders = const {},
    this.showDocuments = true,
  });

  final AdminUserReviewFormData data;
  final AdminUserReviewActionCallback onApprove;
  final AdminUserReviewActionCallback onReject;
  final AdminUserReviewActionCallback onBlock;

  /// HTTP headers forwarded to identity-document preview image requests.
  ///
  /// Populate from `imageAuthHeadersProvider` (in `cl_member_auth`) when
  /// the host's review URIs may require authentication.
  final Map<String, String> httpHeaders;

  /// See `AdminUserReviewForm.showDocuments`.
  final bool showDocuments;

  @override
  State<AdminUserReviewPage> createState() => AdminUserReviewPageState();
}

class AdminUserReviewPageState extends State<AdminUserReviewPage> {
  // Issue 507: Reject/Block now collect their reason in a modal dialog
  // instead of an inline reveal, so the page itself is always a single
  // fixed-height layout — no scroll, no keyboard reflow, no manual
  // scrolling to reach Confirm. Approve still fires immediately on tap.
  AdminUserReviewAction? selectedAction;
  bool isSubmitting = false;

  @override
  void didUpdateWidget(covariant AdminUserReviewPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    // PageView's sliver can preserve this State across data swaps (e.g.
    // when the pending list shrinks after an action and a new user
    // slides into the same slot). Reset selection whenever the user
    // behind this slot actually changes so the new page is clean.
    if (oldWidget.data.userKey != widget.data.userKey) {
      selectedAction = null;
      isSubmitting = false;
    }
  }

  Future<void> _selectAction(AdminUserReviewAction action) async {
    if (isSubmitting) return;
    if (action == AdminUserReviewAction.approve) {
      await _runApproveImmediate();
      return;
    }
    await _openReasonDialog(action);
  }

  Future<void> _openReasonDialog(AdminUserReviewAction action) async {
    setState(() => selectedAction = action);
    final result = await ReasonDialog.show(
      context: context,
      action: action,
      userFullName: widget.data.fullName,
    );
    if (!mounted) return;
    setState(() => selectedAction = null);
    if (result == null) return; // Cancelled.
    setState(() => isSubmitting = true);
    try {
      final reason = result.isEmpty ? null : result;
      await _callbackFor(action)(widget.data, reason);
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  Future<void> _runApproveImmediate() async {
    setState(() {
      selectedAction = AdminUserReviewAction.approve;
      isSubmitting = true;
    });
    try {
      await widget.onApprove(widget.data, null);
    } finally {
      if (mounted) {
        setState(() => isSubmitting = false);
      }
    }
  }

  AdminUserReviewActionCallback _callbackFor(AdminUserReviewAction action) {
    switch (action) {
      case AdminUserReviewAction.approve:
        return widget.onApprove;
      case AdminUserReviewAction.reject:
        return widget.onReject;
      case AdminUserReviewAction.block:
        return widget.onBlock;
    }
  }

  void _openDocumentPreview(IdentityDocumentSlot slot) {
    if (isSubmitting) return;
    showIdentityDocumentsPreview(
      context: context,
      items: widget.data.documents,
      initialItemId: slot.id,
      httpHeaders: widget.httpHeaders,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final hasPriorNote =
        widget.data.adminReviewNote != null &&
        widget.data.adminReviewNote!.trim().isNotEmpty;
    final gender = widget.data.gender.trim();
    final dobLine = gender.isEmpty
        ? 'DOB: ${formatDob(widget.data.dateOfBirth)}'
        : 'DOB: ${formatDob(widget.data.dateOfBirth)} · $gender';
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Header(
            theme: theme,
            fullName: widget.data.fullName,
            userName: widget.data.userName,
          ),
          const SizedBox(height: 20),
          if (widget.showDocuments) ...[
            Expanded(
              child: DocumentsGrid(
                documents: widget.data.documents,
                onTap: _openDocumentPreview,
                httpHeaders: widget.httpHeaders,
              ),
            ),
            const SizedBox(height: 12),
          ],
          Text(dobLine, style: theme.textTheme.h4),
          if (hasPriorNote) ...[
            const SizedBox(height: 20),
            SectionLabel(theme: theme, text: 'Prior review note'),
            const SizedBox(height: 6),
            PriorNoteCallout(
              theme: theme,
              note: widget.data.adminReviewNote!,
            ),
          ],
          const SizedBox(height: 12),
          ActionRow(
            blockLabel: 'Block',
            selected: selectedAction,
            enabled: !isSubmitting,
            onSelect: _selectAction,
          ),
        ],
      ),
    );
  }
}

String formatDob(DateTime dob) {
  final dd = dob.day.toString().padLeft(2, '0');
  final mm = dob.month.toString().padLeft(2, '0');
  final yyyy = dob.year.toString().padLeft(4, '0');
  return '$dd/$mm/$yyyy';
}

class Header extends StatelessWidget {
  const Header({
    required this.theme,
    required this.fullName,
    required this.userName,
    super.key,
  });

  final ShadThemeData theme;
  final String fullName;
  final String userName;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(fullName, style: theme.textTheme.h3, softWrap: true),
        const SizedBox(height: 2),
        Text(userName, style: theme.textTheme.muted),
      ],
    );
  }
}

class SectionLabel extends StatelessWidget {
  const SectionLabel({required this.theme, required this.text, super.key});

  final ShadThemeData theme;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(text, style: theme.textTheme.small);
  }
}

class PriorNoteCallout extends StatelessWidget {
  const PriorNoteCallout({required this.theme, required this.note, super.key});

  final ShadThemeData theme;
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.muted.withValues(alpha: 0.6),
        border: Border.all(color: theme.colorScheme.border),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        note,
        style: theme.textTheme.small.copyWith(
          color: theme.colorScheme.mutedForeground,
        ),
      ),
    );
  }
}

class DocumentsGrid extends StatelessWidget {
  const DocumentsGrid({
    required this.documents,
    required this.onTap,
    required this.httpHeaders,
    super.key,
  });

  final List<IdentityDocumentSlot> documents;
  final void Function(IdentityDocumentSlot) onTap;
  final Map<String, String> httpHeaders;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    if (documents.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: theme.colorScheme.border),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'No documents on file.',
          textAlign: TextAlign.center,
          style: theme.textTheme.muted,
        ),
      );
    }
    // One thumbnail per row. Each row is Expanded so the column fits the
    // height the parent allocates — thumbnails shrink (height first, then
    // width by aspect ratio) so the form never needs to scroll.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (var i = 0; i < documents.length; i++) ...[
          if (i > 0) const SizedBox(height: 12),
          Expanded(
            child: DocThumb(
              slot: documents[i],
              onTap: onTap,
              httpHeaders: httpHeaders,
            ),
          ),
        ],
      ],
    );
  }
}

class DocThumb extends StatelessWidget {
  const DocThumb({
    required this.slot,
    required this.onTap,
    required this.httpHeaders,
    super.key,
  });

  final IdentityDocumentSlot slot;
  final void Function(IdentityDocumentSlot) onTap;
  final Map<String, String> httpHeaders;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(slot),
        child: Center(
          child: AspectRatio(
            aspectRatio: kIdentityDocCardAspect,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: theme.colorScheme.card,
                border: Border.all(color: theme.colorScheme.border),
                borderRadius: BorderRadius.circular(10),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: CredentialedNetworkImage(
                  imageUrl: slot.uri,
                  httpHeaders: httpHeaders,
                  fit: BoxFit.cover,
                  errorBuilder: (_) => ThumbPlaceholder(
                    theme: theme,
                    filename: slot.fileName,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ThumbPlaceholder extends StatelessWidget {
  const ThumbPlaceholder({required this.theme, this.filename, super.key});

  final ShadThemeData theme;
  final String? filename;

  @override
  Widget build(BuildContext context) {
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
}

class ActionRow extends StatelessWidget {
  const ActionRow({
    required this.blockLabel,
    required this.selected,
    required this.enabled,
    required this.onSelect,
    super.key,
  });

  final String blockLabel;
  final AdminUserReviewAction? selected;
  final bool enabled;
  final ValueChanged<AdminUserReviewAction> onSelect;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: SelectableButton(
            label: blockLabel,
            variant: ButtonVariant.destructiveGhost,
            isSelected: selected == AdminUserReviewAction.block,
            enabled: enabled,
            onPressed: () => onSelect(AdminUserReviewAction.block),
          ),
        ),
        const SizedBox(width: 8),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SelectableButton(
              label: 'Reject',
              variant: ButtonVariant.secondary,
              isSelected: selected == AdminUserReviewAction.reject,
              enabled: enabled,
              onPressed: () => onSelect(AdminUserReviewAction.reject),
            ),
            const SizedBox(width: 8),
            SelectableButton(
              label: 'Approve',
              variant: ButtonVariant.primary,
              isSelected: selected == AdminUserReviewAction.approve,
              enabled: enabled,
              onPressed: () => onSelect(AdminUserReviewAction.approve),
            ),
          ],
        ),
      ],
    );
  }
}

enum ButtonVariant { primary, secondary, ghost, destructiveGhost }

/// Action selector for the review form. Visually the buttons stay in their
/// default shad variants regardless of selection — the source of truth for
/// "what's currently selected" is the Confirm button label that appears
/// below once any action is picked. A thin accent ring is added around the
/// currently selected button so the admin gets a subtle visual anchor too.
class SelectableButton extends StatelessWidget {
  const SelectableButton({
    required this.label,
    required this.variant,
    required this.isSelected,
    required this.enabled,
    required this.onPressed,
    super.key,
  });

  final String label;
  final ButtonVariant variant;
  final bool isSelected;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final button = _buildButton();
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          width: 2,
        ),
      ),
      padding: const EdgeInsets.all(2),
      child: button,
    );
  }

  Widget _buildButton() {
    final onTap = enabled ? onPressed : null;
    final child = Text(label, maxLines: 1, overflow: TextOverflow.ellipsis);
    switch (variant) {
      case ButtonVariant.primary:
        return ShadButton(onPressed: onTap, child: child);
      case ButtonVariant.secondary:
        return ShadButton.secondary(onPressed: onTap, child: child);
      case ButtonVariant.ghost:
        return ShadButton.ghost(onPressed: onTap, child: child);
      case ButtonVariant.destructiveGhost:
        return Builder(
          builder: (context) {
            final destructive = ShadTheme.of(context).colorScheme.destructive;
            return ShadButton.ghost(
              onPressed: onTap,
              foregroundColor: destructive,
              hoverForegroundColor: destructive,
              pressedForegroundColor: destructive,
              child: child,
            );
          },
        );
    }
  }
}

/// Modal reason collector used for Reject/Block (issue #507).
///
/// Returns the trimmed reason on Confirm (empty string allowed — the
/// caller maps it to null), or `null` if the admin cancels. Uses
/// [ShadDialog] so the keyboard handling, dimming, and focus trap are
/// the shadcn defaults the rest of the app already uses.
class ReasonDialog extends StatefulWidget {
  const ReasonDialog({
    required this.action,
    required this.userFullName,
    super.key,
  });

  final AdminUserReviewAction action;
  final String userFullName;

  static Future<String?> show({
    required BuildContext context,
    required AdminUserReviewAction action,
    required String userFullName,
  }) {
    return showShadDialog<String>(
      context: context,
      builder: (_) => ReasonDialog(
        action: action,
        userFullName: userFullName,
      ),
    );
  }

  @override
  State<ReasonDialog> createState() => ReasonDialogState();
}

class ReasonDialogState extends State<ReasonDialog> {
  final controller = TextEditingController();
  String? errorText;

  String get _actionVerb => switch (widget.action) {
    AdminUserReviewAction.approve => 'Approve',
    AdminUserReviewAction.reject => 'Reject',
    AdminUserReviewAction.block => 'Block',
  };

  String get _placeholder => switch (widget.action) {
    AdminUserReviewAction.approve =>
      'Optional — anything the user should know.',
    AdminUserReviewAction.reject =>
      'Optional — what does the user need to fix?',
    AdminUserReviewAction.block => 'Optional — why is this user being blocked?',
  };

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  void _handleConfirm() {
    final reason = controller.text.trim();
    final error = AdminUserReviewFormValidators.reason(reason, widget.action);
    if (error != null) {
      setState(() => errorText = error);
      return;
    }
    Navigator.of(context).pop(reason);
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final length = controller.text.trim().length;
    return ShadDialog(
      // Suppress the default top-right close glyph — Cancel below already
      // gives the admin a way out, and the X is visual noise. Issue #507.
      closeIcon: const SizedBox.shrink(),
      title: Text('$_actionVerb ${widget.userFullName}'),
      actions: [
        ShadButton.secondary(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ShadButton(
          onPressed: _handleConfirm,
          child: Text('Confirm $_actionVerb'),
        ),
      ],
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ShadInput(
            controller: controller,
            placeholder: Text(_placeholder),
            maxLines: 4,
            minLines: 3,
            maxLength: kAdminReviewReasonMaxLength,
            keyboardType: TextInputType.multiline,
            textInputAction: TextInputAction.newline,
            autofocus: true,
            onChanged: (_) {
              if (errorText != null) {
                setState(() => errorText = null);
              } else {
                setState(() {});
              }
            },
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              if (errorText != null)
                Expanded(
                  child: Text(
                    errorText!,
                    style: theme.textTheme.small.copyWith(
                      color: theme.colorScheme.destructive,
                    ),
                  ),
                )
              else
                const Spacer(),
              Text(
                '$length / $kAdminReviewReasonMaxLength',
                style: theme.textTheme.small.copyWith(
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
