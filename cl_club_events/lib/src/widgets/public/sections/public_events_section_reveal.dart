import 'package:flutter/widgets.dart';

/// Slides and fades a landing section's part in as it scrolls into view.
class PublicEventsSectionReveal extends StatelessWidget {
  const PublicEventsSectionReveal({
    required this.visible,
    required this.child,
    super.key,
  });

  /// Duration of the slide.
  static const Duration slideDuration = Duration(milliseconds: 400);

  /// Duration of the fade.
  static const Duration fadeDuration = Duration(milliseconds: 300);

  /// Whether the part is shown.
  final bool visible;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      duration: slideDuration,
      curve: Curves.easeInOut,
      offset: visible ? Offset.zero : const Offset(0, 0.5),
      child: AnimatedOpacity(
        duration: fadeDuration,
        opacity: visible ? 1.0 : 0.0,
        child: child,
      ),
    );
  }
}
