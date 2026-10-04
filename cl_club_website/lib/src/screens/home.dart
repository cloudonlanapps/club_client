import 'dart:async';

import 'package:cl_club_branding/cl_club_branding.dart' show ContactFab;
import 'package:club_sdk_2/club_sdk_2.dart' show EventType;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:scroll_to_index/scroll_to_index.dart';

import '../providers/contact_fab_visibility.dart';
import '../providers/navbar_visibility.dart';
import '../providers/scroll_direction.dart';
import '../widgets/hero_section.dart';
import '../widgets/landing_events_section.dart';
import '../widgets/public_page_shell.dart';
import '../widgets/scroll_animated_section.dart';

/// Landing page - the club's main public website
///
/// Single scrollable page with:
/// - Hero section (full screen with animated text card)
/// - Camps section (max 2 upcoming camps)
/// - Programs section (max 2 programs on different days)
/// - One-off events section (max 2 upcoming events)
/// - Footer
///
/// Animation behavior:
/// - Hero text: Exits upward when scrolled past 50% of hero section
/// - Navbar: Fades in when hero text exits
/// - Each section: Animates in when its top reaches 50% of viewport height
class LandingPage extends ConsumerStatefulWidget {
  const LandingPage({super.key});

  @override
  ConsumerState<LandingPage> createState() => LandingPageState();
}

class LandingPageState extends ConsumerState<LandingPage> {
  late final AutoScrollController _scrollController;

  /// Current scroll progress (0.0 to 1.0) within the hero section
  double _heroScrollProgress = 0;

  /// Whether the hero text should be visible (scroll < 50% of hero)
  bool _showHeroText = true;

  /// Last scroll position for direction tracking
  double _lastScrollPosition = 0;
  static const double _directionThreshold = 10;

  @override
  void initState() {
    super.initState();
    _scrollController = AutoScrollController();
    _scrollController.addListener(_onScroll);

    // Hide navbar and shell FAB initially (landing page has its own animated
    // FAB)
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(navbarVisibilityProvider.notifier).state = false;
      ref.read(contactFabVisibilityProvider.notifier).state = false;
    });
  }

  void _onScroll() {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final heroHeight = screenHeight; // Hero is full screen
    final scrollOffset = _scrollController.offset;

    // Calculate scroll progress within hero (0.0 to 1.0)
    final progress = (scrollOffset / heroHeight).clamp(0.0, 1.0);

    // Determine if we're past 50% threshold
    final shouldShowHeroText = progress < 0.5;
    final shouldShowNavbar = progress >= 0.5;

    // Update state if changed
    if (_showHeroText != shouldShowHeroText) {
      setState(() {
        _heroScrollProgress = progress;
        _showHeroText = shouldShowHeroText;
      });
    } else if (_heroScrollProgress != progress) {
      setState(() {
        _heroScrollProgress = progress;
      });
    }

    // Update navbar visibility
    final currentNavbarState = ref.read(navbarVisibilityProvider);
    if (shouldShowNavbar != currentNavbarState) {
      ref.read(navbarVisibilityProvider.notifier).state = shouldShowNavbar;
    }

    // Track scroll direction after hero section (for mobile navbar hide/show)
    if (shouldShowNavbar) {
      final delta = scrollOffset - _lastScrollPosition;
      if (delta.abs() > _directionThreshold) {
        final direction = delta > 0 ? ScrollDirection.down : ScrollDirection.up;
        ref.read(scrollDirectionProvider.notifier).state = direction;
      }
    } else {
      // Reset to idle in hero section
      ref.read(scrollDirectionProvider.notifier).state = ScrollDirection.idle;
    }

    // Always update last position to prevent stale values
    _lastScrollPosition = scrollOffset;
  }

  @override
  void deactivate() {
    // Reset navbar visibility, scroll direction, and FAB visibility when
    // leaving.
    // Must be in deactivate, not dispose because ref cannot be used after the
    // widget is disposed. Use Future.microtask to defer the modification to
    // avoid modifying provider state during widget tree building.
    final navbarNotifier = ref.read(navbarVisibilityProvider.notifier);
    final scrollNotifier = ref.read(scrollDirectionProvider.notifier);
    final fabNotifier = ref.read(contactFabVisibilityProvider.notifier);
    unawaited(
      Future.microtask(() {
        navbarNotifier.state = true;
        scrollNotifier.state = ScrollDirection.idle;
        fabNotifier.state = true;
      }),
    );
    super.deactivate();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  /// Scroll to the first section after hero
  void scrollToFirstSection() {
    unawaited(
      _scrollController.scrollToIndex(
        0,
        preferPosition: AutoScrollPosition.begin,
        duration: const Duration(milliseconds: 800),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Stack(
      children: [
        // Scrollable content
        SingleChildScrollView(
          controller: _scrollController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Hero section (full screen)
              SizedBox(
                height: screenHeight,
                child: HeroSection(
                  showText: _showHeroText,
                  scrollProgress: _heroScrollProgress,
                  onScrollTap: scrollToFirstSection,
                ),
              ),
              // Camps section - animates when 50% visible
              AutoScrollTag(
                key: const ValueKey(0),
                controller: _scrollController,
                index: 0,
                child: ScrollAnimatedSection(
                  scrollController: _scrollController,
                  builder: ({required isVisible}) => LandingEventsSection(
                    type: EventType.camp,
                    visible: isVisible,
                  ),
                ),
              ),
              // Programs section - animates when 50% visible
              AutoScrollTag(
                key: const ValueKey(1),
                controller: _scrollController,
                index: 1,
                child: ScrollAnimatedSection(
                  scrollController: _scrollController,
                  builder: ({required isVisible}) => LandingEventsSection(
                    type: EventType.programme,
                    visible: isVisible,
                  ),
                ),
              ),
              // One-off events section - animates when 50% visible
              AutoScrollTag(
                key: const ValueKey(2),
                controller: _scrollController,
                index: 2,
                child: ScrollAnimatedSection(
                  scrollController: _scrollController,
                  builder: ({required isVisible}) => LandingEventsSection(
                    type: EventType.oneOff,
                    visible: isVisible,
                  ),
                ),
              ),
              // Footer
              const PublicFooter(),
            ],
          ),
        ),
        // Contact FAB - visible from the start: a page with no events is too
        // short to scroll past the hero (club_core#180).
        const Positioned(right: 16, bottom: 16, child: ContactFab()),
      ],
    );
  }
}
