import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// A widget that animates its child when it becomes visible during scroll.
/// Animation triggers when the section's top reaches 50% of viewport height.
class ScrollAnimatedSection extends StatefulWidget {
  const ScrollAnimatedSection({
    required this.scrollController,
    required this.builder,
    super.key,
    this.threshold = 0.5,
  });

  /// The scroll controller to listen to
  final ScrollController scrollController;

  /// Builder that receives visibility state
  final Widget Function({required bool isVisible}) builder;

  /// Threshold as percentage of viewport height (0.0 to 1.0)
  /// Default 0.5 means section animates when its top reaches middle of screen
  final double threshold;

  @override
  State<ScrollAnimatedSection> createState() => _ScrollAnimatedSectionState();
}

class _ScrollAnimatedSectionState extends State<ScrollAnimatedSection> {
  final GlobalKey _key = GlobalKey();
  bool _isVisible = false;

  @override
  void initState() {
    super.initState();
    widget.scrollController.addListener(_checkVisibility);
    SchedulerBinding.instance.addPostFrameCallback((_) => _checkVisibility());
  }

  @override
  void dispose() {
    widget.scrollController.removeListener(_checkVisibility);
    super.dispose();
  }

  void _checkVisibility() {
    final renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null || !renderBox.hasSize) return;

    final position = renderBox.localToGlobal(Offset.zero);
    final screenHeight = MediaQuery.sizeOf(context).height;
    final thresholdPosition = screenHeight * widget.threshold;
    final shouldBeVisible = position.dy <= thresholdPosition;

    if (shouldBeVisible != _isVisible) {
      setState(() => _isVisible = shouldBeVisible);
    }
  }

  @override
  Widget build(BuildContext context) {
    return KeyedSubtree(
      key: _key,
      child: widget.builder(isVisible: _isVisible),
    );
  }
}
