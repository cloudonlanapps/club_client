import 'package:club_sdk_2/club_sdk_2.dart' show PublicProfile;
import 'package:flutter/material.dart';

import 'coach_card.dart';

/// The public staff list: one [CoachCard] per coach.
class CoachesCardList extends StatelessWidget {
  const CoachesCardList({required this.coaches, super.key});

  /// Narrower than this is laid out for a phone.
  static const double mobileBreakpoint = 768;

  /// Widest the list grows.
  static const double maxWidth = 1000;

  final List<PublicProfile> coaches;

  @override
  Widget build(BuildContext context) {
    final isMobile = MediaQuery.sizeOf(context).width < mobileBreakpoint;

    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: maxWidth),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final coach in coaches)
            CoachCard(coach: coach, isMobile: isMobile),
        ],
      ),
    );
  }
}
