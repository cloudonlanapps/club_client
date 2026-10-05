import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../l10n/site_strings.dart';
import '../models/site_config.dart';
import '../providers/contact_fab_visibility.dart';
import '../providers/navbar_visibility.dart';
import 'page_meta_publisher.dart';
import 'route_labels.dart';
import 'scroll_direction_detector.dart';

/// Height of the navbar - must match PublicShellScaffold._navbarHeight
const double _navbarHeight = 64;

/// Shell widget for public pages that provides breadcrumb, footer, and FAB.
///
/// Note: The navbar is NOT included here - it should be provided by a parent
/// ShellRoute to keep it static during page transitions.
///
/// This widget ensures the navbar is visible when detail pages are shown,
/// fixing the issue where navbar remains hidden after navigating from
/// the landing page hero section.
class PublicPageShell extends ConsumerStatefulWidget {
  const PublicPageShell({
    required this.child,
    super.key,
    this.pageTitle,
    this.description,
    this.publishMeta = true,
    this.showContactFab = true,
  });
  final Widget child;

  /// Optional title for the current page (used in breadcrumb for detail pages)
  final String? pageTitle;

  /// What the page is about, for search engines; see [PageMetaPublisher].
  final String? description;

  /// Whether this shell names the page to the browser. Off for a shell that
  /// only stands in while the page's data loads.
  final bool publishMeta;

  /// Whether to show the contact FAB (default: true)
  final bool showContactFab;

  @override
  ConsumerState<PublicPageShell> createState() => _PublicPageShellState();
}

class _PublicPageShellState extends ConsumerState<PublicPageShell> {
  @override
  void initState() {
    super.initState();
    // Ensure navbar is visible and set FAB visibility when showing detail pages
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navbarVisibilityProvider.notifier).state = true;
      ref.read(contactFabVisibilityProvider.notifier).state =
          widget.showContactFab;
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    final layout = isMobile ? _buildMobileLayout() : _buildDesktopLayout();
    if (!widget.publishMeta) return layout;

    // A listing is named by its nav label, from the site's copy; a detail
    // page, whose last segment is an id, by the title its screen gives.
    final segment = GoRouterState.of(context).matchedLocation.split('/').last;
    return PageMetaPublisher(
      pageName:
          routeLabel(SiteStrings.of(context), segment)?.replaceAll('\n', ' ') ??
          widget.pageTitle,
      description: widget.description,
      child: layout,
    );
  }

  Widget _buildMobileLayout() {
    // Add top padding to account for navbar height
    // since content fills behind navbar via Positioned.fill in shell
    return ScrollDirectionDetector(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: _navbarHeight),
            Breadcrumb(pageTitle: widget.pageTitle),
            widget.child,
            const PublicFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout() {
    // Add top padding to account for navbar height
    // since content fills behind navbar via Positioned.fill in shell
    return Column(
      children: [
        const SizedBox(height: _navbarHeight),
        Breadcrumb(pageTitle: widget.pageTitle),
        Expanded(child: SingleChildScrollView(child: widget.child)),
        const PublicFooter(),
      ],
    );
  }
}

// =============================================================================
// BREADCRUMB (left-aligned)
// =============================================================================

class Breadcrumb extends StatelessWidget {
  const Breadcrumb({super.key, this.pageTitle});
  final String? pageTitle;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 1000;

    // Get current route path
    final currentPath = GoRouterState.of(context).matchedLocation;

    // Don't show breadcrumb on home page
    if (currentPath == '/' || currentPath.isEmpty) {
      return const SizedBox.shrink();
    }

    // Parse path segments (e.g., /public/events/123 -> [public, events, 123])
    final segments = currentPath.split('/').where((s) => s.isNotEmpty).toList();

    // Skip 'public' prefix for display
    final displaySegments = segments.length > 1 && segments[0] == 'public'
        ? segments.sublist(1)
        : segments;

    if (displaySegments.isEmpty) {
      return const SizedBox.shrink();
    }

