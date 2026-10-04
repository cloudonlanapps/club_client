import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show MapEmbed, ThemedMarkdown;

/// Venue detail content — description and map.
///
/// Read-only and presentational, on display fields, so the member zone (from
/// a `Venue`) and the public website (from a `PublicVenue`) render the same
/// widget, each inside its own shell.
class VenueContent extends StatelessWidget {
  const VenueContent({
    this.description,
    this.mapUri,
    this.selectable = true,
    super.key,
  });

  /// Narrower than this is laid out for a phone.
  static const double mobileBreakpoint = 768;

  /// Widest the description and map grow.
  static const double maxContentWidth = 1000;

  /// Heading above the map.
  static const String locationHeading = 'Location';

  /// The venue's description, as markdown.
  final String? description;

  /// The venue's map, in the form `MapEmbed` takes.
  final String? mapUri;

  /// Whether the description's text can be selected.
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final isMobile = MediaQuery.sizeOf(context).width < mobileBreakpoint;
    final text = description;
    final map = mapUri;

    return Container(
      padding: EdgeInsets.all(isMobile ? 24 : 48),
      child: Column(
        children: [
          const SizedBox(height: 40),
          if (text != null)
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxContentWidth),
              child: ThemedMarkdown(
                data: text,
                selectable: selectable,
                textAlign: TextAlign.justify,
              ),
            ),
          if (map != null) ...[
            const SizedBox(height: 32),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: maxContentWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        LucideIcons.map,
                        size: 20,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(locationHeading, style: theme.textTheme.h4),
                    ],
                  ),
                  const SizedBox(height: 16),
                  MapEmbed(
                    mapUri: map,
                    height: isMobile ? 300 : 400,
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }
}
