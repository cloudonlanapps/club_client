import 'dart:async';

import 'package:cl_club_branding/cl_club_branding.dart' show ThemeModeWidgetRef;
import 'package:cl_club_events/cl_club_events.dart'
    show
        EventHighlight,
        Highlight,
        PublicEventHeroCard,
        publicHighlightsProvider;
import 'package:cl_gallery_viewer/cl_gallery_viewer.dart'
    show HighlightMediaOverlayButton;
import 'package:cl_remote_store/cl_remote_store.dart'
    show SiteMediaSlot, clPublicSiteMediaProvider;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shadcn_ui/shadcn_ui.dart';
import 'package:ui_lib/ui_lib.dart' show ClubTextTheme, StampBadge;

import '../extensions/site_media_slot_bundled_asset.dart';
import '../page_content/site_copy.dart';
import '../site/site_routes.dart';
import 'club_logo.dart';
import 'hero_top_actions.dart';
import 'hero_video_background.dart';
import 'section_carousel_indicator.dart';

/// Duration each highlight stays before auto-scrolling
const _autoScrollDuration = Duration(seconds: 5);

/// Isolated video background that only rebuilds when its own data changes.
///
/// Extracted from HeroSection to prevent video playback disruption
/// when the highlight carousel index changes (which triggers setState
/// in HeroSectionState and rebuilds the full tree).
class HeroVideoBackgroundLayer extends ConsumerWidget {
  const HeroVideoBackgroundLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const slot = SiteMediaSlot.landingBackground;
    final background =
        ref.watch(clPublicSiteMediaProvider(slot)) ?? slot.bundledMedia;

    return HeroVideoBackground(
      videoUri: null,
      defaultBackground: background.uri,
      isVideo: background.isVideo,
      previewUri: background.previewUri ?? slot.bundledAsset,
      showOverlayButton: false,
    );
  }
}

/// Overlay button for hero media, isolated from carousel rebuilds.
///
/// Shows [HighlightMediaOverlayButton] only when the background is a video.
/// Placed as a top-level child in the hero Stack so it sits above all
/// other layers (gradient, content, navigation hitboxes).
class HeroMediaOverlayButtonLayer extends ConsumerWidget {
  const HeroMediaOverlayButtonLayer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const slot = SiteMediaSlot.landingBackground;
    final background =
        ref.watch(clPublicSiteMediaProvider(slot)) ?? slot.bundledMedia;

    if (!background.isVideo) {
      return const SizedBox.shrink();
    }

    final isMobile = MediaQuery.sizeOf(context).width < 768;

    return Positioned(
      top: isMobile ? 16 : 24,
      left: 0,
      right: 0,
      child: Center(
        child: HighlightMediaOverlayButton(videoUrl: background.uri),
      ),
    );
  }
}

/// Hero tag for theme toggle animation between hero and navbar
const heroThemeToggleTag = 'theme-toggle-hero';

/// Hero section with highlights carousel for landing page
///
/// The text card animates based on [showText]:
/// - When true: text card is visible
/// - When false: text card slides up and exits
class HeroSection extends ConsumerStatefulWidget {
  const HeroSection({
    super.key,
    this.showText = true,
    this.scrollProgress = 0.0,
    this.onScrollTap,
  });

  /// Whether to show the hero text card
  final bool showText;

  /// Scroll progress (0.0 to 1.0) for potential parallax effects
  final double scrollProgress;

  /// Callback when scroll indicator is tapped
  final VoidCallback? onScrollTap;

  @override
  ConsumerState<HeroSection> createState() => HeroSectionState();
}

