import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/src/widgets/signup/signup_form.dart' show SignupForm;
import 'package:ui_lib/ui_lib.dart' show SignupForm;

import 'identity_document_slot.dart';
import 'identity_documents_field.dart';
import 'identity_documents_picker.dart';
import 'identity_documents_privacy_dialog.dart';

/// Form-level field ids.
const String kIdentityDocsFieldId = 'identityDocuments';
const String kPrivacyAcceptedFieldId = 'privacyAccepted';

/// Pure UI form for submitting one or two identity documents.
///
/// Container, typography and field rhythm follow the same conventions as
/// [SignupForm] (max width 420, padding 24, h3 title + muted subtitle,
/// 12px between fields, full-width primary button with text-swap on busy).
class IdentityDocumentsForm extends StatefulWidget {
  const IdentityDocumentsForm({
    required this.onUpload,
    required this.onDiscard,
    required this.onSubmit,
    super.key,
    this.initialItems = const [],
    this.config = IdentityDocumentsFormConfig.defaults,
    this.onDoLater,
    this.httpHeaders = const {},
    this.picker = defaultIdentityDocumentsPicker,
  });

  /// Pre-populated items — both orphans (uploaded earlier, not linked) and
  /// already-linked gallery items go here. The form treats them identically.
  final List<IdentityDocumentSlot> initialItems;

  /// Host callback: upload picked bytes to the server.
  final IdentityDocsUploadCallback onUpload;

  /// Host callback: remove a slot (orphan or linked — host figures it out).
  final IdentityDocsDiscardCallback onDiscard;

  /// Host callback: invoked with the validated form value map. Host is
  /// responsible for creating gallery links for orphan slots. While the
  /// returned future is pending, the form is in its submitting state
  /// (picker + checkbox disabled, button text reads "Submitting…");
  /// whether the future completes or throws, the form returns to idle.
  ///
  /// Value shape:
  /// ```dart
  /// {
  ///   'identityDocuments': List<IdentityDocumentSlot>,
  ///   'privacyAccepted': true,
  /// }
  /// ```
  final Future<void> Function(Map<String, dynamic> formValue) onSubmit;

  final IdentityDocumentsFormConfig config;

  /// Optional escape hatch: when supplied, a muted ghost button labelled
  /// "I'll do it later" appears next to Submit. The host typically wires
  /// it to logout so the user can leave the onboarding flow without
  /// submitting documents.
  final VoidCallback? onDoLater;

  /// HTTP headers forwarded to slot preview image requests.
  ///
  /// Populate from `imageAuthHeadersProvider` (in `cl_member_auth`) when
  /// the host's preview URIs may require authentication. Empty by default
  /// so existing tests and public-URI usage keep working unchanged.
  final Map<String, String> httpHeaders;

  /// Image picker for the add-document affordance. Defaults to the native
  /// file dialog ([defaultIdentityDocumentsPicker]); the host injects it from
  /// `imagePickerProvider` so integration tests can substitute a stub that
  /// returns fixed bytes instead of opening a real OS dialog.
  final IdentityDocumentsPicker picker;

  @override
  State<IdentityDocumentsForm> createState() => IdentityDocumentsFormState();
}

class IdentityDocumentsFormState extends State<IdentityDocumentsForm> {
  final formKey = GlobalKey<ShadFormState>();
  bool privacyAccepted = false;
  bool isSubmitting = false;
  List<IdentityDocumentSlot> currentItems = const [];
  late final TapGestureRecognizer _privacyTap;

  @override
  void initState() {
    super.initState();
    currentItems = widget.initialItems;
    _privacyTap = TapGestureRecognizer()..onTap = _handlePrivacyTap;
  }

  @override
  void dispose() {
    _privacyTap.dispose();
    super.dispose();
  }

  void _handlePrivacyTap() {
    if (!isSubmitting) unawaited(showPrivacyPolicy());
  }

  Map<String, dynamic> get initialValues => {
    kIdentityDocsFieldId: widget.initialItems,
    kPrivacyAcceptedFieldId: false,
  };

  bool get canSubmit =>
      !isSubmitting && privacyAccepted && currentItems.isNotEmpty;

  Future<void> handleSubmit() async {
    final form = formKey.currentState;
    if (form == null || !form.saveAndValidate()) return;
    setState(() => isSubmitting = true);
    try {
      await widget.onSubmit(form.value);
    } finally {
      if (mounted) setState(() => isSubmitting = false);
    }
  }

  Future<void> showPrivacyPolicy() async {
    await showShadDialog<void>(
      context: context,
      builder: (_) => const IdentityDocumentsPrivacyPolicyDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadForm(
      key: formKey,
      initialValue: initialValues,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'We need a clear photo of your Aadhaar card to confirm '
            'your name and date of birth.',
            style: theme.textTheme.p,
          ),
          const SizedBox(height: 16),
          IdentityDocumentsFormField(
            id: kIdentityDocsFieldId,
            initialValue: widget.initialItems,
            enabled: !isSubmitting,
            config: widget.config,
            picker: widget.picker,
            httpHeaders: widget.httpHeaders,
            onUpload: widget.onUpload,
            onDiscard: widget.onDiscard,
            onChanged: (v) => setState(() => currentItems = v ?? const []),
            validator: (items) => (items == null || items.isEmpty)
                ? 'Please add at least one file to continue.'
                : null,
          ),
          const SizedBox(height: 32),
          ShadCheckboxFormField(
            id: kPrivacyAcceptedFieldId,
            initialValue: false,
            enabled: !isSubmitting,
            inputLabel: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: 'I agree to the '),
                  TextSpan(
                    text: 'Privacy Policy',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: _privacyTap,
                  ),
                  const TextSpan(text: '.'),
                ],
              ),
            ),
            onChanged: (v) => setState(() => privacyAccepted = v),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (widget.onDoLater != null)
                ShadButton.ghost(
                  onPressed: isSubmitting ? null : widget.onDoLater,
                  child: Text(
                    "I'll do it later",
                    style: theme.textTheme.muted,
                  ),
                ),
              if (widget.onDoLater != null) const SizedBox(width: 8),
              ShadButton(
                enabled: canSubmit,
                onPressed: canSubmit ? handleSubmit : null,
                child: Text(
                  isSubmitting ? 'Submitting…' : 'Submit',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ShadAccordion<String>.multiple(
            initialValue: const [],
            children: [
              ShadAccordionItem<String>(
                value: 'tips',
                title: Text(
                  'Tips for a clean upload',
                  style: theme.textTheme.p,
                ),
                child: UploadTips(theme: theme),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class UploadTips extends StatelessWidget {
  const UploadTips({required this.theme, super.key});

  final ShadThemeData theme;

  @override
  Widget build(BuildContext context) {
    return BulletList(
      items: const [
        'Regular or masked Aadhaar are both accepted.',
        'Name and date of birth must be readable.',
        'File size must be under 2 MB.',
        'If taking a fresh photo, use good light and hold the camera steady.',
      ],
      style: theme.textTheme.p,
    );
  }
}

class BulletList extends StatelessWidget {
  const BulletList({required this.items, required this.style, super.key});

  final List<String> items;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(0, 4, 0, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('-  ', style: style),
                  Expanded(child: Text(item, style: style)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
