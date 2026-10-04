import 'package:cl_remote_store/cl_remote_store.dart' show ContactInfo;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// The club's postal address, one line per line, in the current locale's
/// language.
class ClubAddressCard extends StatelessWidget {
  const ClubAddressCard({required this.contact, super.key});

  final ContactInfo contact;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final languageCode = Localizations.localeOf(context).languageCode;
    final lines = contact.fullAddress(languageCode).split('\n');

    return ShadCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.mapPin, color: theme.colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Address', style: theme.textTheme.h4),
                const SizedBox(height: 8),
                for (final line in lines) Text(line, style: theme.textTheme.p),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