class HeroSectionState extends ConsumerState<HeroSection>
    with SingleTickerProviderStateMixin {
  int currentIndex = 0;
  Timer? autoScrollTimer;

  /// Animation controller for WhatsApp-style progress bar
  late AnimationController _progressController;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: _autoScrollDuration,
    );
  }

  @override
  void dispose() {
    autoScrollTimer?.cancel();
    _progressController.dispose();
    super.dispose();
  }

  int _highlightCount = 0;

  void startAutoScroll(int itemCount) {
    _highlightCount = itemCount;
    autoScrollTimer?.cancel();
    if (itemCount <= 1) {
      // Single (or zero) highlight: no timer, no progress animation.
      return;
    }

    _progressController.forward(from: 0);

    autoScrollTimer = Timer.periodic(_autoScrollDuration, (_) {
      if (!mounted) return;
      goToPage((currentIndex + 1) % itemCount);
    });
  }

  void goToPage(int index) {
    setState(() => currentIndex = index);
    // Restart timer without recursion
    autoScrollTimer?.cancel();
    if (_highlightCount > 1) {
      _progressController.forward(from: 0);
      autoScrollTimer = Timer.periodic(_autoScrollDuration, (_) {
        if (!mounted) return;
        goToPage((currentIndex + 1) % _highlightCount);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;
    final isTablet = screenWidth >= 768 && screenWidth < 1024;

    final isDark = ref.watchIsDark(context);

    // Theme-aware overlay color (opposite of text for image contrast)
    final overlayColor = isDark ? Colors.black : Colors.white;

    final highlightsAsync = ref.watch(publicHighlightsProvider);
    final highlights = highlightsAsync.valueOrNull ?? [];
    final hasHighlights = highlights.isNotEmpty;

    final learnMoreText = SiteCopy.of(context).landing.hero.learnMoreButton;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (hasHighlights && autoScrollTimer == null) {
        startAutoScroll(highlights.length);
      }
    });

    return Stack(
      fit: StackFit.expand,
      children: [
        // Isolated ConsumerWidget — only rebuilds when landing page data
        // changes,
        // NOT when currentIndex changes from highlight carousel switching.
        const HeroVideoBackgroundLayer(),
        // Overlay gradient (IgnorePointer so taps pass through to video
        // background)
        IgnorePointer(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  overlayColor.withValues(alpha: 0.3),
                  overlayColor.withValues(alpha: 0.15),
                  overlayColor.withValues(alpha: 0.4),
                ],
              ),
            ),
          ),
        ),
        // Content layout
        if (isMobile)
          _buildMobileLayout(
            theme,
            highlights,
            hasHighlights,
            learnMoreText,
          )
        else
          _buildDesktopLayout(
            theme,
            highlights,
            hasHighlights,
            isTablet,
            learnMoreText,
          ),
        // Club logo overlay
        Positioned(
          top: isMobile ? 16 : 24,
          left: isMobile ? 16 : 24,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.card,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: theme.colorScheme.border),
            ),
            child: ClubLogo(height: isMobile ? 32 : 40),
          ),
        ),
        // Theme toggle and menu
        Positioned(
          top: isMobile ? 16 : 24,
          right: isMobile ? 16 : 24,
          child: const HeroTopActions(),
        ),
        // Media overlay button (mute on Chrome, popup on Safari) — top z-order
        // so it sits above content layout, gradient, and navigation hitboxes.
        const HeroMediaOverlayButtonLayer(),
      ],
    );
  }

  Widget _buildDesktopLayout(
    ShadThemeData theme,
    List<Highlight> highlights,
    bool hasHighlights,
    bool isTablet,
    String learnMoreText,
  ) {
    final hPad = isTablet ? 40.0 : 80.0;

    return Stack(
      children: [
        // Swipe detector for carousel — only handles horizontal drags,
        // taps pass through to the video background below.
        if (hasHighlights && highlights.length > 1)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! < -100) {
                  // Swipe left → next
                  goToPage((currentIndex + 1) % highlights.length);
                } else if (details.primaryVelocity! > 100) {
                  // Swipe right → prev
                  final prev = (currentIndex - 1) < 0
                      ? highlights.length - 1
                      : currentIndex - 1;
                  goToPage(prev);
                }
              },
            ),
          ),

        // Content layout
        Positioned.fill(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: hPad),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Animated text card
                      if (hasHighlights)
                        _buildAnimatedHighlightInfo(
                          highlights,
                          false,
                          theme,
                          learnMoreText,
                        ),
                    ],
                  ),
                ),
                // Progress bars (only when carousel has multiple slides)
                if (highlights.length > 1) ...[
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: _buildBottomControls(highlights, false, theme),
                  ),
                ],
                const SizedBox(height: 8),
                SectionCarouselIndicator(
                  visible: widget.showText,
                  onTap: widget.onScrollTap,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    ShadThemeData theme,
    List<Highlight> highlights,
    bool hasHighlights,
    String learnMoreText,
  ) {
    return Stack(
      children: [
        // Swipe detector for carousel — only handles horizontal drags,
        // taps pass through to the video background below.
        if (hasHighlights && highlights.length > 1)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onHorizontalDragEnd: (details) {
                if (details.primaryVelocity == null) return;
                if (details.primaryVelocity! < -100) {
                  goToPage((currentIndex + 1) % highlights.length);
                } else if (details.primaryVelocity! > 100) {
                  final prev = (currentIndex - 1) < 0
                      ? highlights.length - 1
                      : currentIndex - 1;
                  goToPage(prev);
                }
              },
            ),
          ),

        // Content layout
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              children: [
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Animated text card
                      if (hasHighlights)
                        _buildAnimatedHighlightInfo(
                          highlights,
                          true,
                          theme,
                          learnMoreText,
                        ),
                    ],
                  ),
                ),
                // Progress bars (only when carousel has multiple slides)
                if (highlights.length > 1) ...[
                  const SizedBox(height: 16),
                  _buildBottomControls(highlights, true, theme),
                ],
                const SizedBox(height: 8),
                SectionCarouselIndicator(
                  visible: widget.showText,
                  onTap: widget.onScrollTap,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  /// Animated highlight info card that slides up/down based on `showText`
  Widget _buildAnimatedHighlightInfo(
    List<Highlight> highlights,
    bool isMobile,
    ShadThemeData theme,
    String learnMoreText,
  ) {
    final h = highlights[currentIndex];

    return AnimatedSlide(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      offset: widget.showText ? Offset.zero : const Offset(0, -0.5),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: widget.showText ? 1.0 : 0.0,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          child: h is EventHighlight
              ? PublicEventHeroCard(
                  key: ValueKey(h.id),
                  event: h.view,
                  buttonText: learnMoreText,
                  compact: isMobile,
                  onButtonPressed: () =>
                      context.go(SiteRoutes.event(h.view.publicId)),
                )
              : _buildGenericHighlightCard(h, isMobile, theme, learnMoreText),
        ),
      ),
    );
  }

  /// Fallback card for non-event highlights (news, VIP visits, etc.)
  Widget _buildGenericHighlightCard(
    Highlight h,
    bool isMobile,
    ShadThemeData theme,
    String learnMoreText,
  ) {
    final route = SiteRoutes.highlight(h);
    return Container(
      key: ValueKey(h.id),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        color: theme.colorScheme.card.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (h.stamp != null) ...[
            StampBadge(text: h.stamp!),
            const SizedBox(height: 12),
          ],
          Text(
            h.title,
            style: theme.textTheme
                .cardTitle(compact: isMobile)
                .copyWith(
                  fontWeight: FontWeight.w900,
                  color: theme.colorScheme.cardForeground,
                  height: 1.1,
                  letterSpacing: -0.5,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            h.subtitle,
            style: theme.textTheme.heroSubtitle(
              isMobile: isMobile,
              color: theme.colorScheme.mutedForeground,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (route != null) ...[
            SizedBox(height: isMobile ? 12 : 16),
            Align(
              alignment: Alignment.centerRight,
              child: ShadButton(
                size: isMobile ? ShadButtonSize.sm : ShadButtonSize.regular,
                onPressed: () => context.go(route),
                child: Text(learnMoreText),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBottomControls(
    List<Highlight> highlights,
    bool isMobile,
    ShadThemeData theme,
  ) {
    return AnimatedSlide(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      offset: widget.showText ? Offset.zero : const Offset(0, -0.5),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: widget.showText ? 1.0 : 0.0,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: isMobile ? 24 : 60),
          child: _buildProgressBars(highlights.length, theme),
        ),
      ),
    );
  }

  Widget _buildProgressBars(int count, ShadThemeData theme) {
    final foreground = theme.colorScheme.cardForeground;
    return Row(
      children: List.generate(count, (index) {
        final isPast = index < currentIndex;
        final isActive = index == currentIndex;

        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index < count - 1 ? 4 : 0),
            child: GestureDetector(
              onTap: () => goToPage(index),
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  color: foreground.withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(1.5),
                ),
                child: isPast
                    ? Container(
                        decoration: BoxDecoration(
                          color: foreground,
                          borderRadius: BorderRadius.circular(1.5),
                        ),
                      )
                    : isActive
                    ? AnimatedBuilder(
                        animation: _progressController,
                        builder: (context, _) {
                          return FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: _progressController.value,
                            child: Container(
                              decoration: BoxDecoration(
                                color: foreground,
                                borderRadius: BorderRadius.circular(1.5),
                              ),
                            ),
                          );
                        },
                      )
                    : null,
              ),
            ),
          ),
        );
      }),
    );
  }
}
