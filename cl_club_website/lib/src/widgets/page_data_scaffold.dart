import 'package:cl_club_website/src/widgets/section_header.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ClubTextTheme, ThemedMarkdown;

import '../page_content/page_common.dart';
import '../page_content/page_data.dart';
import '../page_content/page_type.dart';
import '../page_content/site_copy.dart';
import 'page_hero.dart';

/// Reusable scaffold for pages using PageData structure.
///
/// Looks the page's copy up in [SiteCopy]. That used to be a server fetch with
/// loading and error branches; the copy ships with the build now, so there is
/// only ever data.
///
/// Builds sections in order:
/// 1. Hero section from pageData.hero
/// 2. Active section header + activeContent, OR empty state if activeContent is
///    null
/// 3. Past section header + pastContent (if pastContent provided and
///    pageData.pastSection exists)
/// 4. CTA section (if pageData.cta is provided) with server-configured routes
class PageDataScaffold extends StatelessWidget {
  const PageDataScaffold({
    required this.pageType,
    super.key,
    this.activeContent,
    this.pastContent,
  });

  /// The page type to fetch data for.
  final PageType pageType;

  /// Content for the active section. If null, shows empty state instead.
  final Widget? activeContent;

  /// Content for the past section. Only shown if pastContent is provided
  /// and pageData.pastSection is not null.
  final Widget? pastContent;

  @override
  Widget build(BuildContext context) {
    return PageDataContent(
      pageData: SiteCopy.of(context).pageData(pageType),
      activeContent: activeContent,
      pastContent: pastContent,
    );
  }
}

/// Renders page content with hero, sections, and CTA.
///
/// Use directly when the PageData is assembled from an entity (an event or a
/// venue). For a plain content page, [PageDataScaffold] looks the copy up.
class PageDataContent extends StatelessWidget {
  const PageDataContent({
    required this.pageData,
    super.key,
    this.activeContent,
    this.pastContent,
    this.heroTopWidget,
    this.heroBottomWidget,
    this.heroLeftAlign = false,
    this.heroUseStampBadge = false,
    this.heroIcon,
    this.useActiveSectionWrapper = true,
  });
  final PageData pageData;
  final Widget? activeContent;
  final Widget? pastContent;

  /// Optional widget displayed above the hero badge/title (e.g., info cards).
  final Widget? heroTopWidget;

  /// Optional widget displayed below the hero description (e.g., info cards).
  final Widget? heroBottomWidget;

  /// If true, hero content is left-aligned instead of centered.
  final bool heroLeftAlign;

  /// If true, uses StampBadge style instead of ShadBadge.outline for the badge.
  final bool heroUseStampBadge;

  /// Optional icon to display instead of badge (e.g., map pin for venue).
  final IconData? heroIcon;

  /// If true, wraps activeContent in [ActiveSection] with section header.
  /// Set to false for detail pages where content provides its own structure.
  final bool useActiveSectionWrapper;

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Hero Section with customization
        PageHero(
          data: pageData.hero,
          topWidget: heroTopWidget,
          bottomWidget: heroBottomWidget,
          leftAlign: heroLeftAlign,
          useStampBadge: heroUseStampBadge,
          icon: heroIcon,
        ),

        // Active Section or Empty State
        if (activeContent != null)
          if (useActiveSectionWrapper && pageData.activeSection != null)
            ActiveSection(
              sectionData: pageData.activeSection!,
              isMobile: isMobile,
              child: activeContent!,
            )
          else
            activeContent!
        else
          EmptyStateSection(data: pageData.emptyState, isMobile: isMobile),

        // Past Section (optional)
        if (pastContent != null && pageData.pastSection != null)
          PastSection(
            sectionData: pageData.pastSection!,
            isMobile: isMobile,
            child: pastContent!,
          ),

        // CTA Section (optional)
        if (pageData.cta != null)
          CtaSection(data: pageData.cta!, isMobile: isMobile),

        const SizedBox(height: 40),
      ],
    );
  }
}

