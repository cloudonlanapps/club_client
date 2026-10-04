import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ClubTextTheme, ThemedMarkdown;

import '../../../models/public/public_event_view.dart';
import 'public_event_benefit_card.dart';

class PublicEventMembershipSection extends StatelessWidget {
  const PublicEventMembershipSection({required this.event, super.key});
  final PublicEventView event;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;
    final membership = event.clubMembership!;
    final themeColor = theme.colorScheme.primary;
    final benefits = membership.benefits ?? [];

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 48),
      child: Column(
        children: [
          Text(
            membership.title,
            style: theme.textTheme.sectionTitle(isMobile: isMobile),
          ),
          if (membership.description != null) ...[
            const SizedBox(height: 8),
            ThemedMarkdown(
              data: membership.description!,
              selectable: false,
              textStyle: theme.textTheme.muted,
            ),
          ],
          if (benefits.isNotEmpty) ...[
            const SizedBox(height: 32),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: isMobile
                  ? Column(
                      children: [
                        for (int i = 0; i < benefits.length; i++) ...[
                          if (i > 0) const SizedBox(height: 16),
                          PublicEventBenefitCard(
                            title: benefits[i],
                            color: themeColor,
                          ),
                        ],
                      ],
                    )
                  : IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (int i = 0; i < benefits.length; i++) ...[
                            if (i > 0) const SizedBox(width: 24),
                            Expanded(
                              child: PublicEventBenefitCard(
                                title: benefits[i],
                                color: themeColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
