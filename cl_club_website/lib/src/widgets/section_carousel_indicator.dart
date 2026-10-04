import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import '../page_content/site_copy.dart';

/// Scroll indicator with rotating section text carousel.
/// Tapping anywhere scrolls to the first section after the hero.
class SectionCarouselIndicator extends ConsumerStatefulWidget {
  const SectionCarouselIndicator({super.key, this.onTap, this.visible = true});
  final VoidCallback? onTap;
  final bool visible;

  @override
  ConsumerState<SectionCarouselIndicator> createState() =>
      _SectionCarouselIndicatorState();
}

class _SectionCarouselIndicatorState
    extends ConsumerState<SectionCarouselIndicator> {
  int _currentIndex = 0;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 3), (_) {
      if (!mounted) return;
      setState(() {
        _currentIndex = (_currentIndex + 1) % 3;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    final landing = SiteCopy.of(context).landing;
    final scrollText = landing.hero.scrollIndicatorText;
    // The nav labels carry a line break so the navbar can stack them onto
    // two lines; the indicator wants one line.
    final sectionTexts = [
      landing.nav.events,
      landing.nav.programs,
      landing.nav.oneOff,
    ].map((label) => label.replaceAll('\n', ' ').toUpperCase()).toList();

    final muted = theme.colorScheme.mutedForeground;
    final foreground = theme.colorScheme.cardForeground;

    return AnimatedSlide(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
      offset: widget.visible ? Offset.zero : const Offset(0, 0.5),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: widget.visible ? 1.0 : 0.0,
        child: GestureDetector(
          onTap: widget.onTap,
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16, top: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  scrollText,
                  style: TextStyle(color: muted, fontSize: isMobile ? 11 : 12),
                ),
                const SizedBox(height: 8),
                // Animated section text
                SizedBox(
                  height: 24,
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return FadeTransition(
                        opacity: animation,
                        child: SlideTransition(
                          position: Tween<Offset>(
                            begin: const Offset(0, 0.3),
                            end: Offset.zero,
                          ).animate(animation),
                          child: child,
                        ),
                      );
                    },
                    child: Text(
                      sectionTexts[_currentIndex],
                      key: ValueKey(_currentIndex),
                      style: TextStyle(
                        color: foreground.withValues(alpha: 0.85),
                        fontSize: isMobile ? 12 : 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: isMobile ? 1.0 : 1.2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Icon(
                  LucideIcons.chevronDown,
                  color: muted,
                  size: isMobile ? 16 : 18,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
