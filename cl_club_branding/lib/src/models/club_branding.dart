import 'dart:convert';

import 'package:flutter/foundation.dart';

/// Which theme surface the auth hero is painted in.
///
/// A club whose logo is drawn in its own brand colour cannot sit on a hero
/// painted in that same colour — it disappears. Clubs whose mark carries
/// contrasting elements can use the saturated surface and keep the stronger
/// brand presence.
///
/// This names a *surface*, not a colour value, so each club's hero follows its
/// own `ShadColorScheme` and adapts between light and dark themes. A literal
/// colour would pin one value across both.
enum ClubHeroSurface {
  /// Saturated brand colour. Suits a logo with light or contrasting elements.
  primary,

  /// Light tint. Suits a logo drawn in the brand colour itself.
  secondary,
}

/// Club-identifying brand strings shown in UI surfaces.
///
/// Supplied by the host app via `appBrandingProvider`, so the shared packages
/// carry no club identity of their own. See also `ContactInfo` for the richer
/// contact details, and `appLogoUriProvider` for the mark itself.
@immutable
class ClubBranding {
  const ClubBranding({
    required this.fullName,
    required this.shortName,
    required this.heroSurface,
  });

  factory ClubBranding.fromMap(Map<String, dynamic> map) {
    return ClubBranding(
      fullName: map['fullName'] as String? ?? '',
      shortName: map['shortName'] as String? ?? '',
      heroSurface: ClubHeroSurface.values.firstWhere(
        (v) => v.name == map['heroSurface'],
        orElse: () => ClubHeroSurface.secondary,
      ),
    );
  }

  factory ClubBranding.fromJson(String source) =>
      ClubBranding.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Full organisation name, e.g. for the window title and splash screen.
  final String fullName;

  /// Short brand mark, e.g. for the auth shell and the footer copyright line.
  final String shortName;

  /// Theme surface the auth hero is painted in.
  ///
  /// Required rather than defaulted: a club whose logo is drawn in its own
  /// brand colour cannot sit on a hero painted in that colour, and which case
  /// applies is not guessable from the other fields. Every club states it, so
  /// two clubs' configuration differ only in the values they choose — never in
  /// which fields they happen to mention.
  final ClubHeroSurface heroSurface;

  ClubBranding copyWith({
    String? fullName,
    String? shortName,
    ClubHeroSurface? heroSurface,
  }) {
    return ClubBranding(
      fullName: fullName ?? this.fullName,
      shortName: shortName ?? this.shortName,
      heroSurface: heroSurface ?? this.heroSurface,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'shortName': shortName,
      'heroSurface': heroSurface.name,
    };
  }

  String toJson() => json.encode(toMap());

  @override
  String toString() =>
      'ClubBranding(fullName: $fullName, shortName: $shortName, '
      'heroSurface: ${heroSurface.name})';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClubBranding &&
        other.fullName == fullName &&
        other.shortName == shortName &&
        other.heroSurface == heroSurface;
  }

  @override
  int get hashCode => Object.hash(fullName, shortName, heroSurface);
}
