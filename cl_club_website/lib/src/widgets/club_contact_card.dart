import 'package:cl_club_branding/cl_club_branding.dart' show launchContactUrl;
import 'package:cl_remote_store/cl_remote_store.dart' show contactInfoProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../page_content/contact/contact_info_labels.dart';
import 'club_contact_row.dart';
import 'instagram_mark.dart';
import 'instagram_qr_tile.dart';

/// The contact page's card: how to reach the club — address, phone,
/// WhatsApp, email — and its Instagram as a QR code.
///
/// Reads `contactInfoProvider` (club_core#53): the server's details field
/// by field over the host's bundled block, in the viewer's language.
class ClubContactCard extends ConsumerWidget {
  const ClubContactCard({
    required this.labels,
    required this.whatsappLabel,
    super.key,
  });

  final ContactInfoLabels labels;
  final String whatsappLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final contact = ref.watch(contactInfoProvider);
    final languageCode = Localizations.localeOf(context).languageCode;

    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(labels.title, style: theme.textTheme.h4),
            const SizedBox(height: 20),
            ClubContactRow(
              icon: LucideIcons.mapPin,
              title: labels.addressLabel,
              content: contact.fullAddress(languageCode),
            ),
            const SizedBox(height: 16),
            ClubContactRow(
              icon: LucideIcons.phone,
              title: labels.phoneLabel,
              content: contact.phoneNumber,
              onTap: () => launchContactUrl(contact.phoneUrl),
            ),
            const SizedBox(height: 16),
            ClubContactRow(
              icon: LucideIcons.messageCircle,
              title: whatsappLabel,
              content: contact.whatsappOrPhone,
              onTap: () => launchContactUrl(contact.whatsappUrl(languageCode)),
            ),
            const SizedBox(height: 16),
            ClubContactRow(
              icon: LucideIcons.mail,
              title: labels.emailLabel,
              content: contact.email,
              onTap: () => launchContactUrl(contact.emailUrl(languageCode)),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      InstagramMark(
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(labels.followUsLabel, style: theme.textTheme.h4),
                    ],
                  ),
                  const SizedBox(height: 16),
                  InstagramQrTile(instagramUrl: contact.instagramUrl),
                  const SizedBox(height: 12),
                  Text(
                    labels.qrCodeHint,
                    style: theme.textTheme.muted,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
