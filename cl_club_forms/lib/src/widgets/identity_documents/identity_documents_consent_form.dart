import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../form/form_body.dart';
import '../form/form_contract.dart';
import 'identity_documents_consent_form_fields.dart';
import 'identity_documents_consent_form_validators.dart';
import 'identity_documents_consent_strings.dart';

/// Pure-UI form holding a member's agreement to the privacy policy for
/// their identity documents (no SDK, no Riverpod): one checkbox, whose
/// label links to the policy. The form opens nothing: a tap on the link
/// calls [onShowPolicy], and the host shows its policy.
///
/// Owns no buttons: the host drives it through a
/// `GlobalKey<IdentityDocumentsConsentFormState>` and calls `validate()`
/// before it submits the documents for review: it returns the values keyed
/// by [IdentityDocumentsConsentFormFields], or null, with the message on the
/// checkbox, when the member has not agreed ([FormContract]).
class IdentityDocumentsConsentForm extends StatefulWidget {
  const IdentityDocumentsConsentForm({
    required this.onShowPolicy,
    this.enabled = true,
    super.key,
  });

  /// Whether the checkbox and the policy link respond.
  final bool enabled;

  /// A tap on the policy link in the label; the host shows the policy.
  final VoidCallback onShowPolicy;

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

  /// Hands a tap on the link in the label to [showPolicy].
  late final TapGestureRecognizer policyTap;

  @override
  void initState() {
    super.initState();
    policyTap = TapGestureRecognizer()..onTap = showPolicy;
  }

  @override
  void dispose() {
    policyTap.dispose();
    super.dispose();
  }

  /// Asks the host for the privacy policy; nothing while the form is off.
  void showPolicy() {
    if (!widget.enabled) return;
    widget.onShowPolicy();
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
            validator: IdentityDocumentsConsentFormValidators.consent,
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
