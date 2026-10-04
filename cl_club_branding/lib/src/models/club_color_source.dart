import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../utils/hex_color.dart';
import 'club_color_tokens.dart';

/// Where a club's colour scheme comes from: a shadcn scheme by name, with
/// optional overrides on top.
///
/// A club app names the scheme in its `club.json` and overrides nothing; a
/// site takes its brand colour and per-brightness tokens from
/// `assets/config/theme.json`. `buildClubColorScheme` turns either into a
/// `ShadColorScheme`.
@immutable
class ClubColorSource {
  /// The shadcn scheme [schemeName] with the given overrides.
  const ClubColorSource({
    required this.schemeName,
    this.primary,
    this.light = const ClubColorTokens(),
    this.dark = const ClubColorTokens(),
  });

  /// Reads a source from the map [toMap] writes.
  factory ClubColorSource.fromMap(Map<String, dynamic> map) {
    return ClubColorSource(
      schemeName: map[schemeNameKey] as String? ?? '',
      primary: parseHexColor(map[primaryKey] as String?),
      light: ClubColorTokens.fromMap(
        map[lightKey] as Map<String, dynamic>? ?? const {},
      ),
      dark: ClubColorTokens.fromMap(
        map[darkKey] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  /// Reads a source from the JSON [toJson] writes.
  factory ClubColorSource.fromJson(String source) =>
      ClubColorSource.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Map key of [schemeName].
  static const String schemeNameKey = 'schemeName';

  /// Map key of [primary].
  static const String primaryKey = 'primary';

  /// Map key of [light].
  static const String lightKey = 'light';

  /// Map key of [dark].
  static const String darkKey = 'dark';

  /// A `ShadColorScheme.fromName` name, e.g. `blue`.
  final String schemeName;

  /// The brand colour for both brightnesses; null keeps the scheme's.
  final Color? primary;

  /// Token overrides for the light scheme.
  final ClubColorTokens light;

  /// Token overrides for the dark scheme.
  final ClubColorTokens dark;

  /// The token overrides for [brightness].
  ClubColorTokens tokensFor(Brightness brightness) =>
      brightness == Brightness.dark ? dark : light;

  /// A copy with the given fields replaced; `primary: () => null` clears it.
  ClubColorSource copyWith({
    String? schemeName,
    Color? Function()? primary,
    ClubColorTokens? light,
    ClubColorTokens? dark,
  }) {
    return ClubColorSource(
      schemeName: schemeName ?? this.schemeName,
      primary: primary != null ? primary() : this.primary,
      light: light ?? this.light,
      dark: dark ?? this.dark,
    );
  }

  /// The source as a map, colours as `#AARRGGBB`.
  Map<String, dynamic> toMap() {
    final brand = primary;
    return <String, dynamic>{
      schemeNameKey: schemeName,
      if (brand != null) primaryKey: formatHexColor(brand),
      lightKey: light.toMap(),
      darkKey: dark.toMap(),
    };
  }

  /// [toMap] as JSON.
  String toJson() => json.encode(toMap());

  @override
  String toString() =>
      'ClubColorSource(schemeName: $schemeName, primary: $primary, '
      'light: $light, dark: $dark)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClubColorSource &&
        other.schemeName == schemeName &&
        other.primary == primary &&
        other.light == light &&
        other.dark == dark;
  }

  @override
  int get hashCode => Object.hash(schemeName, primary, light, dark);
}