/// Active content section with header.
class ActiveSection extends StatelessWidget {
  const ActiveSection({
    required this.sectionData,
    required this.isMobile,
    required this.child,
    super.key,
  });
  final PageSectionHeaderData sectionData;
  final bool isMobile;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 60,
        horizontal: isMobile ? 16 : 48,
      ),
      child: Column(
        children: [
          SectionHeader(sectionData: sectionData, isMobile: isMobile),
          child,
        ],
      ),
    );
  }
}

/// Past content section with header and muted background.
class PastSection extends StatelessWidget {
  const PastSection({
    required this.sectionData,
    required this.isMobile,
    required this.child,
    super.key,
  });
  final PageSectionHeaderData sectionData;
  final bool isMobile;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 60,
        horizontal: isMobile ? 16 : 48,
      ),
      color: theme.colorScheme.muted.withValues(alpha: 0.3),
      child: Column(
        children: [
          SectionHeader(sectionData: sectionData, isMobile: isMobile),
          child,
        ],
      ),
    );
  }
}

/// Empty state section with card, icon, title, description, and button.
class EmptyStateSection extends StatelessWidget {
  const EmptyStateSection({
    required this.data,
    required this.isMobile,
    super.key,
  });
  final PageEmptyStateData data;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 60,
        horizontal: isMobile ? 24 : 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: ShadCard(
            child: Padding(
              padding: const EdgeInsets.all(40),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      LucideIcons.sparkles,
                      size: 48,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    data.title,
                    style: theme.textTheme.h2,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  ThemedMarkdown(
                    data: data.description,
                    selectable: false,
                    textStyle: theme.textTheme.muted.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                  ShadButton(
                    onPressed: () => context.go('/public/contact-us'),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.bell, size: 16),
                        const SizedBox(width: 8),
                        Text(data.buttonText),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Loading indicator for content section.
class LoadingContent extends StatelessWidget {
  const LoadingContent({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: const Center(child: CircularProgressIndicator()),
    );
  }
}

/// Error display for content section.
///
/// Shows a user-friendly error message without exposing technical details.
/// The [error] parameter is only used for debug logging, not displayed to
/// users.
class ErrorContent extends StatelessWidget {
  const ErrorContent({required this.error, required this.title, super.key});
  final String error;
  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: Column(
            children: [
              Icon(
                LucideIcons.circleAlert,
                size: 48,
                color: theme.colorScheme.destructive,
              ),
              const SizedBox(height: 16),
              Text(
                title,
                style: theme.textTheme.h3,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'We encountered an issue loading this content. Please try '
                'again later.',
                style: theme.textTheme.muted,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// CTA section with title, description (supports markdown), and action buttons.
///
/// Primary button is always shown. Secondary button only appears when both
/// [PageCtaData.secondaryButtonText] and [PageCtaData.secondaryRoute] are set.
/// All labels and routes come from server via [PageCtaData].
class CtaSection extends StatelessWidget {
  const CtaSection({required this.data, required this.isMobile, super.key});
  final PageCtaData data;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final showSecondary =
        data.secondaryButtonText != null && data.secondaryRoute != null;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        vertical: isMobile ? 40 : 60,
        horizontal: isMobile ? 24 : 48,
      ),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            children: [
              Text(
                data.title,
                style: theme.textTheme.subsectionTitle(isMobile: isMobile),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              ThemedMarkdown(
                data: data.description,
                selectable: false,
                textStyle: theme.textTheme.muted,
              ),
              const SizedBox(height: 24),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 16,
                runSpacing: 12,
                children: [
                  ShadButton(
                    onPressed: () => context.go(data.primaryRoute),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(LucideIcons.userPlus, size: 16),
                        const SizedBox(width: 8),
                        Text(data.primaryButtonText),
                      ],
                    ),
                  ),
                  if (showSecondary)
                    ShadButton.outline(
                      onPressed: () => context.go(data.secondaryRoute!),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(LucideIcons.mail, size: 16),
                          const SizedBox(width: 8),
                          Text(data.secondaryButtonText!),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
