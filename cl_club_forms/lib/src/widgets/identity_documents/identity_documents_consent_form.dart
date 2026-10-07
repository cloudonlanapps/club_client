import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/form_contract.dart';
import 'identity_documents_consent_form_fields.dart';
import 'identity_documents_consent_strings.dart';
import 'identity_documents_privacy_dialog.dart';

/// Pure-UI form holding a member's agreement to the privacy policy for
/// their identity documents (no SDK, no Riverpod): one checkbox, whose
/// label links to the policy.
///
/// Owns no buttons: the host drives it through a
/// `GlobalKey<IdentityDocumentsConsentFormState>` and calls `validate()`
/// before it submits the documents for review: it returns the values keyed
/// by [IdentityDocumentsConsentFormFields], or null, with the message on the
/// checkbox, when the member has not agreed ([FormContract]).
class IdentityDocumentsConsentForm extends StatefulWidget {
  const IdentityDocumentsConsentForm({this.enabled = true, super.key});

  /// Whether the checkbox and the policy link respond.
  final bool enabled;

  @override
  State<IdentityDocumentsConsentForm> createState() =>
      IdentityDocumentsConsentFormState();
}

/// State of [IdentityDocumentsConsentForm].
class IdentityDocumentsConsentFormState
    extends State<IdentityDocumentsConsentForm>
    with FormContract<IdentityDocumentsConsentForm> {
  @override
  bool get focusFirstInvalid => false;

  /// Opens the policy from the link in the label.
  late final TapGestureRecognizer policyTap;

  @override
  void initState() {
    super.initState();
    policyTap = TapGestureRecognizer()..onTap = openPolicy;
  }

  @override
  void dispose() {
    policyTap.dispose();
    super.dispose();
  }

  /// Shows the privacy policy.
  void openPolicy() {
    if (!widget.enabled) return;
    unawaited(
      showShadDialog<void>(
        context: context,
        builder: (_) => const IdentityDocumentsPrivacyPolicyDialog(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    return ShadForm(
      key: formKey,
      enabled: widget.enabled,
      initialValue: const {
        IdentityDocumentsConsentFormFields.privacyAcceptedId: false,
      },
      child: FormBody(
        error: formError,
        children: [
          ShadCheckboxFormField(
            id: IdentityDocumentsConsentFormFields.privacyAcceptedId,
            initialValue: false,
            validator: (accepted) =>
                accepted ? null : IdentityDocumentsConsentStrings.required,
            inputLabel: Text.rich(
              TextSpan(
                children: [
                  const TextSpan(text: IdentityDocumentsConsentStrings.lead),
                  TextSpan(
                    text: IdentityDocumentsConsentStrings.link,
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: policyTap,
                  ),
                  const TextSpan(text: IdentityDocumentsConsentStrings.tail),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
