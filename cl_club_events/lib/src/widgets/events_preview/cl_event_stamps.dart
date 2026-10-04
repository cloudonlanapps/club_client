import 'dart:math' as math;

import 'package:club_sdk_2/club_sdk_2.dart' show Event, Visibility;
import 'package:flutter/material.dart' hide Visibility;
import 'package:shadcn_ui/shadcn_ui.dart';

/// Cluster of "rubber-stamp" marks overlaid on the event hero image to
/// surface visibility and featured flags.
///
/// - Private events: a bordered stamp with the lucide lock icon.
/// - Featured events: a bare asterisk-shaped mark (no border), colored.
///
/// Renders nothing when the event is public and not featured.
class ClEventStamps extends StatelessWidget {
  const ClEventStamps({required this.event, super.key});

  final Event event;

  static const Color _featuredInk = Color(0xFFEEFF00); // fluorescent yellow
  static const Color _privateInk = Color(0xFFFF3B30); // alert red

  @override
  Widget build(BuildContext context) {
    final isPrivate = event.visibility == Visibility.private;
    final isFeatured = event.isFeatured;

    if (!isPrivate && !isFeatured) return const SizedBox.shrink();

    final marks = <Widget>[
      if (isPrivate) const PrivateStamp(ink: _privateInk),
      if (isFeatured) const FeaturedStamp(ink: _featuredInk),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < marks.length; i++)
          Transform.translate(
            offset: Offset(i == 0 ? 0 : -12, 0),
            child: marks[i],
          ),
      ],
    );
  }
}

/// Featured mark: bold colored award medal with a "FEATURED" caption
/// curving under it. No border ring — the medal shape itself is the stamp.
class FeaturedStamp extends StatelessWidget {
  const FeaturedStamp({required this.ink, super.key});

  final Color ink;

  static const double _size = 84;
  static const double _tiltDegrees = 7;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final color = ink.withValues(alpha: 0.95);
    final shadow = [
      Shadow(
        color: Colors.black.withValues(alpha: 0.45),
        blurRadius: 4,
        offset: const Offset(1, 1),
      ),
    ];
    return Transform.rotate(
      angle: _tiltDegrees * math.pi / 180.0,
      child: Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              Colors.black.withValues(alpha: 0.45),
              Colors.black.withValues(alpha: 0),
            ],
            stops: const [0.4, 1],
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              LucideIcons.award,
              color: color,
              size: 60,
              shadows: shadow,
            ),
            Text(
              'FEATURED',
              textAlign: TextAlign.center,
              style: theme.textTheme.small.copyWith(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 1.2,
                height: 1,
                shadows: shadow,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Private mark: bordered double-ring stamp with the lucide lock icon.
class PrivateStamp extends StatelessWidget {
  const PrivateStamp({required this.ink, super.key});

  final Color ink;

  static const double _size = 84;
  static const double _tiltDegrees = -10;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final color = ink.withValues(alpha: 0.9);
    return Transform.rotate(
      angle: _tiltDegrees * math.pi / 180.0,
      child: Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black.withValues(alpha: 0.35),
          border: Border.all(color: color, width: 2.5),
        ),
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: color),
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.lock, color: color, size: 26),
              const SizedBox(height: 2),
              Text(
                'PRIVATE',
                textAlign: TextAlign.center,
                style: theme.textTheme.small.copyWith(
                  color: color,
                  fontWeight: FontWeight.w900,
                  fontSize: 10,
                  letterSpacing: 0.8,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