    final canGoBack = context.canPop();

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 16 : 24,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.muted.withValues(alpha: 0.3),
        border: Border(bottom: BorderSide(color: theme.colorScheme.border)),
      ),
      child: Row(
        children: [
          // Back button (only when there's navigation history)
          if (canGoBack) ...[
            ShadButton.ghost(
              size: ShadButtonSize.sm,
              onPressed: () => context.pop(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    LucideIcons.arrowLeft,
                    size: 16,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Back',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Container(
                width: 1,
                height: 20,
                color: theme.colorScheme.border,
              ),
            ),
          ],
          // Breadcrumb
          Expanded(
            child: ShadBreadcrumb(
              separator: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Icon(
                  LucideIcons.chevronRight,
                  size: 14,
                  color: theme.colorScheme.mutedForeground,
                ),
              ),
              children: _buildBreadcrumbItems(context, displaySegments),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBreadcrumbItems(
    BuildContext context,
    List<String> segments,
  ) {
    final theme = ShadTheme.of(context);
    final items = <Widget>[
      // Home link (always first)
      ShadBreadcrumbLink(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(LucideIcons.house, size: 14, color: theme.colorScheme.primary),
            const SizedBox(width: 6),
            Text('Home', style: TextStyle(color: theme.colorScheme.primary)),
          ],
        ),
        onPressed: () =>
            context.go('/', extra: DateTime.now().millisecondsSinceEpoch),
      ),
    ];

    // Build path progressively
    final path = StringBuffer('/public');

    for (var i = 0; i < segments.length; i++) {
      final segment = segments[i];
      final isLast = i == segments.length - 1;
      path.write('/$segment');
      final pathSoFar = path.toString();

      // Skip the parent segment of a detail page — 'rink' in /public/rink/<id>
      // — which has no route of its own.
      //
      // This used to detect the id by parsing it as an integer. Ids are opaque
      // public id strings now, so the shape says nothing; what identifies a
      // detail page is that the id is the last segment and something precedes
      // it. The public routes are one or two segments deep, never more.
      final isDetailParent = i + 1 == segments.length - 1;
      if (isDetailParent) {
        continue;
      }

      // Get label: use pageTitle for last segment if provided, otherwise lookup
      // or format
      String label;
      if (isLast && pageTitle != null) {
        label = pageTitle!;
      } else {
        label =
            (routeLabel(SiteStrings.of(context), segment) ??
                    _formatSegment(segment))
                .replaceAll('\n', ' ');
      }

      if (isLast) {
        // Current page - no link, just text
        items.add(
          Text(
            label,
            style: theme.textTheme.small.copyWith(fontWeight: FontWeight.w600),
          ),
        );
      } else {
        // Parent pages - clickable links
        final linkPath = pathSoFar;
        items.add(
          ShadBreadcrumbLink(
            child: Text(
              label,
              style: TextStyle(color: theme.colorScheme.primary),
            ),
            onPressed: () => context.go(linkPath),
          ),
        );
      }
    }

    return items;
  }

  /// Format segment like "weekend-early" to "Weekend Early"
  String _formatSegment(String segment) {
    return segment
        .split('-')
        .map(
          (word) => word.isNotEmpty
              ? '${word[0].toUpperCase()}${word.substring(1)}'
              : '',
        )
        .join(' ');
  }
}

// =============================================================================
// FOOTER
// =============================================================================

/// Build timestamp passed via --dart-define=BUILD_TIMESTAMP=...
const String _buildTimestamp = String.fromEnvironment('BUILD_TIMESTAMP');

class PublicFooter extends ConsumerWidget {
  const PublicFooter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ShadTheme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      decoration: BoxDecoration(
        color: theme.colorScheme.muted.withValues(alpha: 0.3),
        border: Border(top: BorderSide(color: theme.colorScheme.border)),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '© ${DateTime.now().year} '
              '${ref.watch(siteConfigProvider).fullName}. All rights '
              'reserved.',
              style: theme.textTheme.muted.copyWith(fontSize: 12),
              textAlign: TextAlign.center,
            ),
            if (_buildTimestamp.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                'Build: $_buildTimestamp',
                style: theme.textTheme.muted.copyWith(fontSize: 10),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
