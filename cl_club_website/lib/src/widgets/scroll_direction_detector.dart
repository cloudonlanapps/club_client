import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/scroll_direction.dart';

/// Detects scroll direction and updates [scrollDirectionProvider].
///
/// Only active on mobile (< 768px). On desktop, just renders the child.
/// Uses a threshold of 10px to prevent flickering from small movements.
class ScrollDirectionDetector extends ConsumerStatefulWidget {
  const ScrollDirectionDetector({required this.child, super.key});
  final Widget child;

  @override
  ConsumerState<ScrollDirectionDetector> createState() =>
      ScrollDirectionDetectorState();
}

class ScrollDirectionDetectorState
    extends ConsumerState<ScrollDirectionDetector> {
  double _lastScrollPosition = 0;
  static const double _threshold = 10;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scrollDirectionProvider.notifier).state = ScrollDirection.idle;
    });
  }

  @override
  void deactivate() {
    final notifier = ref.read(scrollDirectionProvider.notifier);
    unawaited(Future.microtask(() => notifier.state = ScrollDirection.idle));
    super.deactivate();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 768;

    if (!isMobile) return false;

    if (notification is ScrollUpdateNotification) {
      final currentPosition = notification.metrics.pixels;
      final delta = currentPosition - _lastScrollPosition;

      if (currentPosition <= 0) {
        ref.read(scrollDirectionProvider.notifier).state = ScrollDirection.idle;
        _lastScrollPosition = currentPosition;
        return false;
      }

      if (delta.abs() > _threshold) {
        final direction = delta > 0 ? ScrollDirection.down : ScrollDirection.up;
        ref.read(scrollDirectionProvider.notifier).state = direction;
        _lastScrollPosition = currentPosition;
      }
    }

    return false;
  }

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: _handleScrollNotification,
      child: widget.child,
    );
  }
}
