import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

import 'cancelled_stripes_painter.dart';

/// One session's share of a half-hour cell in the calendar's week view.
///
/// A live session is filled with the theme's `primary`, fainter once it
/// has ended and stronger while selected. A [cancelled] session is drawn
/// faintly in the theme's muted colours with diagonal stripes, so it reads
/// as planned and called off (club_client#419); selected, its stripes
/// strengthen.
class CalendarSessionBlock extends StatelessWidget {
  const CalendarSessionBlock({
    required this.cancelled,
    required this.selected,
    required this.past,
    super.key,
  });

  /// Whether the session was cancelled.
  final bool cancelled;

  /// Whether the session is the one selected on the calendar.
  final bool selected;

  /// Whether the session has ended.
  final bool past;

  /// Opacity of a live session's fill: selected or not, ended or not.
  static const double liveSelected = 0.9;
  static const double liveSelectedPast = 0.5;
  static const double live = 0.6;
  static const double livePast = 0.2;

  /// Opacity of a cancelled session's muted fill and of its stripes.
  static const double cancelledFill = 0.6;
  static const double cancelledStripes = 0.45;
  static const double cancelledStripesSelected = 0.9;

  @override
  Widget build(BuildContext context) {
    final colors = ShadTheme.of(context).colorScheme;
    if (!cancelled) {
      final alpha = selected
          ? (past ? liveSelectedPast : liveSelected)
          : (past ? livePast : live);
      return ColoredBox(color: colors.primary.withValues(alpha: alpha));
    }
    return CustomPaint(
      painter: CancelledStripesPainter(
        background: colors.muted.withValues(alpha: cancelledFill),
        color: colors.mutedForeground.withValues(
          alpha: selected ? cancelledStripesSelected : cancelledStripes,
        ),
      ),
      child: const SizedBox.expand(),
    );
  }
}
