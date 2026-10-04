import 'package:club_sdk_2/club_sdk_2.dart' show Facility;
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ThemedMarkdown;

import '../../../extensions/facility_icon.dart';

class PublicEventFacilityCard extends StatelessWidget {
  const PublicEventFacilityCard({
    required this.facility,
    required this.color,
    super.key,
  });
  final Facility facility;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return ShadCard(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(facility.iconValue, size: 32, color: color),
            ),
            const SizedBox(height: 16),
            Text(
              facility.name,
              style: theme.textTheme.h4,
              textAlign: TextAlign.center,
            ),
            if (facility.description != null) ...[
              const SizedBox(height: 8),
              ThemedMarkdown(
                data: facility.description!,
                selectable: false,
                textStyle: theme.textTheme.muted,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
