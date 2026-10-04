import 'package:cl_club_branding/cl_club_branding.dart' show launchContactUrl;
import 'package:cl_remote_store/cl_remote_store.dart' show ContactInfo;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'contact_row.dart';

/// WhatsApp, phone and email, each opening its app; the WhatsApp message
/// and email subject in the current locale's language.
class ContactActionsCard extends StatelessWidget {
  const ContactActionsCard({required this.contact, super.key});

  final ContactInfo contact;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Reach us', style: theme.textTheme.h4),
          const SizedBox(height: 12),
          ContactRow(
            icon: LucideIcons.messageCircle,
            label: 'WhatsApp',
            value: contact.whatsappOrPhone,
            onTap: () => launchContactUrl(contact.whatsappUrl(languageCode)),
          ),
          const Divider(height: 24),
          ContactRow(
            icon: LucideIcons.phone,
            label: 'Phone',
            value: contact.phoneNumber,
            onTap: () => launchContactUrl(contact.phoneUrl),
          ),
          const Divider(height: 24),
          ContactRow(
            icon: LucideIcons.mail,
            label: 'Email',
            value: contact.email,
            onTap: () => launchContactUrl(contact.emailUrl(languageCode)),
          ),
        ],
      ),
    );
  }
}
