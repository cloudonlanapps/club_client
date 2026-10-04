import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../theme/text_theme_extensions.dart';
import 'content_page_hero_background.dart';
import 'content_page_hero_mark.dart';
import 'markdown/themed_markdown.dart';

/// Standardized hero section for content pages.
///
/// Features:
/// - Edge-to-edge background image, or [fallbackImageUri] when the page has
///   none, under a theme-aware gradient; content at most 1000px wide
/// - Optional topWidget / bottomWidget (e.g., info cards)
/// - Optional badge (outline or StampBadge), or an icon in its place
/// - Title with responsive font sizes, optional markdown description
/// - Optional left alignment (for programmes)
class ContentPageHeroSection extends StatelessWidget {
  const ContentPageHeroSection({
    required this.title,
    super.key,
    this.description,
    this.badge,
    this.imageUri,
    this.fallbackImageUri,
    this.httpHeaders,
    this.topWidget,
    this.bottomWidget,
    this.useStampBadge = false,
    this.leftAlign = false,
    this.icon,
    this.selectable = true,
  });

  /// Hero title (required).
  final String title;

  /// Optional markdown description shown below the title.
  final String? description;

  /// Optional badge text (e.g. "BATCH 1"). Ignored when [icon] is set.
  final String? badge;

  /// Background image URI. When it and [fallbackImageUri] are both null, the
  /// hero collapses to an empty widget.
  final String? imageUri;

  /// Public image or video shown when [imageUri] is null — e.g. a site's
  /// default page hero — so a page without a picture keeps its title.
  final String? fallbackImageUri;

  /// Auth headers for [imageUri]. When non-null the page image renders
  /// through `CredentialedNetworkImage` (for authenticated media URLs); when
  /// null it renders through `HighlightMediaOrchestrator` (public image/video
  /// URLs), as the fallback always does.
  final Map<String, String>? httpHeaders;

  /// Optional widget displayed above the badge/title (e.g., info cards for programmes).
  final Widget? topWidget;

  /// Optional widget displayed below the description (e.g., info cards for camps/one-off).
  final Widget? bottomWidget;

  /// If true, uses StampBadge style instead of ShadBadge.outline for the badge.
  final bool useStampBadge;

  /// If true, content is left-aligned instead of centered (for programmes).
  final bool leftAlign;

  /// Optional icon to display instead of badge (e.g., map pin for venue).
  final IconData? icon;

  /// Whether the description's text can be selected.
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    final isDark = theme.brightness == Brightness.dark;

    final textColor = theme.colorScheme.foreground;
    final overlayColor = isDark ? Colors.black : Colors.white;

    if (imageUri == null && fallbackImageUri == null) {
      return const SizedBox.shrink();
    }

    final descriptionStyle = theme.textTheme.heroSubtitle(
      isMobile: isMobile,
      color: textColor,
    );

    // Use smaller minimum height when no extra widgets are present
    final hasExtraContent = bottomWidget != null || topWidget != null;
    final minHeight = hasExtraContent
        ? (isMobile ? 300.0 : 400.0)
        : (isMobile ? 200.0 : 280.0);

    final crossAxisAlignment = leftAlign
        ? CrossAxisAlignment.start
        : CrossAxisAlignment.center;
    final textAlign = leftAlign ? TextAlign.left : TextAlign.center;

    return Padding(
      padding: EdgeInsets.only(bottom: isMobile ? 24 : 32),
      child: Container(
        constraints: BoxConstraints(minHeight: minHeight),
        width: double.infinity,
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            // Background image/video
            Positioned.fill(
              child: ContentPageHeroBackground(
                imageUri: imageUri,
                fallbackImageUri: fallbackImageUri,
                httpHeaders: httpHeaders,
              ),
            ),
            // Gradient overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    overlayColor.withValues(alpha: 0.5),
                    overlayColor.withValues(alpha: 0.85),
                  ],
                ),
              ),
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: Padding(
                    padding: EdgeInsets.only(
                      top: isMobile ? 40 : 60,
                      left: isMobile ? 24 : 48,
                      right: isMobile ? 24 : 48,
                      bottom: hasExtraContent
                          ? (isMobile ? 40 : 60)
                          : (isMobile ? 24 : 40),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: crossAxisAlignment,
                      children: [
                        if (topWidget != null) ...[
                          topWidget!,
                          const SizedBox(height: 24),
                        ],
                        if (icon != null || badge != null)
                          ContentPageHeroMark(
                            icon: icon,
                            badge: badge,
                            useStampBadge: useStampBadge,
                            isMobile: isMobile,
                          ),
                        Text(
                          title,
                          style: theme.textTheme
                              .heroTitle(isMobile: isMobile)
                              .copyWith(color: textColor),
                          textAlign: textAlign,
                        ),
                        if (description != null && description!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 600),
                            child: ThemedMarkdown(
                              data: description!,
                              selectable: selectable,
                              textStyle: descriptionStyle,
                              textAlign: textAlign,
                            ),
                          ),
                        ],
                        if (bottomWidget != null) ...[
                          const SizedBox(height: 32),
                          bottomWidget!,
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
