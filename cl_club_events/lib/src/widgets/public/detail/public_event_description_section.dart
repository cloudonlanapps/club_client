import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ThemedMarkdown;

import '../../../models/public/public_event_view.dart';

class PublicEventDescriptionSection extends StatelessWidget {
  const PublicEventDescriptionSection({required this.event, super.key});

  final PublicEventView event;

  @override
  Widget build(BuildContext context) {
    final description = event.fullDescription ?? event.description;
    if (description.isEmpty) return const SizedBox.shrink();

    final theme = ShadTheme.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < 768;
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(isMobile ? 24 : 48),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: ThemedMarkdown(
            data: description,
            selectable: false,
            textAlign: TextAlign.justify,
            textStyle: theme.textTheme.p.copyWith(height: 1.6, fontSize: 16),
          ),
        ),
      ),
    );
  }
}
