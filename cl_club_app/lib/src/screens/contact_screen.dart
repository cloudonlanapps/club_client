import 'package:cl_club_branding/cl_club_branding.dart' show AppLogo;
import 'package:cl_remote_store/cl_remote_store.dart' show contactInfoProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show TitleRow;

import '../widgets/club_address_card.dart';
import '../widgets/contact_actions_card.dart';

/// How to reach the club, from `contactInfoProvider`: the server's details
/// once they arrive, the host's bundled ones until then (club_core#53).
class ContactScreen extends ConsumerWidget {
  const ContactScreen({super.key});

  /// Below this width the sidebar, and the brand in it, is hidden, so the
  /// page shows the logo and club name itself.
  static const double mobileBreakpoint = 768;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);
    final contact = ref.watch(contactInfoProvider);
    final isMobile = MediaQuery.sizeOf(context).width < mobileBreakpoint;

    return Column(
      children: [
        TitleRow(
          title: 'Contact Us',
          onBack: context.canPop() ? () => context.pop() : null,
        ),
        const Divider(height: 1),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (isMobile) ...[
                      const AppLogo(height: 96),
                      const SizedBox(height: 12),
                      Text(
                        contact.clubName,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.h4.copyWith(
                          color: theme.colorScheme.primary,
                          letterSpacing: 0.5,
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                    ContactActionsCard(contact: contact),
                    const SizedBox(height: 16),
                    if (contact.hasAddress) ClubAddressCard(contact: contact),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
