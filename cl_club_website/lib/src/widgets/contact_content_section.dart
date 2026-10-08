import 'package:cl_club_forms/cl_club_forms.dart' show InquiryChoice;
import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:ui_lib/ui_lib.dart' show MapEmbed;

import '../models/contact_map_config.dart';
import '../page_content/contact/contact_page_labels.dart';
import '../page_content/site_copy.dart';
import 'club_contact_card.dart';
import 'inquiry_view.dart';

/// Contact content section with info card and map.
class ContactContentSection extends StatelessWidget {
  const ContactContentSection({
    required this.contactPageLabels,
    required this.mapConfig,
    required this.whatsappLabel,
    super.key,
  });
  final ContactPageLabels contactPageLabels;
  final ContactMapConfig mapConfig;
  final String whatsappLabel;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    final strings = SiteCopy.of(context).strings;
    final form = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560),
      child: InquiryView(
        kind: InquiryKind.contact,
        title: contactPageLabels.form.title,
        description: contactPageLabels.form.description,
        messageLabel: contactPageLabels.form.messageLabel,
        messagePlaceholder: contactPageLabels.form.messagePlaceholder,
        submitLabel: contactPageLabels.form.submitButton,
        thanksTitle: strings.contactFormThanksTitle,
        thanksBody: strings.contactFormThanksBody,
        choices: [
          InquiryChoice(
            key: 'subject',
            label: contactPageLabels.form.subjectLabel,
            placeholder: contactPageLabels.form.subjectPlaceholder,
            options: {
              'registration':
                  contactPageLabels.form.subjectOptions.registration,
              'programs': contactPageLabels.form.subjectOptions.programs,
              'facility': contactPageLabels.form.subjectOptions.facility,
              'sponsorship': contactPageLabels.form.subjectOptions.sponsorship,
              'other': contactPageLabels.form.subjectOptions.other,
            },
          ),
        ],
      ),
    );
    final info = ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 400),
      child: ClubContactCard(
        labels: contactPageLabels.info,
        whatsappLabel: whatsappLabel,
      ),
    );

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 48),
      child: Column(
        children: [
          // Side by side where there is room; the form first on a narrow
          // screen, because it is what the page is for.
          if (isMobile)
            Column(
              children: [form, const SizedBox(height: 32), info],
            )
          else
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(child: form),
                const SizedBox(width: 32),
                Flexible(child: info),
              ],
            ),
          if (mapConfig.hasEmbed) ...[
            SizedBox(height: isMobile ? 40 : 60),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: MapEmbed(
                mapUri: mapConfig.mapUri,
                height: isMobile ? 300 : 400,
                fallbackTitle: mapConfig.fallbackTitle,
                openInMapsText: contactPageLabels.map.openInMapsButton,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
