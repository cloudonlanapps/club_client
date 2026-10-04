import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../page_content/page_common.dart';
import '../page_content/site_copy.dart';
import 'public_page_shell.dart';

/// Reusable not-found page widget.
///
/// Takes its labels from the site's own copy, falling back to a generic set
/// for a key it has none for.
///
/// Valid keys: 'program', 'camp', 'oneoff', 'venue'
class NotFoundPage extends StatelessWidget {
  const NotFoundPage({required this.notFoundKey, super.key});

  /// Key to identify which not-found labels to load.
  /// Valid values: 'program', 'camp', 'oneoff', 'venue'
  final String notFoundKey;

  @override
  Widget build(BuildContext context) {
    final labels =
        SiteCopy.of(context).notFound(notFoundKey) ??
        _defaultLabels(notFoundKey);
    final theme = ShadTheme.of(context);

    return PublicPageShell(
      pageTitle: labels.pageTitle,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                _iconFromName(labels.iconName),
                size: 64,
                color: theme.colorScheme.mutedForeground,
              ),
              const SizedBox(height: 24),
              Text(labels.title, style: theme.textTheme.h2),
              const SizedBox(height: 12),
              Text(
                labels.description,
                style: theme.textTheme.muted,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              ShadButton(
                onPressed: () => context.go(labels.buttonRoute),
                child: Text(labels.buttonText),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Default labels when server data unavailable.
  static NotFoundLabels _defaultLabels(String key) {
    switch (key) {
      case 'program':
        return const NotFoundLabels(
          pageTitle: 'Program Not Found',
          title: 'Program Not Found',
          description:
              "The program you're looking for doesn't exist or has been "
              'removed.',
          buttonText: 'View All Programs',
          buttonRoute: '/public/programs',
        );
      case 'camp':
        return const NotFoundLabels(
          pageTitle: 'Camp Not Found',
          title: 'Camp Not Found',
          description:
              "The camp you're looking for doesn't exist or has been removed.",
          buttonText: 'View All Camps',
          buttonRoute: '/public/events',
        );
      case 'oneoff':
        return const NotFoundLabels(
          pageTitle: 'Event Not Found',
          title: 'Event Not Found',
          description:
              "The event you're looking for doesn't exist or has been removed.",
          buttonText: 'View All Events',
          buttonRoute: '/public/one-off',
        );
      case 'venue':
        return const NotFoundLabels(
          pageTitle: 'Venue Not Found',
          title: 'Venue Not Found',
          description: "The venue you're looking for doesn't exist.",
          buttonText: 'View All Rinks',
          buttonRoute: '/public/rinks',
          iconName: 'mapPinOff',
        );
      default:
        return const NotFoundLabels(
          pageTitle: 'Not Found',
          title: 'Not Found',
          description: 'The page you are looking for does not exist.',
          buttonText: 'Go Home',
          buttonRoute: '/',
        );
    }
  }

  static IconData _iconFromName(String name) {
    switch (name) {
      case 'searchX':
        return LucideIcons.searchX;
      case 'mapPinOff':
        return LucideIcons.mapPinOff;
      default:
        return LucideIcons.circleAlert;
    }
  }
}
