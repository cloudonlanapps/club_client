import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../models/identity_documents_submit_sizes.dart';
import '../models/identity_documents_submit_strings.dart';

/// The collapsed help section of the submit-documents step: what makes an
/// upload acceptable.
class IdentityDocumentsUploadTips extends StatelessWidget {
  const IdentityDocumentsUploadTips({super.key});

  @override
  Widget build(BuildContext context) {
    final style = ShadTheme.of(context).textTheme.p;
    return ShadAccordion<String>.multiple(
      initialValue: const [],
      children: [
        ShadAccordionItem<String>(
          value: IdentityDocumentsSubmitStrings.tipsTitle,
          title: Text(IdentityDocumentsSubmitStrings.tipsTitle, style: style),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              vertical: IdentityDocumentsSubmitSizes.tipsPadding,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              spacing: IdentityDocumentsSubmitSizes.tipGap,
              children: [
                for (final tip in IdentityDocumentsSubmitStrings.tips)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('-  ', style: style),
                      Expanded(child: Text(tip, style: style)),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
