import 'package:cl_club_forms/cl_club_forms.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Demo screen for [IdentityDocumentsConsentForm]: plays the host's part
/// with a Submit button that validates the form.
class IdentityDocumentsConsentScreen extends StatefulWidget {
  const IdentityDocumentsConsentScreen({super.key});

  @override
  State<IdentityDocumentsConsentScreen> createState() =>
      _IdentityDocumentsConsentScreenState();
}

class _IdentityDocumentsConsentScreenState
    extends State<IdentityDocumentsConsentScreen> {
  final consentKey = GlobalKey<IdentityDocumentsConsentFormState>();

  void handleSubmit() {
    if (consentKey.currentState?.validate() == null) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Consent given.')));
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      spacing: 16,
      children: [
        IdentityDocumentsConsentForm(key: consentKey),
        Align(
          alignment: Alignment.centerRight,
          child: ShadButton(
            onPressed: handleSubmit,
            child: const Text('Submit'),
          ),
        ),
      ],
    );
  }
}
