import 'package:club_sdk_2/club_sdk_2.dart';
import 'package:flutter/material.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

/// Cluster of circular "rubber-stamp" role marks overlaid on the avatar.
///
/// Each stamp is a circular double-ring with the role label in caps, drawn
/// in a single ink color and slightly rotated so it reads like an
/// inked-on impression. Multiple stamps stagger their rotation so they
/// feel hand-applied.
///
/// Renders nothing when the user has no role.
class ProfileRoleStamps extends StatelessWidget {
  const ProfileRoleStamps({required this.user, super.key});

  final UserInfo user;

  @override
  Widget build(BuildContext context) {
    final stamps = <StampSpec>[];

    // Super Admin supersedes Admin (super implies admin).
    // Fluorescent ink colors per role — chosen to read on dark photo
    // backgrounds without colliding with the app's orange brand color.
    const adminInk = Color(0xFF39FF14); // fluorescent green
    const coachInk = Color(0xFFEEFF00); // fluorescent yellow
    if (user.isSuperAdmin) {
      stamps.add(
        const StampSpec(label: 'SUPER\nADMIN', tiltDegrees: -10, ink: adminInk),
      );
    } else if (user.roles.isAdmin) {
      stamps.add(
        const StampSpec(label: 'ADMIN', tiltDegrees: -10, ink: adminInk),
      );
    }
    if (user.roles.isCoach) {
      stamps.add(
        const StampSpec(label: 'COACH', tiltDegrees: 7, ink: coachInk),
      );
    }

    if (stamps.isEmpty) return const SizedBox.shrink();

    // Slightly overlap adjacent stamps (via negative horizontal translation
    // on every stamp after the first) so multiple roles read as two
    // impressions hand-applied in sequence rather than a tidy grid.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < stamps.length; i++)
          Transform.translate(
            offset: Offset(i == 0 ? 0 : -12.0, 0),
            child: RubberStamp(spec: stamps[i]),
          ),
      ],
    );
  }
}

class StampSpec {
  const StampSpec({
    required this.label,
    required this.tiltDegrees,
    required this.ink,
  });

  final String label;
  final double tiltDegrees;
  final Color ink;
}

class RubberStamp extends StatelessWidget {
  const RubberStamp({required this.spec, super.key});

  final StampSpec spec;

  static const double _size = 84;

  @override
  Widget build(BuildContext context) {
    final theme = ShadTheme.of(context);
    final ink = spec.ink.withValues(alpha: 0.9);

    return Transform.rotate(
      angle: spec.tiltDegrees * 3.1415926535 / 180.0,
      child: Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: ink, width: 2.5),
        ),
        padding: const EdgeInsets.all(4),
        child: Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: ink),
          ),
          alignment: Alignment.center,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              spec.label,
              textAlign: TextAlign.center,
              style: theme.textTheme.small.copyWith(
                color: ink,
                fontWeight: FontWeight.w900,
                fontSize: 11,
                letterSpacing: 0.8,
                height: 1.05,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
